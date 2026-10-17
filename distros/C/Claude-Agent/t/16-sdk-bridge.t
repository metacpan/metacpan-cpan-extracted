#!perl
use 5.020;
use strict;
use warnings;
use Test::More;
use Future;
use IO::Async::Loop;
use JSON::PP ();

use Claude::Agent qw(tool create_sdk_mcp_server);
use Claude::Agent::MCP::SDKBridge;

my $loop = IO::Async::Loop->new;

my $add = tool('add', 'Add two numbers',
    { type => 'object', properties => { a => { type => 'number' }, b => { type => 'number' } }, required => ['a', 'b'] },
    sub { my ($args) = @_; return { content => [{ type => 'text', text => ($args->{a} // 0) + ($args->{b} // 0) }] } });
my $slow = tool('slow', 'Never finishes', { type => 'object' }, sub { my ($args, $l) = @_; return $l->new_future });
my $later = tool('later', 'Finishes on the loop', { type => 'object' },
    sub { my ($args, $l) = @_; return $l->delay_future(after => 0.01)->then(sub { Future->done({ content => [{ type => 'text', text => 'later' }] }) }) });
my $dies = tool('dies', 'Dies', { type => 'object' }, sub { die "kaboom\n" });
my $bad = tool('bad', 'Returns the wrong shape', { type => 'object' }, sub { return { text => 'oops' } });
my $err = tool('err', 'Reports an error', { type => 'object' }, sub { return { content => [{ type => 'text', text => 'no' }], is_error => 1 } });

my $server = create_sdk_mcp_server(name => 'utilities', version => '2.1.0', tools => [$add, $slow, $later, $dies, $bad, $err]);
my $bridge = Claude::Agent::MCP::SDKBridge->new(server => $server, loop => $loop, tool_timeout => 0.05);

sub rpc {
    my ($id, $method, $params) = @_;
    my $f = $bridge->handle({ jsonrpc => '2.0', id => $id, method => $method, ($params ? (params => $params) : ()) });
    $loop->loop_once(0.01) until $f->is_ready;
    return $f->get;
}

subtest 'initialize' => sub {
    my $reply = rpc(1, 'initialize', { protocolVersion => '2025-06-18', capabilities => {}, clientInfo => { name => 'claude' } });
    is($reply->{jsonrpc}, '2.0', 'jsonrpc');
    is($reply->{id}, 1, 'id echoed');
    is($reply->{result}{protocolVersion}, '2025-06-18', 'protocol version echoed');
    is_deeply($reply->{result}{capabilities}, { tools => {} }, 'tools capability');
    is_deeply($reply->{result}{serverInfo}, { name => 'utilities', version => '2.1.0' }, 'serverInfo');
    is(rpc(2, 'initialize', {})->{result}{protocolVersion}, '2024-11-05', 'default protocol version');
    is(rpc(3, 'initialize', {})->{id}, 3, 'a repeated initialize is answered');
};

subtest 'notifications and ping' => sub {
    my $f = $bridge->handle({ jsonrpc => '2.0', method => 'notifications/initialized' });
    ok($f->is_done, 'notification Future is done');
    ok(!defined $f->get, 'notification gets no reply');
    ok(!defined $bridge->handle({ jsonrpc => '2.0', id => 9, result => {} })->get, 'a response with no method gets no reply');
    is_deeply(rpc(4, 'ping'), { jsonrpc => '2.0', id => 4, result => {} }, 'ping');
};

subtest 'tools/list' => sub {
    my $reply = rpc(5, 'tools/list');
    is(scalar @{$reply->{result}{tools}}, 6, 'six tools');
    is($reply->{result}{tools}[0]{name}, 'add', 'first tool name');
    is($reply->{result}{tools}[0]{inputSchema}{type}, 'object', 'inputSchema');
    is($reply->{result}{tools}[0]{description}, 'Add two numbers', 'description');
};

subtest 'tools/call' => sub {
    my $reply = rpc(6, 'tools/call', { name => 'add', arguments => { a => 2, b => 3 } });
    is($reply->{id}, 6, 'id');
    is($reply->{result}{content}[0]{text}, 5, 'sync result');
    like(JSON::PP->new->canonical->encode($reply->{result}{content}[0]), qr/"text":"5"/, 'a numeric text is sent as a string');
    ok(ref $reply->{result}{isError} && !${$reply->{result}{isError}}, 'isError is JSON false');

    $reply = rpc(7, 'tools/call', { name => 'later', arguments => {} });
    is($reply->{result}{content}[0]{text}, 'later', 'async result awaited on the loop');

    $reply = rpc(8, 'tools/call', { name => 'dies', arguments => {} });
    ok(${$reply->{result}{isError}}, 'a dying handler is an error result');
    like($reply->{result}{content}[0]{text}, qr/Error executing tool: dies/, 'error names the tool, not the exception');

    $reply = rpc(9, 'tools/call', { name => 'bad', arguments => {} });
    ok(${$reply->{result}{isError}}, 'a malformed result is an error result');
    like($reply->{result}{content}[0]{text}, qr/Invalid handler result format/, 'malformed message');

    $reply = rpc(10, 'tools/call', { name => 'err', arguments => {} });
    ok(${$reply->{result}{isError}}, 'is_error passes through');
    is($reply->{result}{content}[0]{text}, 'no', 'error content passes through');

    $reply = rpc(11, 'tools/call', { name => 'slow', arguments => {} });
    ok(${$reply->{result}{isError}}, 'a slow tool times out');
    like($reply->{result}{content}[0]{text}, qr/timed out after 0\.05s/, 'timeout message');

    $reply = rpc(12, 'tools/call', { name => 'nope', arguments => {} });
    is($reply->{error}{code}, -32601, 'unknown tool code');
    like($reply->{error}{message}, qr/Unknown tool: nope/, 'unknown tool message');

    $reply = rpc(13, 'tools/call', { name => 'add' });
    is($reply->{result}{content}[0]{text}, 0, 'missing arguments are an empty hash');
};

subtest 'errors' => sub {
    my $reply = rpc(14, 'resources/list');
    is($reply->{error}{code}, -32601, 'unknown method code');
    is($reply->{error}{message}, 'Method not found: resources/list', 'unknown method message');
    my $bad = $bridge->handle('not a hash')->get;
    is($bad->{error}{code}, -32600, 'a non-hash message is an invalid request');
};

subtest 'timeout_seconds' => sub {
    my $plain = Claude::Agent::MCP::SDKBridge->new(server => $server);
    local $ENV{CLAUDE_AGENT_TOOL_TIMEOUT};
    delete $ENV{CLAUDE_AGENT_TOOL_TIMEOUT};
    is($plain->timeout_seconds, 60, 'default 60');
    $ENV{CLAUDE_AGENT_TOOL_TIMEOUT} = 900;
    is($plain->timeout_seconds, 300, 'capped at 300');
    $ENV{CLAUDE_AGENT_TOOL_TIMEOUT} = 'abc';
    is($plain->timeout_seconds, 60, 'non-numeric falls back');
    $ENV{CLAUDE_AGENT_TOOL_TIMEOUT} = 15;
    is($plain->timeout_seconds, 15, 'env value used');
    is($bridge->timeout_seconds, 0.05, 'tool_timeout overrides env');
    my $f = $plain->handle({ jsonrpc => '2.0', id => 1, method => 'tools/call', params => { name => 'add', arguments => { a => 1, b => 1 } } });
    is($f->get->{result}{content}[0]{text}, 2, 'a sync tool needs no loop');
};

done_testing();
