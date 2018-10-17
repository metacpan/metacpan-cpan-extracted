#!/usr/bin/perl
# -*-cperl-*-
#
# vault.pl - Vault server for HashCash Digital Cash
# Copyright (c) 2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: bin/vault.pl v1.129 Tue Oct 16 16:56:38 PDT 2018 $

use strict;
use warnings;

package Crypt::HashCash::Vault;

use vars qw(@ISA);
use Crypt::HashCash::Vault::Bitcoin;
use Crypt::HashCash::Coin::Blinded;
use Crypt::HashCash::CoinRequest;
use Crypt::HashCash::Coin;
use Crypt::HashCash qw (_dec _hex);
use Crypt::EECDH;
use Digest::MD5 qw(md5_hex);
use Net::Server::PreFork;
use File::HomeDir;
use Crypt::CBC;

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

@ISA = qw(Net::Server::PreFork);

Crypt::HashCash::Vault->run();
exit;

sub process_request {
  my $self = shift;
  eval {
    local $SIG{ALRM} = sub { die "Timed Out!\n" };
    my $timeout = 60;                                    # Give client 60 seconds to send input
    alarm($timeout);
    while (<STDIN>) {
      /(\S+)/;                                           # Decrypt the message and get the key to encrypt reply with
      my $enchex = _hex($1);
      my $eecdh = new Crypt::EECDH;
      my ($request, $pubkey) = $eecdh->decrypt (Key => $sk, Ciphertext => pack ('H*', $enchex));
      diag("REQ: $request\n");
      alarm(0);
      my ($ret) = $vault->process_request($request);     # Process the request
      diag("RET: $ret\n");
      if ( defined $ret) {                               # Encrypt and return response
	my ($encrypted) = $eecdh->encrypt (PublicKey => $pubkey, Message => $ret);
	my $response = _dec(unpack 'H*', $encrypted);
	diag("RES: $response\n");
	print "$response\n";
      }
      alarm($timeout);
    }
  };
  if( $@=~/timed out/i ){
    print STDERR "Timed out\n";
    return;
  }
}

sub diag {
  print STDERR shift if 0;
}

1;

__END__

=head1 NAME

vault.pl - Vault for HashCash Digital Cash

=head1 VERSION

 $Revision: 1.129 $
 $Date: Tue Oct 16 16:56:38 PDT 2018 $

=head1 SYNOPSIS

  vault.pl [--keygen]

=head1 DESCRIPTION

vault.pl is a server for a vault in the HashCash digital cash
system. It accepts connections from clients, processes their requests
and returns the responses.

This command is primarily for testing. For real vaults, optimal
security and performance can be achieved by running the vault on an
air-gapped cluster (see L<vault-worker.pl> and L<vault-queuer.pl>).

=head1 COMMAND LINE OPTIONS

=head2 --keygen

Create blind-signing keys for all coin denominations supported by the
vault.

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<vault-worker.pl>

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

    perldoc vault.pl

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

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
