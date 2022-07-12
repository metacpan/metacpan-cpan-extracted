#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyJSONRPCApp->to_app();
my $tester = Plack::Test->create($app);

{
    note("JSONRPC multirequest");
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            [
                {
                    jsonrpc => '2.0',
                    method  => 'ping',
                    id      => 42,
                    params  => {plugin => 'jsonrpc'}
                },
                {
                    jsonrpc => '2.0',
                    method  => 'version',
                    id      => 43,
                    params  => undef,
                },
            ]
        ),
    );
    my $response = $tester->request($request);
    my $response_data = decode_json($response->content);
    is_deeply(
        $response_data,
        [
            {
                jsonrpc => '2.0',
                id      => 42,
                result  => 'pong',
            },
            {
                jsonrpc => '2.0',
                id      => 43,
                result  => {software => $MyAppCode::VERSION}
            },
        ],
        "multi-request (special jsonrpc feature)"
    ) or diag(explain($response));
}

{
    note("JSONRPC fire&forget");
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json( {jsonrpc => '2.0', method => 'ping'} )
    );

    my $response = $tester->request($request);
    is($response->status_line, "202 Accepted", "Accepted")
        or diag(explain($response));
}

{
    note("JSONRPC fire&forget error");
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json( {jsonrpc => '2.0', method => 'pong'} )
    );

    my $response = $tester->request($request);
    is($response->status_line, "202 Accepted", "Accepted")
        or diag(explain($response));
}

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
