use v5.36;
use Test::More;
use lib 't/lib';
use HTTP::Request::Common qw/POST/;
use JSON::MaybeXS qw/decode_json/;

use Catalyst::Test 'TestApp';

sub call_mcp ($json) {
    my $req = POST '/mcp',
        'Content-Type' => 'application/json',
        Content        => $json;
    return request($req);
}

# initialize: 200 + negotiated version + capabilities for both kinds
{
    my $res = call_mcp(
        '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18"},"id":1}'
    );
    ok( $res->is_success, 'HTTP 200 for initialize' );
    my $body = decode_json( $res->content );
    is( $body->{result}{protocolVersion}, '2025-06-18', 'version negotiated' );
    is_deeply(
        $body->{result}{capabilities},
        { tools => {}, resources => {} },
        'capabilities advertise both registered kinds'
    );
}

# tools/call happy path over HTTP
{
    my $res = call_mcp(
        '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"echo","arguments":{"msg":"hi"}},"id":2}'
    );
    ok( $res->is_success, 'tools/call happy path is HTTP 200' );
    is_deeply(
        decode_json( $res->content )->{result},
        { content => [ { type => 'text', text => 'echo: hi' } ] },
        'tools/call result over HTTP'
    );
}

# tools/call execution error -> result with isError (still HTTP 200, no error)
{
    my $res = call_mcp(
        '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"echo","arguments":{"fail":1}},"id":3}'
    );
    my $body = decode_json( $res->content );
    ok( !$body->{error}, 'execution failure is not a JSON-RPC error' );
    is( $body->{result}{isError}, 1, 'execution failure rides in isError' );
}

# tools/call unknown tool -> -32602 protocol error
{
    my $res = call_mcp(
        '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"ghost"},"id":4}'
    );
    is( $res->code, 200, 'unknown tool is still HTTP 200 (JSON-RPC error envelope)' );
    is( decode_json( $res->content )->{error}{code}, -32602,
        'unknown tool is -32602' );
}

# resources/read not found -> -32002
{
    my $res = call_mcp(
        '{"jsonrpc":"2.0","method":"resources/read","params":{"uri":"mem://missing"},"id":5}'
    );
    is( $res->code, 200, 'resource-not-found is still HTTP 200 (JSON-RPC error envelope)' );
    is( decode_json( $res->content )->{error}{code}, -32002,
        'unknown resource is -32002' );
}

# notification (no id) -> HTTP 202 Accepted, empty body.
# MCP's Streamable HTTP transport requires 202 (not the generic JSON-RPC 204)
# for a POST that carries only responses/notifications.
{
    my $res = call_mcp('{"jsonrpc":"2.0","method":"notifications/initialized"}');
    is( $res->code, 202, 'notification yields HTTP 202 Accepted' );
    is( $res->content, '', 'empty body' );
}

done_testing;
