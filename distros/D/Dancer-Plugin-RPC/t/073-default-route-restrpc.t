#! perl -I. -w
use t::Test::abeltje;

use Dancer qw/!pass !warning/;
use Dancer::RPCPlugin::DefaultRoute;
use Dancer::Plugin::RPC::RESTRPC;
use Dancer::Test;

my $ENDPOINT         = '/system/code_wrapper';
my $UNKNOWN_ENDPOINT = '/system/code_wrapper/undefined_endpoint';


use MyTest::API;
use MyTest::Client;

my $client = MyTest::Client->new(ping_value => 'pong');
my $dispatch = {
    'MyTest::API' => MyTest::API->new(test_client => $client),
};
my $config = {
    config       => 'config',
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
    route_doesnt_exist([POST => $url], "$prefix: Unknown route $url");
    is($response->{status}, 404, "$prefix: unknown endpoint returns 404 status");

    $response = _post($ENDPOINT, { method => 'system.pong'} );
    $url = $ENDPOINT.'/system_pong';
    route_doesnt_exist([POST => $url], "$prefix: Unknown route $url");
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
    route_exists([POST => $url], "$prefix: Known route: $url");
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
    route_exists([POST => $url], "$prefix: Known route $url");

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

done_testing();

sub _post {
    my ($endpoint, $body) = @_;
    my $url = sprintf("%s/%s", $endpoint, defined $body ? $body->{method} : 'system_ping');
    my $response = dancer_response(
        POST => $url,
        {
            content_type => 'application/json',
            body         => to_json({}),
        }
    );
    $response->{content} = from_json(delete $response->{content})
        if $response->{status} == 200;

    return $response;
}

