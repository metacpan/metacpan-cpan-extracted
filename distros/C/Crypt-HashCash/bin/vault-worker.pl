#!/usr/bin/perl
# -*-cperl-*-
#
# vault-worker.pl - Vault worker for HashCash Digital Cash
# Copyright (c) 2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: bin/vault-worker.pl v1.127 Sat Sep 16 18:48:11 PDT 2017 $

use strict;
use warnings;

use Crypt::HashCash::Vault::Bitcoin;
use Crypt::HashCash::Coin::Blinded;
use Crypt::HashCash::CoinRequest;
use Crypt::HashCash::Coin;
use Crypt::HashCash qw (_dec _hex _dectob85 _b85todec);
use Crypt::Random qw(makerandom);
use Crypt::EECDH;
use Crypt::CBC;
use File::HomeDir;
use Digest::MD5 qw(md5_hex);
use IPC::Queue::Duplex;

my $HASHCASH = $ENV{HASHCASHDIR} || File::HomeDir->my_home . '/.hashcash';

unless (-d $HASHCASH) {
  die "Directory $HASHCASH doesn't exist and couldn't be created.\n" unless mkdir($HASHCASH, 0700);
}

unless (-d "$HASHCASH/vaults") {
  die "Directory $HASHCASH/.vaults doesn't exist and couldn't be created.\n" unless mkdir("$HASHCASH/vaults", 0700);
}

my $vault = new Crypt::HashCash::Vault::Bitcoin ( DB => "$HASHCASH/vault.db",
						  KeyDB => "$HASHCASH/vaults/vault.key" );

if (!-f "$HASHCASH/vaults/vault.key" or (defined $ARGV[0] and $ARGV[0] eq '--keygen')) {
  $|=1;
  print STDERR "Generating vault keys... ";
  $vault->keygen( Name   => 'localhost',
		  Server => 'localhost',
		  Port   => '20203',
		  Fees   => { mf => 50, mp => 0, vf => 50, vp => 0.001 } );
  print "done.\n";
}

$vault->mint->loadkeys();
my $sk = pack ('H*',$vault->mint->keydb->{vaultsec});
my $queue = new IPC::Queue::Duplex ( Dir => '/tmp' );

while(1){
  my ($job, $pubkey, $keyhex, $ret, $preret, $sendto, $sendamt);
  my $eecdh = new Crypt::EECDH;
  unless ($job = $queue->get) {
    $vault->mint->signer->preinit if $vault->mint->sigscheme eq 'ECDSA';
    next;
  }
  $_ = $job->{Request};
  alarm(0);
  /^(\S+)\s?(\S+)?\s?(\S+)?/;
  if ($1 eq 'es') {                                   # Electrum signing request from external server
    my $electrum = '/home/hash/src/Electrum-2.8.2/electrum';
    my $withdrawid = $3;
    my $tx = "{\n\"complete\": false,\n\"final\": true,\n\"hex\": \"$2\"\n}";
    my $txdetails = `$electrum deserialize '$tx'`;    # Check transaction details
    my $addresses = `$electrum listaddresses --change`;
    my @addresses = map { /\"(\S+)\"/; $1; } split /,\s*/, $addresses;
    $txdetails =~ /\"outputs\": (.*)/s; my $outputs = $1;
    my @outputs = map { /\"address\": \"(\S+?)\".*\"value\": (\d+)/s; ($1 => $2) } split /\}\,/s, $outputs;
    my $query = "SELECT sendto,sendamt from withdrawals WHERE id='$withdrawid';";
    print STDERR "ERR: couldn't retrieve withdrawal params.\n" unless my ($sndto, $sndamt) = $vault->bizbtc->db->selectrow_array($query);
    $job->finish('ERR'), next unless $outputs[0] eq $sndto and $outputs[1] == $sndamt;
    my $err;
    for (2..$#outputs) {
      next if $_ % 2; my $o = $outputs[$_];
      $job->finish('ERR'), $err = 1, last unless grep { /^$o$/ } @addresses;
    }
    next if $err;
    my $signedtx = `$electrum signtransaction '$tx'`;
    $signedtx =~ /"hex": "(\S+)"/s;
    $job->finish("eb $1");
    next;
  }
  elsif ($1 eq 'ed') {                                # Electrum payment completed
    my $id = $2; my $txid = $3;
    my $query = "SELECT key,ret from withdrawals WHERE id='$id';";
    print STDERR "ERR: couldn't retrieve saved withdrawal params.\n" unless ($keyhex, $ret) = $vault->bizbtc->db->selectrow_array($query);
    $vault->bizbtc->db->do("DELETE FROM withdrawals WHERE id='$id';");
    my $key = pack 'H*', $keyhex;
    $ret = "OK $txid";
  }
  else {                                              # Decrypt the message and get the key to encrypt reply with
#    my $enchex = _hex(_b85todec($1));
    my $enchex = _hex($1);
    my $request;
    ($request, $pubkey) = $eecdh->decrypt (Key => $sk, Ciphertext => pack ('H*', $enchex));
    ($ret, $preret, $sendto, $sendamt) = $vault->process_request($request);   # Process the request
#    ($ret, $preret, $sendto, $sendamt) = $vault->process_request($request, 1);   # Process the request (air-gapped mode)
  }

  if (defined $preret) {                              # Send unencrypted payment request to online machine
    # Save $key, $ret for when we actually finish this request
    my $withdrawid = makerandom( Size => 32, Strength => 0 );
    diag("INSERT INTO withdrawals values ('$withdrawid', '$keyhex', '$ret', '$sendto', '$sendamt');");
    unless ($vault->bizbtc->db->do("INSERT INTO withdrawals values ('$withdrawid', '$keyhex', '$ret', '$sendto', '$sendamt');")) {
      diag("INSERT INTO withdrawals values ('$withdrawid', '$keyhex', '$ret');");
      # TODO: log an error and tx details
    }
    $job->finish("$preret $withdrawid");
  }
  elsif (defined $ret) {                              # Encrypt and return response
    my ($encrypted) = $eecdh->encrypt (PublicKey => $pubkey, Message => $ret);
    my $response = _dec(unpack 'H*', $encrypted);
    diag("R: $ret\n\n");
#    $job->finish(_dectob85($response));
    $job->finish($response);
  }
}

sub diag {
  print STDERR shift if 1;
}

package Business::Bitcoin::Request;

use IPC::Queue::Duplex;

sub verify_serial {
  my $self = shift;
  my $vqueue = new IPC::Queue::Duplex ( Dir => '/tmp/verify' );
  my $verify = $vqueue->add($self->address);
  my $paid = $verify->response;
  $self->error($paid), return if $paid =~ /\D/;
  $self->error('');
  $paid >= $self->amount ? $paid : 0;
}

__END__

=head1 NAME

vault-worker.pl - Vault worker for HashCash Digital Cash

=head1 VERSION

 $Revision: 1.127 $
 $Date: Sat Sep 16 18:48:11 PDT 2017 $

=head1 SYNOPSIS

  vault-worker.pl [--keygen]

=head1 DESCRIPTION

vault-worker.pl is a worker for a vault in the HashCash digital cash
system. It picks up requests from the queue and writes responses back
to the queue.

A cluster of systems can run vault-worker.pl with the queue shared
between them via SSHFS. For the best security, vault worker systems
can be offline and air-gapped off from the Internet. For more details
on this, see L<IPC::Queue::Duplex> and L<IPC::Serial>.

=head1 COMMAND LINE OPTIONS

=over

=item B<--keygen>

=back

=over

Create blind-signing keys for all coin denominations supported by the
vault.

=back

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<vault.pl>

=head2 L<vault-queuer.pl>

=head2 L<IPC::Serial>

=head2 L<IPC::Queue::Duplex>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this command with the perldoc command.

    perldoc vault-worker.pl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-HashCash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-HashCash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-HashCash>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-HashCash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
