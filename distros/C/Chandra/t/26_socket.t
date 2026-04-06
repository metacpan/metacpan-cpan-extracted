#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Socket::UNIX;

# Socket tests require Unix sockets
plan skip_all => 'Unix sockets not available' unless eval { IO::Socket::UNIX->new; 1 } || 1;

plan tests => 47;

use_ok('Chandra::Socket::Connection');
use_ok('Chandra::Socket::Hub');
use_ok('Chandra::Socket::Client');

# === Frame encoding ===
{
	my $frame = Chandra::Socket::Connection->encode_frame({ channel => 'test', data => { x => 1 } });
	ok(defined $frame, 'encode_frame returns data');
	my $len = unpack('N', substr($frame, 0, 4));
	is($len, length($frame) - 4, 'length prefix matches payload');
}

# === Frame decoding ===
{
	my $msg = { channel => 'hello', data => { name => 'world' } };
	my $frame = Chandra::Socket::Connection->encode_frame($msg);
	my @decoded = Chandra::Socket::Connection->decode_frames($frame);
	is(scalar @decoded, 1, 'decoded one message');
	is($decoded[0]->{channel}, 'hello', 'channel preserved');
	is($decoded[0]->{data}{name}, 'world', 'data preserved');
}

# === Multiple frames in one buffer ===
{
	my $f1 = Chandra::Socket::Connection->encode_frame({ channel => 'a', data => 1 });
	my $f2 = Chandra::Socket::Connection->encode_frame({ channel => 'b', data => 2 });
	my @decoded = Chandra::Socket::Connection->decode_frames($f1 . $f2);
	is(scalar @decoded, 2, 'decoded two messages from concatenated buffer');
	is($decoded[0]->{channel}, 'a', 'first message channel');
	is($decoded[1]->{channel}, 'b', 'second message channel');
}

# === Partial frame decoded as empty ===
{
	my $frame = Chandra::Socket::Connection->encode_frame({ channel => 'x', data => 1 });
	my $partial = substr($frame, 0, 6);  # incomplete payload
	my @decoded = Chandra::Socket::Connection->decode_frames($partial);
	is(scalar @decoded, 0, 'partial frame returns no messages');
}

# === Connection via socketpair ===
{
	use Socket;
	socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0)
		or die "socketpair: $!";
	$s1->blocking(0);
	$s2->blocking(0);

	my $conn1 = Chandra::Socket::Connection->new(socket => $s1, name => 'side-a');
	my $conn2 = Chandra::Socket::Connection->new(socket => $s2, name => 'side-b');

	ok($conn1->is_connected, 'conn1 is connected');
	ok($conn2->is_connected, 'conn2 is connected');
	is($conn1->name, 'side-a', 'conn1 name');
	is($conn2->name, 'side-b', 'conn2 name');

	# Send from conn1, receive on conn2
	ok($conn1->send('ping', { val => 42 }), 'conn1 send succeeded');

	# Small delay for the socket buffer
	select(undef, undef, undef, 0.05);

	my @msgs = $conn2->recv;
	is(scalar @msgs, 1, 'conn2 received one message');
	is($msgs[0]->{channel}, 'ping', 'channel is ping');
	is($msgs[0]->{data}{val}, 42, 'data val is 42');
	is($msgs[0]->{from}, 'side-a', 'from is side-a');

	# Reply
	ok($conn2->send('pong', { val => 99 }), 'conn2 reply succeeded');
	select(undef, undef, undef, 0.05);

	my @replies = $conn1->recv;
	is(scalar @replies, 1, 'conn1 received reply');
	is($replies[0]->{channel}, 'pong', 'reply channel is pong');
	is($replies[0]->{data}{val}, 99, 'reply data val is 99');

	# Close
	$conn1->close;
	ok(!$conn1->is_connected, 'conn1 disconnected after close');

	$conn2->close;
}

# === Hub creation (Unix socket) ===
{
	my $name = "test-hub-$$";
	my $dir = $ENV{XDG_RUNTIME_DIR} || $ENV{TMPDIR} || '/tmp';
	my $path = "$dir/chandra-$name.sock";
	my $token_path = "$path.token";
	unlink $path if -e $path;

	my $hub = Chandra::Socket::Hub->new(name => $name);
	ok(-e $path, 'Unix socket file created');
	ok(-e $token_path, 'token file created');
	ok(length($hub->token) >= 16, 'token is non-trivial');

	$hub->close;
	ok(!-e $path, 'Unix socket file removed on close');
	ok(!-e $token_path, 'token file removed on close');
}

# === Hub + Client connection lifecycle ===
{
	my $name = "test-lifecycle-$$";
	my $hub = Chandra::Socket::Hub->new(name => $name);

	my @connected;
	my @disconnected;
	$hub->on_connect(sub { push @connected, $_[0]->name });
	$hub->on_disconnect(sub { push @disconnected, $_[0]->name });

	# Client connects
	my $client = Chandra::Socket::Client->new(name => 'win-1', hub => $name);
	ok($client->is_connected, 'client is connected');

	# Poll hub to process accept + handshake
	select(undef, undef, undef, 0.05);
	$hub->poll;
	select(undef, undef, undef, 0.05);
	$hub->poll;
	is(scalar @connected, 1, 'on_connect fired');
	is($connected[0], 'win-1', 'client name is win-1');
	is(scalar $hub->clients, 1, 'hub has one client');

	# Client sends message to hub
	my @received;
	$hub->on('status', sub { push @received, $_[0] });
	$client->send('status', { ready => 1 });
	select(undef, undef, undef, 0.05);
	$hub->poll;
	is(scalar @received, 1, 'hub received status message');
	is($received[0]->{ready}, 1, 'status data correct');

	# Hub broadcasts to client
	my @client_msgs;
	$client->on('config', sub { push @client_msgs, $_[0] });
	$hub->broadcast('config', { theme => 'dark' });
	select(undef, undef, undef, 0.05);
	$client->poll;
	is(scalar @client_msgs, 1, 'client received broadcast');
	is($client_msgs[0]->{theme}, 'dark', 'broadcast data correct');

	# Hub send_to specific client
	my @direct_msgs;
	$client->on('direct', sub { push @direct_msgs, $_[0] });
	$hub->send_to('win-1', 'direct', { msg => 'hello' });
	select(undef, undef, undef, 0.05);
	$client->poll;
	is(scalar @direct_msgs, 1, 'client received direct message');
	is($direct_msgs[0]->{msg}, 'hello', 'direct message data correct');

	# Client disconnect
	$client->close;
	select(undef, undef, undef, 0.05);
	$hub->poll;
	is(scalar @disconnected, 1, 'on_disconnect fired');
	is($disconnected[0], 'win-1', 'disconnected client name correct');
	is(scalar $hub->clients, 0, 'hub has no clients after disconnect');

	$hub->close;
}

# === Multiple spokes ===
{
	my $name = "test-multi-$$";
	my $hub = Chandra::Socket::Hub->new(name => $name);

	my $s1 = Chandra::Socket::Client->new(name => 'panel-1', hub => $name);
	select(undef, undef, undef, 0.05);
	$hub->poll;
	select(undef, undef, undef, 0.05);
	$hub->poll;

	my $s2 = Chandra::Socket::Client->new(name => 'panel-2', hub => $name);
	select(undef, undef, undef, 0.05);
	$hub->poll;
	select(undef, undef, undef, 0.05);
	$hub->poll;
	is(scalar $hub->clients, 2, 'hub has two clients');

	# Broadcast reaches both
	my (@m1, @m2);
	$s1->on('update', sub { push @m1, $_[0] });
	$s2->on('update', sub { push @m2, $_[0] });
	$hub->broadcast('update', { data => 'all' });
	select(undef, undef, undef, 0.05);
	$s1->poll;
	$s2->poll;
	is(scalar @m1, 1, 'client 1 got broadcast');
	is(scalar @m2, 1, 'client 2 got broadcast');

	$s1->close;
	$s2->close;
	$hub->close;
}
