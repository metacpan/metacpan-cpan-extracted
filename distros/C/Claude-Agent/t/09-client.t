#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Claude::Agent::Client;
use Claude::Agent::Options;

# Test basic client creation
my $client = Claude::Agent::Client->new();
isa_ok($client, 'Claude::Agent::Client');

# Test client has default options
isa_ok($client->options, 'Claude::Agent::Options', 'client has default options');

# Test is_connected - initial state
ok(!$client->is_connected, 'client not connected initially');

# Test session_id before connect
is($client->session_id, undef, 'session_id is undef before connect');

# Test with custom options
my $options = Claude::Agent::Options->new(
    allowed_tools   => ['Read', 'Glob', 'Grep'],
    permission_mode => 'bypassPermissions',
);

$client = Claude::Agent::Client->new(options => $options);
is_deeply($client->options->allowed_tools, ['Read', 'Glob', 'Grep'], 'custom options preserved');
is($client->options->permission_mode, 'bypassPermissions', 'custom permission_mode preserved');

# Test connect requires not already connected
# We can't actually connect without the CLI, but we can test the validation
$client = Claude::Agent::Client->new();

# Test disconnect on unconnected client (should be safe)
eval { $client->disconnect };
ok(!$@, 'disconnect on unconnected client does not die');
ok(!$client->is_connected, 'still not connected after disconnect');

# Test send requires connection
eval { $client->send('test message') };
like($@, qr/Not connected/, 'send requires connection');

# Test receive requires connection
eval { $client->receive };
like($@, qr/Not connected/, 'receive requires connection');

# Test interrupt on unconnected client (should be safe)
eval { $client->interrupt };
ok(!$@, 'interrupt on unconnected client does not die');

# Test resume requires not already connected
# Simulate connected state to test validation
# Note: We're testing the interface, not actual functionality

# Test receive_until_result placeholder
# This method collects messages until a Result is received
# Without actual CLI, we can only test the method exists
can_ok($client, 'receive_until_result');
can_ok($client, 'receive_async');
can_ok($client, 'resume');

# Test documentation example pattern (without actual CLI)
# This validates the API matches the documented usage
my $example_client = Claude::Agent::Client->new(
    options => Claude::Agent::Options->new(
        allowed_tools   => ['Read', 'Glob', 'Grep', 'Edit'],
        permission_mode => 'acceptEdits',
    ),
);

# Verify the client is ready for the documented usage pattern:
# 1. $client->connect($prompt)
# 2. while (my $msg = $client->receive) { ... }
# 3. $client->send($follow_up)
# 4. $client->disconnect

can_ok($example_client, 'connect');
can_ok($example_client, 'receive');
can_ok($example_client, 'send');
can_ok($example_client, 'disconnect');
can_ok($example_client, 'is_connected');
can_ok($example_client, 'session_id');

# Test that options are accessible
is(
    $example_client->options->permission_mode,
    'acceptEdits',
    'client options are accessible'
);

# Test error types
subtest 'Client error handling' => sub {
    my $c = Claude::Agent::Client->new();

    # Test error message for send on disconnected client
    eval { $c->send('test') };
    my $err = $@;
    ok($err, 'send on disconnected throws');
    like($err, qr/Not connected/, 'send error mentions connection');

    # Test error message for receive on disconnected client
    eval { $c->receive };
    $err = $@;
    ok($err, 'receive on disconnected throws');
    like($err, qr/Not connected/, 'receive error mentions connection');

    # Test receive_async on disconnected client
    eval { $c->receive_async };
    $err = $@;
    ok($err, 'receive_async on disconnected throws');
    like($err, qr/Not connected/, 'receive_async error mentions connection');
};

# Test connect/disconnect state management
subtest 'Client state management' => sub {
    my $c = Claude::Agent::Client->new();

    ok(!$c->is_connected, 'new client not connected');
    is($c->session_id, undef, 'new client has no session_id');

    # Multiple disconnects are safe
    $c->disconnect;
    ok(!$c->is_connected, 'still not connected after disconnect');
    $c->disconnect;
    ok(!$c->is_connected, 'still not connected after second disconnect');
};

# Test that resume requires not being connected
subtest 'Resume requires not connected' => sub {
    my $c = Claude::Agent::Client->new();

    # Can't test actual resume without CLI, but can verify method exists
    can_ok($c, 'resume');
};

done_testing();
