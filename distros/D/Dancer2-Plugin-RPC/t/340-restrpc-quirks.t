#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use Dancer2::RPCPlugin::ErrorResponse;
use HTTP::Request;
use JSON;

my $app = MyRESTRPCApp->to_app();
my $tester = Plack::Test->create($app);

subtest "RESTRPC return ErrorResponse" => sub {
    our $CodeWrapped = sub {
        return error_response(error_code => 42, error_message => "It went wrong :(");
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint/ping',
        [
            'Content-type' => 'application/json',
            'Accept'       => 'application/json',
        ]
    );

    my $response = $tester->request($request);
    my $response_error = decode_json($response->content)->{error};
    is_deeply(
        $response_error,
        {
            code => 42,
            message => 'It went wrong :(',
        },
        "::ErrorResponse was processed"
    ) or diag(explain($response));
};

subtest "RESTRPC codewrapper returns an object" => sub {
    our $CodeWrapped = sub {
        return bless {data => 42}, 'AnyClass';
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint/ping',
        [
            'Content-type' => 'application/json',
            'Accept'       => 'application/json',
        ]
    );

    my $response = $tester->request($request);
    my $response_data = decode_json($response->content);
    is_deeply(
        $response_data,
        { data => 42 },
        "flatten_data() was called"
    ) or diag(explain($response));
};

abeltje_done_testing();

BEGIN {
    package MyRESTRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::RESTRPC;

    BEGIN {
        set(log => 'error');
    }
    restrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        code_wrapper => sub { $::CodeWrapped->() },
    };

    1;
}
