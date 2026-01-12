#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent qw(session);
use Claude::Agent::Options;

# Test session export
can_ok('main', 'session');

# Test session returns Client object
my $client = session(
    options => Claude::Agent::Options->new(
        allowed_tools => ['Read', 'Glob'],
    ),
);

isa_ok($client, 'Claude::Agent::Client', 'session() returns Client object');

# Test session with loop parameter
SKIP: {
    eval { require IO::Async::Loop };
    skip "IO::Async::Loop not installed", 2 if $@;

    my $loop = IO::Async::Loop->new;
    my $async_client = session(
        options => Claude::Agent::Options->new(
            allowed_tools => ['Read'],
        ),
        loop => $loop,
    );

    isa_ok($async_client, 'Claude::Agent::Client', 'session() with loop returns Client');
    ok($async_client->has_loop, 'Client has loop attribute set');
}

# Test client methods exist
can_ok($client, 'connect');
can_ok($client, 'send');
can_ok($client, 'receive');
can_ok($client, 'receive_async');
can_ok($client, 'disconnect');
can_ok($client, 'is_connected');
can_ok($client, 'session_id');

# Test initial state
ok(!$client->is_connected, 'Client is not connected initially');
is($client->session_id, undef, 'session_id is undef before connect');

# Test disconnect on unconnected client (should not throw)
eval { $client->disconnect };
ok(!$@, 'disconnect on unconnected client does not throw');

# Test receive throws when not connected
eval { $client->receive };
like($@, qr/Not connected/, 'receive throws when not connected');

# Test send throws when not connected
eval { $client->send('test') };
like($@, qr/Not connected/, 'send throws when not connected');

done_testing();
