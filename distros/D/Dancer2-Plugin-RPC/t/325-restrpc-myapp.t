#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyAllRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "RESTRPC ping" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint/ping',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content),
        { RESULT => 'pong' },
        "simple-scalar-result becomes hashref with key RESPONSE"
    ) or diag(explain($response));
};

subtest "RESTRPC version" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint/version',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content),
        { software => $MyAppCode::VERSION },
        "version"
    ) or diag(explain($response));
};

subtest "RESTRPC method_list()" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint/method_list',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content),
        {
            'jsonrpc' => {'/endpoint' => ['method.list', 'ping', 'version']},
            'restrpc' => {'/endpoint' => ['method_list', 'ping', 'version']},
            'xmlrpc'  => {'/endpoint' => ['methodList',  'ping', 'version']}
        },
        "method_list()"
    ) or diag(explain($response));
};

subtest "RESTRPC method_list(plugin => 'restrpc')" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint/method_list',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            { plugin => 'restrpc'}
        ),
    );

    my $response = $tester->request($request);
    is_deeply(
        from_json($response->decoded_content),
        {
            '/endpoint' => [qw/
                method_list
                ping
                version
            /]
        },
        "method_list(plugin => 'restrpc')"
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
