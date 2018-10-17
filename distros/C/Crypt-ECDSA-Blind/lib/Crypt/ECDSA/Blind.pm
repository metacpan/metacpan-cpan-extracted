# -*-cperl-*-
#
# Crypt::ECDSA::Blind - Blind ECDSA signatures
# Copyright (c) Ashish Gulhati <crypt-ecdsab at hash.neo.tc>
#
# $Id: lib/Crypt/ECDSA/Blind.pm v1.015 Tue Oct 16 22:40:55 PDT 2018 $

package Crypt::ECDSA::Blind;

use warnings;
use strict;
use DBI;
use Bytes::Random::Secure;
use Math::EllipticCurve::Prime;
use Digest::SHA;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.015 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_; my $dbname = $arg{DB} || '/tmp/ceb.db';
  unlink $dbname if $arg{Clobber} and $dbname ne ':memory:';
  my $db = DBI->connect("dbi:SQLite:dbname=$dbname", undef, undef, {AutoCommit => 1});
  my @tables = $db->tables('%','%','initkeys','TABLE');
  unless ($tables[0]) {
    if ($arg{Create}) {
      return undef unless $db->do('CREATE TABLE initkeys (
		                                           Rp TEXT PRIMARY KEY,
		                                           k TEXT NOT NULL,
		                                           issued int NOT NULL
		                                         );');
      return undef unless $db->do('CREATE INDEX idx_initkeys_Rp ON initkeys(Rp);');
    }
    else {
      return undef;
    }
  }
  @tables = $db->tables('%','%','preinits','TABLE');
  unless ($tables[0]) {
    if ($arg{Create}) {
      return undef unless $db->do('CREATE TABLE preinits (
		                                           Rp TEXT PRIMARY KEY,
		                                           k TEXT NOT NULL
		                                         );');
    }
    else {
      return undef;
    }
  }
  bless { debug => 0,
	  db    => $db,
	  curve => Math::EllipticCurve::Prime->from_name('secp256k1')
	}, $class;
}

sub keygen {                               # Generate public, private key pair
  my $self = shift;
  my $random = Bytes::Random::Secure->new( Bits => 128 );
  my $d = _makerandom($self->curve->n);
  my $Q = $self->curve->g->multiply($d);
  $self->_diag("keygen(): d: $d, Q: x:" . $Q->x . ', y:' . $Q->y . "\n");
  return ((bless {Q => $Q}, 'Crypt::ECDSA::Blind::PubKey'),(bless {d => $d}, 'Crypt::ECDSA::Blind::SecKey'));
}

sub preinit {                              # Create an init vector in advance
  my $self = shift;
  my $count = $self->db->selectcol_arrayref("SELECT count() from preinits;")->[0];
  return if $count > 20;
  my ($k, $Rp, $rp);
  until ($rp) {
    $k = _makerandom($self->curve->n);
    $Rp = $self->curve->g->multiply($k);
    $rp = $Rp->x;
    $Rp = _compress($Rp);
  }
  $self->db->do("INSERT INTO preinits values ('$Rp','$k');");
}

sub init {                                 # Return an init vector
  my $self = shift;
  my ($k, $Rp, $rp) = $self->_getpreinit;
  unless ($k) {
    until ($rp) {
      $k = _makerandom($self->curve->n);
      $Rp = $self->curve->g->multiply($k);
      $rp = $Rp->x;
      $Rp = _compress($Rp);
    }
    $self->_initkey($Rp => $k);
  }
  return $Rp;
}

sub request {                                  # Create a signing request
  my ($self, %arg) = @_;
  my $n = $self->curve->n;
  my $Rp = _point_from_hex($arg{Init});
  my $rp = $Rp->x->bmod($n);
  my $A = _makerandom($n);
  my $B = _makerandom($n);
  my $R = $Rp->multiply($A)->add($self->curve->g->multiply($B));
  my $r = $R->x->bmod($n);
  my $hasher = Digest::SHA->new('sha256');
  $hasher->add($arg{Message});
  my $hash = $hasher->hexdigest; $hash =~ s/\s//g;
  my $H = Math::BigInt->from_hex($hash);
  my $mp = ($A * $H * $rp * $r->copy->bmodinv($n))->bmod($n);
  $self->_request($arg{Init} => { R => $R, B => $B, H => $H });
  $self->_diag("request(): mp: $mp\n");
  return $mp;
}

sub sign {                                 # Create a blind signature
  my ($self, %arg) = @_;
  my $n = $self->curve->n;
  my $Rp = _point_from_hex($arg{Init});
  my $rp = $Rp->x->bmod($n);
  return unless my $k = $self->_initkey($arg{Init});
  my $sp = ($arg{Key}->d * $rp + $k * $arg{Message})->bmod($n);
  $self->_diag("sign(): sp: $sp\n");
  return $sp;
}

sub unblind {                              # Unblind a blind signature
  my ($self, %arg) = @_;
  my $n = $self->curve->n;
  my $Rp = _point_from_hex($arg{Init});
  my $rp = $Rp->x->bmod($n);
  return unless my $req = $self->_request($arg{Init});
  my $r = $req->{R}->x->bmod($n);
  # Check here that sp and rp are in the range (1, n-1)
  my $s = ($arg{Signature} * $r * $rp->copy->bmodinv($n) + $req->{H} * $req->{B})->bmod($n);
  $self->_diag("unblind(): s: $s\n"); $s = $s->as_hex; $s =~ s/^0x//;
  return ( bless { s => $s,
		   R => _compress($req->{R})
		 }, 'Crypt::ECDSA::Blind::Signature' );
}

sub verify {                               # Verify a signature
  my ($self, %arg) = @_;
  my $r = $arg{Signature}->R->x->bmod($self->curve->n);
  my $Q = $arg{Key}->Q;
  my $hasher = Digest::SHA->new('sha256');
  $hasher->add($arg{Message});
  my $hash = $hasher->hexdigest; $hash =~ s/\s//g;
  my $H = Math::BigInt->from_hex($hash);
  $self->_diag('verify(): s: ' . $arg{Signature}->s . ', R(x): ' . $arg{Signature}->R->x . ", H: $H\n");
  my $u1 = $self->curve->g->multiply($arg{Signature}->s);
  my $u2 = $Q->multiply($r)->add($arg{Signature}->R->multiply($H));
  $self->_diag('verify(): u1: ' . $u1->x . ', u2: ' . $u2->x . "\n");
  $u1->to_hex eq $u2->to_hex;
}

sub _getpreinit {                          # Get a pre-created init vector
  my $self = shift;
  my $timestamp = time;
  while (1) {
    my ($k,$Rp) = $self->db->selectrow_array("SELECT k,Rp FROM preinits LIMIT 1;");
    return undef unless $k;
    $self->db->do("DELETE FROM preinits WHERE k='$k';");
    next unless $self->db->do("INSERT INTO initkeys values ('$Rp','$k','$timestamp');");
    return ($k, $Rp);
  }
}

sub _initkey {                             # Save or destructively retrieve a saved init vector
  my $self = shift;
  my $Rp = $_[0]; my $timestamp = time;
  if ($_[1]) {
    $self->db->do("INSERT INTO initkeys values ('$Rp','$_[1]','$timestamp');");
  }
  else {
    my $k = $self->db->selectcol_arrayref("SELECT k from initkeys WHERE Rp='$Rp';")->[0];
    $self->db->do("DELETE FROM initkeys WHERE Rp='$Rp';");
    return Math::BigInt->new($k);
  }
}

sub _request {                             # Save or destructively retrieve a saved request
  my $self = shift;
  my $Rp = $_[0]; my $ret;
  if ($_[1]) {
    $self->{Requests}->{$Rp} = $_[1];
  }
  else {
    $ret = $self->{Requests}->{$Rp};
    delete $self->{Requests}->{$Rp};
  }
  return $ret;
}

sub _makerandom {
  my $n = shift; my $nlen = length($n->as_bin)-2;
  my $random = Bytes::Random::Secure->new( Bits => 128 );
  my $r = 0;
  $r = Math::BigInt->from_bin($random->string_from('01',$nlen)) until ($r > 1 and $r < $n);
  return $r;
}

sub _point_from_hex {
  my $P = Math::EllipticCurve::Prime::Point->from_hex(_decompress(shift));
  $P->curve(Math::EllipticCurve::Prime->from_name('secp256k1'));
  $P;
}

sub _decompress {
  my $Kc = shift; $Kc =~ /^(..)(.*)/;
  my $i = $1; my $K = '04' . '0' x (64 - length($2)) . $2; my $x = Math::BigInt->from_hex($2);
  my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');
  my ($p, $a, $b) = ($curve->p, $curve->a, $curve->b);
  my $y = ($x->bmodpow(3,$p)+$a*$x+$b)->bmodpow(($p+1)/4,$p);
  $y = $p - $y if $i%2 ne $y%2;
  my $yhex = $y->as_hex; $yhex =~ s/^0x//;
  $K .= '0' x (64 - length($yhex)) . $yhex; # print "D:$K\n";
  return $K;
}

sub _compress {
  my $K = shift; # print 'C:'. $K->to_hex . "\n";
  my $Kc = $K->x->as_hex; $Kc =~ s/^0x//;
  $Kc = '0' x (64 - length($Kc)) . $Kc;
  $Kc = ($K->y % 2 ? '03' : '02') . $Kc;
}

sub _diag {
  my $self = shift;
  print @_ if $self->debug;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(db|debug)$/x) {
    $self->{$auto} = shift if (defined $_[0]);
  }
  if ($auto =~ /^(curve|db|debug)$/x) {
    return $self->{$auto};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1; # End of Crypt::ECDSA::Blind

package Crypt::ECDSA::Blind::PubKey;

sub write {
  1;
}

sub as_hex {
  Crypt::ECDSA::Blind::_compress(shift->Q);
}

sub from_hex {
  bless {Q => Crypt::ECDSA::Blind::_point_from_hex(shift)}, 'Crypt::ECDSA::Blind::PubKey';
}

sub Q {
  shift->{Q};
}

1; # End of Crypt::ECDSA::Blind::PubKey

package Crypt::ECDSA::Blind::SecKey;

sub as_hex {
  my $d = shift->d->as_hex; $d =~ s/^0x//;
  $d;
}

sub from_hex {
  bless {d => Math::BigInt->from_hex(shift)}, 'Crypt::ECDSA::Blind::SecKey';
}

sub write {
  1;
}

sub d {
  shift->{d};
}

1; # End of Crypt::ECDSA::Blind::SecKey

package Crypt::ECDSA::Blind::Signature;

sub s {
  Math::BigInt->from_hex(shift->{'s'});
}

sub R {
  Crypt::ECDSA::Blind::_point_from_hex(shift->{R});
}

sub is_valid {
  my $self = shift;
  $self->{R} =~ /^[0-9a-f]+$/ and $self->{s} =~ /^[0-9a-f]+$/;
}

1; # End of Crypt::ECDSA::Blind::Signature

__END__

=head1 NAME

Crypt::ECDSA::Blind - Blind ECDSA Signatures

=head1 VERSION

 $Revision: 1.015 $
 $Date: Tue Oct 16 22:40:55 PDT 2018 $

=head1 SYNOPSIS

This module implements the blind ECDSA signature protocol outlined in
[1].

    use Crypt::ECDSA::Blind;

    my $ecdsab = new Crypt::ECDSA::Blind;

    my ($pubkey, $seckey) = $ecdsab->keygen;

    my $msg = 'Hello, world!';

    my $init = $ecdsab->init;

    my $req = $ecdsab->request( Key => $pubkey, Init => $init,
                                Message => $msg );

    my $blindsig = $ecdsab->sign( Key => $seckey, Init => $init,
                                  Plaintext => $req );

    my $sig = $ecdsab->unblind( Key => $pubkey, Init => $init,
                                Signature => $blindsig );

    print "Verified\n" if $ecdsab->verify( Key => $pubkey, Message => $msg,
                                           Signature => $sig );

=head1 METHODS

=head2 new

Creates and returns a new Crypt::ECDSA::Blind object. The following
optional named parameters can be provided:

=over

DB - Full pathname of a file to use for the database of initialization
vectors. This can also be the special filename ':memory:' in which
case the database will be in RAM rather than on a disk file. The
default is '/tmp/ceb.db'.

=back

=head2 keygen

Generates and returns an ECDSA key-pair for blind signing.

=head2 init

Generates and returns an initialization vector for blind signing. The
initialization vector should be passed in to the request(), sign() and
unblind() methods in the Init named parameter.

=head2 preinit

Generates and saves an initialization vector for later retrieval by
init. Keeping pre-prepared initialization vectors available for use on
demand will speed up calls to init.

=head2 request

Generates and returns a blind signing request. The following named
parameters are required:

=over

Init - The initialization vector from init()

Key - The public key of the signer

Message - The message to be blind signed

=back

=head2 sign

Generates and returns a blind signature. The following named
parameters are required:

=over

Init - The initialization vector from init()

Key - The private key of the signer

Plaintext - The blind-signing request

=back

=head2 unblind

Unblinds a blind signature and returns a verifiable signature. The
following named parameters are required:

=over

Init - The initialization vector from init()

Key - The public key of the signer

Signature - The blind signature

=back

=head2 verify

Verify a signature. The dollowing named parameters are required:

=over

Key - The public key of the signer

Signature - The blind signature

Message - The message that was signed

=back

=head1 ACCESSORS

Accessors can be called with no arguments to query the value of an
object property, or with a single argument, to set the property to a
specific value (unless it is read-only).

=head2 db

The filename of the file to use for the database of initialization
vectors. Default is '/tmp/ceb.db'.

=head2 debug

Set true to emit helpful messages for debugging purposes, false
otherwise. Default is false.

=head1 REFERENCES

1. A blind digital signature scheme using elliptic curve digital
signature algorithm, Ismail Butun, Mehmet Demirer. L<http://journals.tubitak.gov.tr/elektrik/abstract.htm?id=13855>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-ecdsab at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-ecdsa-blind at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-ECDSA-Blind>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::ECDSA::Blind

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-ECDSA-Blind>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-ECDSA-Blind>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-ECDSA-Blind>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-ECDSA-Blind/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
