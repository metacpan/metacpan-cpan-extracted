#! perl -I. -w
use t::Test::abeltje;

use Plack::Test;

use Dancer2::RPCPlugin::ErrorResponse;
use HTTP::Request;
use JSON;

my $app = MyJSONRPCApp->to_app();
my $tester = Plack::Test->create($app);

{
    note("JSONRPC return ErrorResponse");
    our $CodeWrapped = sub {
        return error_response(error_code => 42, error_message => "It went wrong :(");
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint',
        [
            'Content-type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json({ jsonrpc => '2.0', id => 42, method => 'ping'})
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
}

{
    note("JSONRPC codewrapper returns an object");
    our $CodeWrapped = sub {
        return bless {dummy => 42}, 'AnyClass';
    };
    my $request = HTTP::Request->new(
        POST => 'endpoint',
        [
            'Content-type' => 'application/json',
            'Accept'       => 'application/json',
        ],
        encode_json({jsonrpc => '2.0', method => 'ping', id => '42'})
    );

    my $response = $tester->request($request);
    my $response_result = decode_json($response->content)->{result};
    is_deeply(
        $response_result,
        { dummy => 42 },
        "flatten_data() was used"
    ) or diag(explain($response));
}

abeltje_done_testing();

BEGIN {
    package MyJSONRPCApp;
    use lib 'ex/';
    use Dancer2;
    use Dancer2::Plugin::RPC::JSONRPC;

    BEGIN {
        set(log => 'error');
    }
    jsonrpc '/endpoint' => {
        publish   => 'pod',
        arguments => [qw/ MyAppCode /],
        code_wrapper => sub { $::CodeWrapped->() },
    };

    1;
}
