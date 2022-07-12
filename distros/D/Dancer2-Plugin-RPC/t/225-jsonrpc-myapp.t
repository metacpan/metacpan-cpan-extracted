#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyAllRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "JSONRPC ping" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            {
                jsonrpc => '2.0',
                method  => 'ping',
                id      => 42,
            }
        ),
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content)->{result},
        'pong',
        "ping"
    ) or diag(explain($response));
};

subtest "JSONRPC version" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            {
                jsonrpc => '2.0',
                method  => 'version',
                id      => 42,
            }
        ),
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content)->{result},
        { software => $MyAppCode::VERSION },
        "version"
    ) or diag(explain($response));
};

subtest "JSONRPC method.list()" => sub {
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
            }
        ),
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content)->{result},
        {
            'jsonrpc' => {'/endpoint' => ['method.list', 'ping', 'version']},
            'restrpc' => {'/endpoint' => ['method_list', 'ping', 'version']},
            'xmlrpc'  => {'/endpoint' => ['methodList',  'ping', 'version']}
        },
        "method.list()"
    ) or diag(explain($response));
};

subtest "JSONRPC method.list(plugin => 'jsonrpc')" => sub {
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
            '/endpoint' => [ qw/ method.list ping version / ]
        },
        "method.list(plugin => 'jsonrpc')"
    ) or diag(explain($response));
};

abeltje_done_testing();

BEGIN {
    package MyAllRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::XMLRPC;
    use Dancer2::Plugin::RPC::RESTRPC;
    use Dancer2::Plugin::RPC::JSONRPC;

    BEGIN { set(logger => 'Null') }
    xmlrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    restrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    jsonrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
    };
    1;
}
