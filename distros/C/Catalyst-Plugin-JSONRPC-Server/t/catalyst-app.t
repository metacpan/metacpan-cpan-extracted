use v5.36;
use Test::More;
use lib 't/lib';
use HTTP::Request::Common qw/POST/;
use JSON::MaybeXS qw/decode_json/;

use Catalyst::Test 'TestApp';

# Single call
{
    my $req = POST '/rpc',
        'Content-Type' => 'application/json',
        Content        => '{"jsonrpc":"2.0","method":"add","params":{"a":3,"b":4},"id":1}';
    my $res = request($req);
    ok( $res->is_success, 'HTTP 200 for a call' );
    is( $res->header('Content-Type'), 'application/json', 'json content type' );
    is_deeply( decode_json( $res->content ),
        { jsonrpc => '2.0', result => 7, id => 1 },
        'add result over HTTP' );
}

# Batch
{
    my $req = POST '/rpc',
        'Content-Type' => 'application/json',
        Content        => '[{"jsonrpc":"2.0","method":"echo","params":["a"],"id":1},{"jsonrpc":"2.0","method":"nope","id":2}]';
    my $res = request($req);
    ok( $res->is_success, 'HTTP 200 for a batch' );
    is_deeply( decode_json( $res->content ),
        [
            { jsonrpc => '2.0', result => ['a'], id => 1 },
            { jsonrpc => '2.0', error => { code => -32601, message => 'Method not found' }, id => 2 },
        ],
        'batch over HTTP' );
}

# Notification -> 204, empty body
{
    my $req = POST '/rpc',
        'Content-Type' => 'application/json',
        Content        => '{"jsonrpc":"2.0","method":"echo","params":[1]}';
    my $res = request($req);
    is( $res->code, 204, 'notification yields HTTP 204' );
    is( $res->content, '', 'empty body' );
}

done_testing;
