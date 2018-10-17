# -*-cperl-*-
#
# Business::Bitcoin::Request - Bitcoin payment request
# Copyright (c) Ashish Gulhati <biz-btc at hash dot neomailbox.ch>
#
# $Id: lib/Business/Bitcoin/Request.pm v1.051 Tue Oct 16 22:26:58 PDT 2018 $

use warnings;
use strict;

package Business::Bitcoin::Request;

use DBI;
use LWP::UserAgent;
use HTTP::Request;
use Math::EllipticCurve::Prime;
use Math::EllipticCurve::Prime::Point;
use Digest::SHA qw(sha256 sha256_hex hmac_sha512_hex);
use Encode::Base58::BigInt;
use Crypt::RIPEMD160;

use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.051 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %args) = @_;
  return undef if $args{Amount} !~ /^\d+$/; return undef if $args{StartIndex} and $args{StartIndex} =~ /\D/;
  my $db = $args{_BizBTC}->db; my $xpub = $args{_BizBTC}->xpub;
  my $timestamp = time;
  my $index = defined $args{StartIndex} ? $args{StartIndex} : 'NULL';
  my $refid = defined $args{Reference} ? "'$args{Reference}'" : 'NULL';
  return undef unless $db->do("INSERT INTO requests values ($index, '$args{Amount}', NULL, $refid, '$timestamp', NULL, NULL);");
  $index = $db->last_insert_id('%', '%', 'requests', 'reqid');
  $ENV{PATH} = undef;
  return undef unless my $address = _getaddress($args{_BizBTC}, $index);
  my $rows = $db->do("UPDATE requests set address='$address' where reqid='$index';");
  bless { Address => $address,
	  ID => $index,
	  Amount => $args{Amount},
	  DB => $db,
	  Reference => $args{Reference},
	  Confirmations => defined $args{Confirmations} ? $args{Confirmations} : 5,
	  Created => $timestamp }, $class;
}

sub verify {
  my $self = shift;
  my $ua = new LWP::UserAgent;
  my $req = HTTP::Request->new(GET => 'https://blockchain.info/q/addressbalance/' . $self->address . '?confirmations=' . $self->confirmations);
  my $res = $ua->request($req);
  my $paid = $res->content;
  $self->error($paid), return if $paid =~ /\D/;
  $self->error('');
  $paid >= $self->amount ? $paid : 0;
}

sub _find {
  my ($class, %args) = @_;
  return unless defined $args{Address} or defined $args{Reference};
  return if defined $args{Address} and defined $args{Reference};
  return unless defined $args{_BizBTC} and $args{_BizBTC}->db->ping;

  my $query = 'SELECT reqid,address,amount,reference,created,processed,status from requests WHERE ' .
    (defined $args{Address} ? "address='$args{Address}';" : "reference='$args{Reference}';");
  my ($reqid, $address, $amount, $refid, $created, $processed, $status) = $args{_BizBTC}->db->selectrow_array($query);
  bless { Address => $address,
	  Amount => $amount,
	  Reference => $refid,
	  ID => $reqid,
	  DB => $args{_BizBTC}->db,,
	  Confirmations => defined $args{Confirmations} ? $args{Confirmations} : 5,
	  Created => $created,
	  Processed => $processed,
	  Status => $status
	}, $class;
}

sub commit {
  my $self = shift;
  my $processed = $self->processed;
  my $status = $self->status;
  my $amount = $self->amount;
  my $refid = $self->reference;
  my $address = $self->address;
  my @updates;
  push @updates, "processed = '" . $processed . "'" if $processed;
  push @updates, "reference = '" . $refid . "'" if $refid;
  push @updates, "status = '" . $status . "'" if $status;
  push @updates, "amount = '" . $amount . "'" if $amount;
  return 1 unless my $updates = join ',',@updates;
  return undef unless $self->db->do("UPDATE requests SET $updates where address='$address';");
  return 1;
}

sub _getaddress {
  my ($bizbtc, $index) = @_;
  my $xpub = $bizbtc->xpub;
  my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
  my $xpubdata =  Math::BigInt->new(_decode58($xpub))->as_hex;
  $xpubdata =~ /.(.{8})(..)(.{8})(.{8})(.{64})(.{66})(.*)/;
  my ($ver, $depth, $fp, $i, $c, $Kc) = ($1, $2, $3, $4, $5, $6);
  my $K = Math::EllipticCurve::Prime::Point->from_hex(_decompress($Kc));
  if ($bizbtc->path eq 'electrum') {
    # m/0
    my ($Ki, $ci) = _CKDpub($K, $c, 0);
    # m/0/$index
    my ($Ki2, $ci2) = _CKDpub($Ki, $ci, $index);
    return _address(_compress($Ki2));
  }
  else {
    my ($Ki, $ci) = _CKDpub($K, $c, $index);
    return _address(_compress($Ki));
  }
}

sub _CKDpub {
  my ($K, $c, $i) = @_;
  my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
  my $data = pack('H*', _compress($K)) . pack ('L>', $i);
  my $hmac = hmac_sha512_hex($data, pack('H*', $c)); $hmac =~ /(.{64})(.{64})/;
  my ($Il, $ci) = ($1, $2);
  my $Ki = $curve->g->multiply(Math::BigInt->from_hex($Il))->add($K);
  return ($Ki, $ci);
}

sub _address {
  my $sha256 = sha256(pack('H*', shift));
  my $id = '00' . Crypt::RIPEMD160->hexhash($sha256); $id =~ s/\s//g;
  my $checksum = substr(sha256_hex(sha256(pack('H*', $id))), 0, 8);
  my $address = _encode58(Math::BigInt->from_hex($id . $checksum));
  my $leadingones;
  while ($id =~ /^(00)/) { $leadingones .= '1'; $id =~ s/^00//; }
  return $leadingones . $address;
}

sub _decompress {
  my $Kc = shift; $Kc =~ /^(..)(.*)/;
  my $i = $1; my $K = '04' . '0' x (64 - length($2)) . $2; my $x = Math::BigInt->from_hex($2);
  my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
  my ($p, $a, $b) = ($curve->p, $curve->a, $curve->b);
  my $y = ($x->bmodpow(3,$p)+$a*$x+$b)->bmodpow(($p+1)/4,$p);
  $y = $p - $y if $i%2 ne $y%2;
  my $yhex = $y->as_hex; $yhex =~ s/^0x//;
  $K .= '0' x (64 - length($yhex)) . $yhex;
  return $K;
}

sub _compress {
  my $K = shift;
  my $Kc = $K->x->as_hex; $Kc =~ s/^0x//;
  $Kc = '0' x (64 - length($Kc)) . $Kc;
  $Kc = ($K->y % 2 ? '03' : '02') . $Kc;
}

sub _decode58 {
  my $todecode = shift;
  $todecode =~ tr/A-HJ-NP-Za-km-z/a-km-zA-HJ-NP-Z/;
  my $decoded = decode_base58($todecode);
}

sub _encode58 {
  my $encoded = encode_base58(shift);
  $encoded =~ tr/a-km-zA-HJ-NP-Z/A-HJ-NP-Za-km-z/;
  return $encoded;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(confirmations|processed|status|amount|reference|error)$/x and defined $_[0]) {
    $self->{"\u$auto"} = shift;
  }
  if ($auto =~ /^(reqid|amount|address|reference|version|created|confirmations|processed|status|error)$/x) {
    return $self->{"\u$auto"};
  }
  if ($auto =~ /^(db|id)$/x) {
    return $self->{"\U$auto"};
  }
  die "Could not AUTOLOAD method $auto.";
}

1; # End of Business::Bitcoin::Request

=head1 NAME

Business::Bitcoin::Request - Bitcoin payment request

=head1 VERSION

 $Revision: 1.051 $
 $Date: Tue Oct 16 22:26:58 PDT 2018 $

=head1 SYNOPSIS

Business::Bitcoin::Request objects represent Bitcoin payment requests
generated by Business::Bitcoin.

    use Business::Bitcoin;

    my $bizbtc = new Business::Bitcoin (DB => '/tmp/bizbtc.db',
                                        XPUB => 'xpub...');

    my $request = $bizbtc->request(Amount => 4200);

    print ($request->verify ? "Verified\n" : "Verification failed\n");

=head1 METHODS

=head2 new

Not intended to be called directly. Business::Bitcoin::Request objects
should be created by calling the request method on a Business::Bitcoin
object.

=head2 commit

Commit the Request object to the requests database. Only the
'processed' and 'status' fields are updated in the database.

=head2 verify

Verify that the request has been paid. Returns the total unspent
balance at the address corresponding to the request if the request has
been paid, and 0 if the balance at the address is lower than the
request amount. The number of confirmations required to consider a
payment valid can be set via the confirmations accessor.

=head1 ACCESSORS

Accessors can be called with no arguments to query the value of an
object property, or with a single argument, to set the property to a
specific value (unless the property is read only).

=head2 confirmations

The number of confirmations needed to consider a payment valid.

=head2 amount

The amount of the payment request, in Satoshi. Read only.

=head2 address

The Bitcoin receiving address for the payment request. Read only.

=head2 created

The timestamp of when the request was created. Stored as an int in the
requests database. Read only.

=head2 reference

An optional reference ID for the request, to facilitate integration
with existing order systems. Stored as a text field in the requests
database. Read only.

=head2 processed

An optional property for applications to record the timestamp of when
the transaction was processed. Stored as an int in the requests
database. Read/write.

=head2 status

An optional property that can be used to record the status of the
transaction ('processed', 'shipped', 'refunded', etc.). Stored as a
text field in the requests database. Read/write.

=head2 error

If the last verify() returned undef, this accessor will return the
error string that was received from the blockchain API call.

=head2 version

The version number of this module. Read only.

=head1 AUTHOR

Ashish Gulhati, C<< <biz-btc at hash dot neomailbox.ch> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-bitcoin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Bitcoin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::Bitcoin::Request

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-Bitcoin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-Bitcoin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-Bitcoin>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-Bitcoin/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
