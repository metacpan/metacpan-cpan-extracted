=head1 NAME

AnyEvent::Ping::TCP - Asynchronous and Synchronous TCP ping functions.

=head1 SYNOPSIS

  use AnyEvent::Ping::TCP;
  
  # Synchronous TCP Ping
  my $latency = tcp_ping 'www.google.co.nz', 80;
  
  # Asynchronous TCP Ping
  tcp_ping_syn 'www.google.co.nz', 80;
  
  # Sometime later
  my $latency = tcp_ping_ack 'www.google.co.nz', 80;
  
=head1 DESCRIPTION

This module provides a very simple implementation of TCP Ping, with both an asynchronous and synchronous interface.

Latency is always returned in milliseconds, and is provided by Time::HiRes

Socket functionality is provided by AnyEvent::Socket

All functions are exported by default.

=cut

package AnyEvent::Ping::TCP;

use strict;
use warnings;

use AnyEvent;
use AnyEvent::Socket;
use Time::HiRes qw ( time );

use base 'Exporter';

our @EXPORT = qw( tcp_ping_syn tcp_ping_ack tcp_ping );

our $VERSION = '1.01';

our %PingQueue = ();

=head2 Synchronous API

=over 4
 
=item $latency = tcp_ping $site, $port [, $timeout]

Measures the time taken to connect to the provided $site:$port and returns it synchronously.

$timeout is optional, and defaults to 5 seconds if not provided.

=back

=cut

sub tcp_ping {
	my $host = shift;
	my $port = shift;
	my $timeout = shift || 5;

	tcp_ping_syn($host, $port, $timeout);
	return tcp_ping_ack($host, $port);
}

=head2 Asynchronous API

=over 4

=item tcp_ping_syn $site, $port [, $timeout]

Initiates the connection to the provided $site:$port and sets a callback to calculate the latency. Correct latency measurement is
not dependant on timely calls to tcp_ping_ack. 

$timeout is optional, and defaults to 5 seconds if not provided.

If this function is called multiple times for the same $site:$port pair, a counter indicating the number of responses requrested is 
incremented per call, but additional connections are not initiated - it is therefore safe to call this function on an unsorted list of
$site:$port pairs.

=cut

sub tcp_ping_syn {
	my $host = shift;
	my $port = shift;
	my $timeout = shift || 5;

	if ((++$PingQueue{$host}{$port}{Requests}) > 1) {
		# Ping already underway...
		return;
	}	
	
	my $cv = AnyEvent->condvar;
	my $startTime;
	my $endTime;
	
	$PingQueue{$host}{$port}{CondVar} = $cv;
	
	tcp_connect $host, $port, sub {
 		$endTime = time;
		my ($fh) = @_;
 		
		$cv->send(( $fh ? (($endTime - $startTime) * 1000) : undef ));
	},
	sub {
		$startTime = time;
		$timeout;
	};
		
	return undef;
}

=item $latency = tcp_ping_ack $site, $port;

Waits for the latency of the connection to the $site:$port pair. If the connection has already completed, it returns the latency immediately.

This function uses the counter maintained by tcp_ping_syn to know how many responses are expected before cleaning up the memory associated with
the ping operation. Again, this allows the calling program to be fairly naive about the lists it uses. All tcp_ping_syn calls for a given
$site:$port pair will yield the same latency value until tcp_ping_ack has drained the queue. Only then will a new connection and measurement
be taken.

=back

=cut   

sub tcp_ping_ack {
	my $host = shift;
	my $port = shift;
			
	if ($PingQueue{$host}{$port}{Requests} < 1) {
		# No outstanding requests...
		return undef;
	}	

	my $latency = $PingQueue{$host}{$port}{CondVar}->recv;
	
	if ((--$PingQueue{$host}{$port}{Requests}) < 1) {
		# Responded to last request.
		$PingQueue{$host}{$port}{CondVar} = undef;	
	}
	
	return $latency;	
}


=head1 SEE ALSO

L<AnyEvent>
L<AnyEvent::Socket>
L<Time::HiRes>

=head1 AUTHOR

Phillip O'Donnell, E<lt>podonnell@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Phillip O'Donnell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

