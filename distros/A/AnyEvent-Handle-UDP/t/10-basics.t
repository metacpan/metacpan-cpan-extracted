#! perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use AnyEvent::Handle::UDP;
use Socket qw/unpack_sockaddr_in/;
use IO::Socket::INET;

alarm 3;

{
	my $cb = AE::cv;
	my $server = AnyEvent::Handle::UDP->new(bind => [ localhost => 0 ], on_recv => $cb);
	my $port = (unpack_sockaddr_in($server->sockname))[0];
	my $client = IO::Socket::INET->new(PeerHost => 'localhost', PeerPort => $port, Proto => 'udp');
	send $client, "Hello", 0;
	is($cb->recv, "Hello", 'received "Hello"');
}

{
	my $cb = AE::cv;
	my $server = AnyEvent::Handle::UDP->new(bind => [ localhost => 0 ], on_recv => sub {
		my ($message, $handle, $client_addr) = @_;
		is($message, "Hello", "received \"Hello\"");
		$handle->push_send("World", $client_addr);
	});
	my $client = AnyEvent::Handle::UDP->new(connect => $server->sockname, on_recv => $cb);
	$client->push_send("Hello");
	is($cb->recv, "World", 'received "World"');
}
