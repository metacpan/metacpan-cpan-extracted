#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyRESTRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "RESTRPC methodList(plugin => 'restrpc')" => sub {
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

subtest "RESTRPC ping(plugin => 'restrpc')" => sub {
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

subtest "RESTRPC methodList(plugin => 'restrpc') /wrong_endpoint" => sub {
    my $request = HTTP::Request->new(
        POST => '/wrong_endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json( {plugin => 'restrpc'} ),
    );

    my $response = $tester->request($request);
    is($response->status_line, "404 Not Found", "Not found...")
        or diag("Response: ", explain($response));
};

subtest "RESTRPC wrong content-type => 404" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint/method_list',
        [ 'Content-Type' => 'text/xml', ],
        encode_json( {plugin => 'jsonrpc'} ),
    );
    my $response = $tester->request($request);
    is($response->status_line, "404 Not Found", "Check content-type jsonrpc")
        or diag(explain($response));
};

abeltje_done_testing();

BEGIN {
    package MyRESTRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::RESTRPC;

    BEGIN { set(log => 'error') }
    restrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
    };

    1;
}
