#! perl -I. -w
use t::Test::abeltje;

use Dancer2 qw/!pass !warning/;
use Dancer2::RPCPlugin::DefaultRoute;
use Dancer2::Plugin::RPC::RESTRPC;
use Plack::Test;

my $ENDPOINT         = '/system/code_wrapper';
my $UNKNOWN_ENDPOINT = '/system/code_wrapper/undefined_endpoint';


use MyTest::API;
use MyTest::Client;

my $client = MyTest::Client->new(ping_value => 'pong');
my $dispatch = {
    'MyTest::API' => MyTest::API->new(test_client => $client),
};
my $config = {
    publish      => 'config',
    code_wrapper => sub {
        my ($code, $package, $method_name, @arguments) = @_;
        my $result = eval {
            my $instance = $dispatch->{$package};
            $instance->$code(@arguments);
        };
        if (my $error = $@) {
            error("[code_wrapper] ($package\->$method_name) ", $error);
            if (blessed($error) and $error->does('MyTest::Exception')) {
                # The plugin will send a proper error-response for the protocol
                die $error->as_string;
            }
            die $error;
        };
        return  [ $result ];
    },
};

set(
    logger => 'null',
    plugins => {
        'RPC::RESTRPC' => {
            $ENDPOINT => {
                'MyTest::API' => {
                    'system_ping'      => 'rpc_ping',
                    'system.exception' => 'rpc_fail',
                }
            }
        }
    }
);
set( clients => { test_client => { endpoint => 'somewhere' } });

restrpc $ENDPOINT => $config;

my $app = main->to_app();
my $tester = Plack::Test->create($app);

note("Without catchall unknown endpoint errors");
{
    my $prefix = "Without catchall";
    my $response = _post($ENDPOINT);
    is($response->{status}, 200, "$prefix: Known endpoint returns 200 status");
    is_deeply(
        $response->{content},
        [ { result => 'pong' } ],
        "$prefix: Known route returns result"
    );

    my $url = $UNKNOWN_ENDPOINT.'/system_ping';
    $response = _post($UNKNOWN_ENDPOINT);
    is($response->{status}, 404, "$prefix: unknown endpoint returns 404 status");

    $response = _post($ENDPOINT, { method => 'system.pong'} );
    $url = $ENDPOINT.'/system_pong';
    is($response->{status}, 404, "$prefix: Unknown method returns 404 status");
}

setup_default_route();

note('With catchall unknown endpoint errors');
{
    my $prefix = "With catchall";

    my $response = _post($ENDPOINT);
    is($response->{status}, 200, "$prefix: known endpoint returns 200 status");
    is_deeply(
        $response->{content},
        [ {result => 'pong'} ],
        "$prefix: Known route returns result"
    );

    my $url = $UNKNOWN_ENDPOINT.'/system_ping';
    $response = _post($UNKNOWN_ENDPOINT);
    is($response->{status}, 200, "$prefix: Unknown route returns 200 status");

    is_deeply(
        $response->{content}{error},
        {
            code    => -32601,
            message => "Method '$UNKNOWN_ENDPOINT/system_ping' not found",
        },
        "$prefix: Unknown route returns -32601 error"
    ) or diag(explain($response));

    $url = $UNKNOWN_ENDPOINT.'/system_pong';

    $response = _post($ENDPOINT, { method => 'system.pong'} );
    my $error = $response->{content}{error};
    is($response->{status}, 200, "$prefix: Unknown method returns 200 status");
    is($error->{code}, -32601, "$prefix: Unknown method returns -32601 code");
    like(
        $error->{message},
        qr/Method '.*' not found/,
        sprintf("RPC::RESTRPC: %s - %s", $prefix, $error->{message})
    );
}

abeltje_done_testing();

sub _post {
    my ($endpoint, $body) = @_;
    my $url = sprintf("%s/%s", $endpoint, defined $body ? $body->{method} : 'system_ping');
    my $request = HTTP::Request->new(
        POST => $url,
        [ content_type => 'application/json' ],
        to_json( {} ),
    );
    my $response = $tester->request($request);

    my $dancer_response = {
        content_type => $response->header('content_type'),
        status       => $response->code,
        content      => $response->content,
    };

    $dancer_response->{content} = from_json(delete $dancer_response->{content})
        if $dancer_response->{status} eq 200;

    return $dancer_response;
}

