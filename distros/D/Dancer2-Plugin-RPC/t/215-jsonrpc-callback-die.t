#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyJSONRPCAppCallbackFail->to_app();
my $tester = Plack::Test->create($app);

subtest "JSONRPC Callback::Fail" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json(
            {
                jsonrpc => '2.0',
                id      => 42,
                method => 'ping',
                params => undef,
            }
        )
    );
    my $response = $tester->request($request);
    my $response_data = decode_json($response->content)->{error};
    is_deeply(
        $response_data,
        {
            'code'    => 500,
            'message' => "Callback die()s\n",
        },
        "CallbackFail"
    ) or diag(explain($response_data));
};

abeltje_done_testing();

BEGIN {
    package MyJSONRPCAppCallbackFail;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::JSONRPC;
    use Dancer2::RPCPlugin::CallbackResultFactory;

    BEGIN { set(log => 'error') }
    jsonrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        callback  => sub {
            die "Callback die()s\n";
        },
    };
    1;
}

