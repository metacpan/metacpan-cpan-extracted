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

# 0.14: one process per session, driven through the Query test seam
subtest 'Client drives one Query' => sub {
    require JSON::PP;
    require IO::Async::Loop;
    my $json = JSON::PP->new;
    my @out;
    my $closed = 0;
    my $loop = IO::Async::Loop->new;
    my $c = Claude::Agent::Client->new(
        loop       => $loop,
        options    => Claude::Agent::Options->new(allowed_tools => ['Read']),
        query_args => { spawn => 0, writer => sub { push @out, $_[1] }, closer => sub { $closed++ } },
    );
    $c->connect('first prompt');
    ok($c->is_connected, 'connected');
    my $query = $c->query;
    isa_ok($query, 'Claude::Agent::Query');
    ok($query->persistent, 'the query is persistent');
    is($out[0]{request}{subtype}, 'initialize', 'initialize written');
    $query->feed_line($json->encode({ type => 'control_response', response => { subtype => 'success', request_id => $out[0]{request_id}, response => { commands => [] } } }));
    is($out[1]{message}{content}, 'first prompt', 'the prompt follows the initialize response');
    is($closed, 0, 'stdin stays open');
    $query->feed_line($json->encode({ type => 'system', subtype => 'init', session_id => 'sess-1' }));
    $query->feed_line($json->encode({ type => 'result', subtype => 'success', result => 'one' }));
    my @turn = $c->receive_until_result;
    is(scalar @turn, 2, 'two messages in the first turn');
    is($c->session_id, 'sess-1', 'session id captured');
    is($closed, 0, 'stdin still open after the result');

    $c->send('second prompt');
    is($c->query, $query, 'send did not spawn a new query');
    is_deeply($out[-1], { type => 'user', session_id => 'default', message => { role => 'user', content => 'second prompt' }, parent_tool_use_id => undef }, 'the follow-up is a user message');
    $c->send('third', session_id => 'sess-1');
    is($out[-1]{session_id}, 'sess-1', 'an explicit session id is used');

    my $f = $c->set_permission_mode_async('acceptEdits');
    is($out[-1]{request}{subtype}, 'set_permission_mode', 'set_permission_mode delegates');
    $query->feed_line($json->encode({ type => 'control_response', response => { subtype => 'success', request_id => $out[-1]{request_id}, response => {} } }));
    ok($f->is_done, 'and resolves');
    is_deeply($c->server_info, { commands => [] }, 'server_info delegates');

    $c->disconnect;
    ok(!$c->is_connected, 'disconnected');
    is($closed, 1, 'disconnect closed stdin');
    ok(!defined $c->query, 'the query is gone');
    ok(!defined $c->interrupt, 'interrupt after disconnect returns undef');
    ok($c->interrupt_async->is_failed, 'interrupt_async after disconnect fails');

    $c->connect;
    ok($c->is_connected, 'connect without a prompt');
    is($out[-1]{request}{subtype}, 'initialize', 'a fresh initialize');
    $c->disconnect;

    $c->resume('sess-1');
    is($c->session_id, 'sess-1', 'resume sets the session id');
    is($c->query->options->resume, 'sess-1', 'resume option set on the new query');
    ok(!$c->query->options->has_fork_session, 'resume does not fork');
    is_deeply($c->query->options->allowed_tools, ['Read'], 'resume keeps the other options');
    eval { $c->resume('sess-2') };
    like($@, qr/Already connected/, 'resume while connected dies');
    $c->disconnect;
    $c->fork('sess-1', 'again');
    ok($c->query->options->fork_session, 'fork sets fork_session');
    $c->disconnect;
};

done_testing();
