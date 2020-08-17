#! perl -I. -w
use t::Test::abeltje;
BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'test';
    $ENV{DANCER_APPDIR}      = '.';
}


use Dancer qw/:syntax !pass !warning/;
use Dancer::Test;

use Dancer::RPCPlugin::DefaultRoute;
use Dancer::Plugin::RPC::XMLRPC;
use RPC::XML;
use RPC::XML::ParserFactory;
$RPC::XML::ENCODING = 'utf-8';

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
        'RPC::XMLRPC' => {
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

xmlrpc $ENDPOINT => $config;

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

    $response = _post($UNKNOWN_ENDPOINT);
    route_doesnt_exist([POST => $UNKNOWN_ENDPOINT], "$prefix: Unknown route $UNKNOWN_ENDPOINT");
    is($response->{status}, 404, "$prefix: unknown endpoint returns 404 status");

    $response = _post($ENDPOINT, { method => 'system.pong'} );
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
        [ { result => 'pong'} ],
        "$prefix: Known route returns result"
    );

    route_exists([POST => $UNKNOWN_ENDPOINT], "$prefix: Known route: $UNKNOWN_ENDPOINT");
    $response = _post($UNKNOWN_ENDPOINT);
    is($response->{status}, 200, "$prefix: Unknown route returns 200 status");

    is_deeply(
        $response->{content},
        {
            faultCode   => -32601,
            faultString => "Method 'system_ping' not found",
        },
        "$prefix: Unknown route returns -32601 error"
    ) or diag(explain($response));

    route_exists([POST => $UNKNOWN_ENDPOINT], "$prefix: Known route $UNKNOWN_ENDPOINT");

    $response = _post($ENDPOINT, { method => 'system.pong'} );
    is($response->{status}, 200, "$prefix: Unknown method returns 200 status");
    is($response->{content}{faultCode}, -32601, "$prefix: Unknown method returns -32601 code");
    like(
        $response->{content}{faultString},
        qr/Method '.*' not found/,
        sprintf("RPC::XMLRPC: %s - %s", $prefix, $response->{content}{faultCode}),
    );
}

done_testing();

sub _post {
    my ($endpoint, $body) = @_;
    my $parser = RPC::XML::ParserFactory->new();

    $body //= { method => 'system_ping' };
    my $request = RPC::XML::request->new($body->{method})->as_string();
    my $response = dancer_response(
        POST => $endpoint,
        {
            content_type => 'text/xml',
            body         => $request,
        },
    );
    if ($response->{status} == 200) {
        $response->{content} = $parser->parse($response->{content})->value->value;
    }
    return $response;
}

