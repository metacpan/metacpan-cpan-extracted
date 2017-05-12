#! perl

use strict;
use warnings FATAL => 'all';
use Test::More 0.89;
use Test::Fatal;

use AnyEvent::Handle::UDP;
use IO::Socket::INET;

alarm 12;

{
	my $cb = AE::cv;
	my $cb2 = AE::cv;
	my $server = AnyEvent::Handle::UDP->new(
		bind => [ localhost => 0 ],
		on_recv => $cb, 
		timeout => 3,    on_timeout => sub { $cb->croak("Timeout") },
		rtimeout => 4.5, on_rtimeout => sub { $cb2->croak("Read Timeout") }
	);
	my $start_time = AE::now;
	like(exception { $cb->recv }, qr/Timeout/, 'Receive throws a timeout');
	cmp_ok AE::now, '>=', $start_time + 3, 'Three seconds have passed';
	like(exception { $cb2->recv }, qr/Read Timeout/, 'Receive throws a timeout again');
	cmp_ok AE::now, '>=', $start_time + 4.5, '1.5 more seconds have passed';
	$server->timeout_reset;
	my $cb3 = AE::cv;
	$server->on_timeout(sub { $cb3->croak('Reset') });
	like(exception { $cb3->recv }, qr/Reset/, 'Receive throws a timeout again');
	cmp_ok AE::now, '>=', $start_time + 7.5, '3 more seconds have passed';
}

done_testing;
