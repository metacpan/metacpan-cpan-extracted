#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use HTTP::Request;
use JSON;

my $app = MyRESTRPCAppCallbackFail->to_app();
my $tester = Plack::Test->create($app);

subtest "RESTRPC CodeWrapper" => sub {
    my $request = HTTP::Request->new(
        POST => '/endpoint/ping',
        [
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ],
    );
    my $response = $tester->request($request);
    my $response_data = decode_json($response->content)->{error};
    is_deeply(
        $response_data,
        {
            'code'    => 500,
            'message' => "Codewrapper die()s\n",
        },
        "CodeWrapper die()s"
    ) or diag(explain($response_data));
};

abeltje_done_testing();

BEGIN {
    package MyRESTRPCAppCallbackFail;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::RESTRPC;
    use Dancer2::RPCPlugin::CallbackResultFactory;

    BEGIN { set(log => 'error') }
    restrpc '/endpoint' => {
        publish      => 'pod',
        arguments    => [qw/ MyAppCode /],
        code_wrapper => sub {
            die "Codewrapper die()s\n";
        }
    };
    1;
}
