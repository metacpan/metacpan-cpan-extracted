#!/usr/bin/perl
# -*-cperl-*-
#
# vault-queuer.pl - Queuer for Offline HashCash Digital Cash Vault
# Copyright (c) 2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: bin/vault-queuer.pl v1.126 Sat Jun 24 02:15:19 PDT 2017 $

use warnings;
use strict;

package Crypt::HashCash::Vault::Queuer;

use vars qw(@ISA);
use Net::Server::PreFork;
use IPC::Queue::Duplex;
use Crypt::HashCash qw(_dectob85 _b85todec);

@ISA = qw(Net::Server::PreFork);

my $queue = new IPC::Queue::Duplex ( Dir => '/tmp' );

Crypt::HashCash::Vault::Queuer->run();
exit;

sub process_request {
  my $self = shift;
  eval {
    local $SIG{ALRM} = sub { die "Timed Out!\n" };
    my $timeout = 60;                                    # Give client 60 seconds to send input
    alarm($timeout);
    while( <STDIN> ){
      chomp; s/\r//;
      unless (/^\S{3,}/) {
	print "-ERR Invalid input\n";
	next;
      }
      my $job = $queue->add($_);
#      my $job = $queue->add(_dectob85($_));
      alarm(0);
      my $res = $job->response;
      if ($res =~ /^ep (\S+) (\d+) (\d+) (\d+)$/) {
	my $sendto = $1; my $withdrawid = $4;
	my $sendamt = $2 / 100000000; my $feeamt = $3 / 100000000;
	my $electrum = '/home/hash/src/Electrum-2.8.2/electrum';
	my $balance = `$electrum getbalance`;
	$balance =~ /"confirmed": "(\S+)"/s; $balance = $1 * 100000000;
	# TODO: Return error if wallet balance lower than send amount
	my $tx = `$electrum payto $sendto $sendamt -f $feeamt -u`;
	print STDERR "T:$tx:\n";
	$tx =~ /"hex": "(\S+)"/s;
	my $job2 = $queue->add("es $1 $withdrawid");
	$res = $job2->response;
	$res =~ /^eb (\S+)/;
	my $signedtx = "{\n\"complete\": true,\n\"final\": true,\n\"hex\": \"$1\"\n}";
#	my $id = `$electrum broadcast '$signedtx'`;
	diag("$electrum broadcast '$signedtx'");
	my $id = '1234';
	$job2 = $queue->add("ed $withdrawid $id");
	print _b85todec($job2->response) . "\n";
      }
      else {
	print "$res\n";
#	print _b85todec($res) . "\n";
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
  print STDERR shift if 1;
}

__END__

=head1 NAME

vault-queuer.pl - Vault enqueuer for HashCash Digital Cash

=head1 VERSION

 $Revision: 1.126 $
 $Date: Sat Jun 24 02:15:19 PDT 2017 $

=head1 SYNOPSIS

  vault-queuer.pl

=head1 DESCRIPTION

vault-queuer.pl is an enqueuer for requests to a vault in the HashCash
digital cash system. It accepts client connections over the Internet,
writes requests to the queue, waits for responses and returns those to
the client.

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<vault.pl>

=head2 L<vault-worker.pl>

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

    perldoc vault-queuer.pl

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
