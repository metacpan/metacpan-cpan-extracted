#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use lib 't/lib';
use TestUtil qw(ROOT free_port wait_port start_bg stop_bg mock_stdio_cmd);
use App::MCP::CLI::Client qw(content_text);

# stdio
{
    my $c = App::MCP::CLI::Client->new(cmd => mock_stdio_cmd(), timeout => 10);
    $c->connect;
    is($c->server_info->{name}, 'mock-stdio', 'handshake completed');

    my $tools = $c->list_tools;
    is(scalar @$tools, 9, 'tools/list follows nextCursor pagination');

    my $r = $c->call_tool('add_numbers', { a => 2, b => 3 });
    is(content_text($r->{result}), 'sum=5', 'tool call works despite log lines and notifications');

    like(content_text($c->call_tool('init_state')->{result}), qr/initialized=1/,
         'notifications/initialized is sent after initialize');

    $r = $c->call_tool('fail');
    ok($r->{result}{isError}, 'isError is visible to the caller');
    is(content_text($r->{result}), 'boom', 'error text is rendered');

    like(content_text($c->call_tool('img')->{result}),
         qr{^\[image: image/png, 4 bytes base64, not displayed\]$},
         'image blocks become a placeholder');

    $r = $c->call_tool('nope');
    is($r->{error}{code}, -32602, 'a JSON-RPC error is returned as an error response');

    $c->close;
    $c->close;    # must be safe to repeat
    pass('close is idempotent');
}

{   # timeouts
    my $c = App::MCP::CLI::Client->new(cmd => mock_stdio_cmd(), timeout => 1);
    $c->connect;
    my $t0 = time;
    eval { $c->call_tool('slow') };
    like($@, qr/Timed out waiting for/, 'a silent server causes a timeout, not a hang');
    cmp_ok(time - $t0, '<', 5, 'the timeout fires promptly');
    $c->close;
}

{   # server exits without answering
    my $c = App::MCP::CLI::Client->new(cmd => mock_stdio_cmd(), timeout => 10);
    $c->connect;
    eval { $c->call_tool('die') };
    like($@, qr/closed the connection/, 'a server that exits gives a clear error');
    $c->close;
}

{   # env applies to the child only
    my $c = App::MCP::CLI::Client->new(cmd => mock_stdio_cmd(), env => { MOCK_VAR => 'hello' }, timeout => 10);
    $c->connect;
    is(content_text($c->call_tool('get_env')->{result}), 'MOCK_VAR=hello', 'env reaches the server');
    $c->close;
    ok(!exists $ENV{MOCK_VAR}, 'env did not leak into this process');
}

{
    my $c = App::MCP::CLI::Client->new(cmd => ['/nonexistent/mcp-server-xyz']);
    eval { $c->connect };
    like($@, qr/Failed to start MCP server/, 'an unstartable command is a clear error');
}

# SSE
{
    my $port = free_port();
    my $pid  = start_bg(cmd => [ $^X, ROOT . '/t/lib/mock_sse.pl', $port ]);
    ok(wait_port($port), 'mock SSE server is up') or BAIL_OUT('mock SSE server did not start');

    my $c = App::MCP::CLI::Client->new(url => "http://127.0.0.1:$port/sse", timeout => 10);
    $c->connect;
    ok($c->is_sse, 'SSE transport selected');
    is($c->server_info->{name}, 'mock-sse', 'handshake over SSE (response arrives on the stream)');
    is($c->{post_url}, "http://127.0.0.1:$port/messages?session=abc", 'relative endpoint is resolved');

    my $tools = $c->list_tools;
    is($tools->[0]{name}, 'add_numbers', 'tools/list over SSE');
    is(content_text($c->call_tool('add_numbers', { a => 4, b => 5 })->{result}), 'sum=9',
       'tools/call over SSE, split chunked events reassembled');
    $c->close;
    stop_bg($pid);

    eval { App::MCP::CLI::Client->new(url => "http://127.0.0.1:$port/sse", timeout => 2)->connect };
    like($@, qr/Cannot connect/, 'an unreachable SSE server is a clear error');
}

# The bundled example answers inside the POST body and closes its stream.
SKIP: {
    skip 'HTTP::Daemon not installed', 4 unless eval { require HTTP::Daemon; 1 };

    my $port = free_port();
    my $pid  = start_bg(cmd => [ $^X, ROOT . '/examples/sse_server.pl' ], env => { SSE_PORT => $port });
    ok(wait_port($port), 'example SSE stub is up') or BAIL_OUT('example SSE server did not start');

    my $c = App::MCP::CLI::Client->new(url => "http://127.0.0.1:$port/sse", timeout => 10);
    $c->connect;
    my $tools = $c->list_tools;
    is($tools->[0]{name}, 'get_mock_weather', 'example stub: tools/list');
    like(content_text($c->call_tool('get_mock_weather', { location => 'London' })->{result}),
         qr/\S/, 'example stub: tools/call');
    $c->close;
    stop_bg($pid);
    pass('example stub stopped');
}

done_testing;
