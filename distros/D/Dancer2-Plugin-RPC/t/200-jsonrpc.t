#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyJSONRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "JSONRPC methodList(plugin => 'jsonrpc')" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            {
                jsonrpc => '2.0',
                method  => 'method.list',
                id      => 42,
                params  => {plugin => 'jsonrpc'}
            }
        ),
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content)->{result},
        {
            '/endpoint' => [qw/
                method.list
                ping
                version
            /]
        },
        "method.list(plugin => 'jsonrpc')"
    ) or diag(explain($response));
};

subtest "JSONRPC methodList(plugin => 'jsonrpc') /wrong_endpoint" => sub {
    my $request = HTTP::Request->new(
        POST => '/wrong_endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
                {
                    jsonrpc => '2.0',
                    method  => 'method.list',
                    id      => 42,
                    params  => {plugin => 'jsonrpc'}
                }
            ),
    );

    my $response = $tester->request($request);
    is($response->status_line, "404 Not Found", "Not found...");
};

subtest "JSONRPC methodList(plugin => 'jsonrpc') /wrong_endpoint" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            {
                jsonrpc => '2.0',
                method  => 'methodList',
                id      => 42,
                params  => {plugin => 'any'}
            }
        ),
    );

    my $response = $tester->request($request);
    is($response->status_line, "200 OK", "Transport OK");
    is_deeply(
        from_json($response->decoded_content)->{error},
        {
            code    => -32601,
            message => "Method 'methodList' not found at '/endpoint' (skipped)"
        },
        "Unknown jsonrpc-method"
    );
};

subtest "JSONRPC wrong content-type => 404" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [ 'Content-Type' => 'text/xml', ],
        encode_json(
            {
                jsonrpc => '2.0',
                method  => 'method.list',
                id      => 42,
                params  => {plugin => 'jsonrpc'}
            }
        ),
    );
    my $response = $tester->request($request);
    is($response->status_line, "404 Not Found", "Check content-type jsonrpc")
        or diag(explain($response));
};

abeltje_done_testing();

BEGIN {
    package MyJSONRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::JSONRPC;

    BEGIN { set(log => 'error') }
    jsonrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
    };

    1;
}
