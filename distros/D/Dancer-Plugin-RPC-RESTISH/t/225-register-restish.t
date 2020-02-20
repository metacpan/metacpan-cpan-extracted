#! perl -w
use strict;
use lib 't/lib';

use Test::More;

use Dancer qw/:syntax !pass/;

use Dancer::Plugin::RPC::RESTISH;
use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::ErrorResponse;

use Dancer::Test;

{
    note("default publish == 'config'");
    set(plugins => {
        'RPC::RESTISH' => {
            '/endpoint' => {
                'TestProject::SystemCalls' => {
                    'GET@ping'    => 'do_ping',
                    'GET@version' => 'do_version',
                },
            },
        }
    });
    set(encoding => 'utf-8');
    restish '/endpoint' => { };

    route_exists([GET => '/endpoint/ping'],    "GET /endpoint/ping registered");
    route_exists([GET => '/endpoint/version'], "GET /endpoint/version registered");

    my $response = dancer_response(
        GET => '/endpoint/ping',
    );

    my $ping = from_json('{"response": true}');
    if (JSON->VERSION >= 2.90) {
        my $t = 1;
        $ping->{response} = bless \$t, 'JSON::PP::Boolean';
    }

    is_deeply(
        from_json($response->{content}),
        $ping,
        "GET /endpoint/ping"
    ) or diag(explain($response));
}

{
    note("publish is code that returns the dispatch-table");
    restish '/endpoint2' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => dispatch_item(
                    code    => TestProject::SystemCalls->can('do_version'),
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub { return callback_success(); },
    };

    route_exists([GET => '/endpoint2/version'], "GET /endpoint2/version registered");

    my $response = dancer_response(
        GET => '/endpoint2/version',
    );

    is_deeply(
        from_json($response->{content}),
        { software_version => $TestProject::SystemCalls::VERSION },
        "GET /endpoint2/version"
    );
}

{
    note("callback fails");
    restish '/fail1' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => dispatch_item(
                    code    => TestProject::SystemCalls->can('do_version'),
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            return callback_fail(
                error_code    => -32601,
                error_message => "Force callback error",
            );
        },
    };

    route_exists([GET => '/fail1/version'], "GET /fail1/version registered");

    my $response = dancer_response(
        GET => '/fail1/version',
    );

    is($response->{status}, 403, "callback http-status 403") or diag(explain($response));

    my $result = $response->header('content-type') eq 'application/json'
        ? from_json($response->{content})
        : $response->{content};
    is_deeply(
        $result,
        {
            error_code    => -32601,
            error_message => "Force callback error",
            error_data    => { },
        },
        "GET /fail1/version (callback_fail)"
    ) or diag(explain($response));
}

{
    note("callback dies");
    restish '/fail2' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => dispatch_item(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            die "terrible death\n";
        },
    };

    route_exists([GET => '/fail2/version'], "/fail2/version registered");

    my $response = dancer_response(
        GET => '/fail2/version',
    );
    is($response->{status}, 500, "callback http-status 500") or diag(explain($response));

    my $result = $response->header('content-type') eq 'application/json'
        ? from_json($response->{content})
        : $response->{content};
    is_deeply(
        $result,
        {
            error_code    => -32500,
            error_message => "terrible death\n",
            error_data    => { },
        },
        "GET /endpoint_fail2/version (callback dies)"
    ) or diag(explain($result));
}

{
    note("callback returns unknown object");
    restish '/fail3' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => dispatch_item(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            bless {easter => 'egg'}, 'SomeRandomClass';
        },
        code_wrapper => sub {
            return 'pang';
        },
    };

    route_exists([GET => '/fail3/version'], "/fail3/ registered");

    my $response = dancer_response(
        GET => '/fail3/version',
    );
    is($response->{status}, 400, "callback http-status 500") or diag(explain($response));

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error_code    => -32603,
            error_message => "Internal error: 'callback_result' wrong class SomeRandomClass",
            error_data    => {},
        },
        "GET /fail3/version (callback wrong class)"
    ) or diag(explain($response));
}

{
    note("callback checks \$Dancer::RPCPlugin::ROUTE_INFO");
    restish '/callback' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version/:api_version' => dispatch_item(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            my ($request, $method_name, $method_args) = @_;

            # Access only for 'small-letter-v' with a version
            return $Dancer::RPCPlugin::ROUTE_INFO->{rpc_method} =~ qr{version/v\d+$}
                ? callback_success()
                : callback_fail(
                    error_code    => -32601,
                    error_message => "Access denied for $Dancer::RPCPlugin::ROUTE_INFO->{rpc_method}",
                );
        },
    };

    route_exists([GET => '/callback/version/v2'], "/callback/version registered");
    my $response = dancer_response(
        GET => '/callback/version/v2'
    );
    is($response->{status}, 200, "callback http-status 200") or diag(explain($response));

    $response = dancer_response(GET => '/callback/version/V2');
    is($response->{status}, 403, "'/callback/version/V2' is not valid")
        or diag(explain($response));

    my $error = from_json($response->{content});
    is_deeply(
        $error,
        {
            'error_code'    => '-32601',
            'error_data'    => {'api_version' => 'V2'},
            'error_message' => 'Access denied for version/V2'
        },
        "error-object"
    ) or diag(explain($error));
}

{
    note("code_wrapper dies");
    restish '/fail4' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => dispatch_item(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            return callback_success();
        },
        code_wrapper => sub {
            die "code_wrapper died\n";
        },
    };

    route_exists([GET => '/fail4/version'], "/fail4/version registered");

    my $response = dancer_response(
        GET => '/fail4/version',
    );
    is($response->{status}, 400, "code-wrapper http-status 500") or diag(explain($response));

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error_code    => 500,
            error_message => "code_wrapper died\n",
            error_data    => {},
        },
        "GET /fail4/version (code_wrapper dies)"
    );
}

{
    note("code_wrapper returns unknown object");
    restish '/fail5' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => dispatch_item(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            return callback_success();
        },
        code_wrapper => sub {
            return bless({easter => 'egg'}, 'SomeRandomClass');
        },
    };

    route_exists([GET => '/fail5/version'], "/fail5/version registered");

    my $response = dancer_response(
        GET => '/fail5/version',
    );
    is($response->{status}, 200, "code-wrapper http-status 200") or diag(explain($response));

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {easter => 'egg'},
        "GET /fail5/version (code_wrapper object)"
    ) or diag(explain($response));
}

{
    note("call fails");
    restish '/fail6' => {
        publish => sub {
            return {
                'GET@error' => dispatch_item(
                    code    => sub { die "Example error code\n" },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([GET => '/fail6/error'], "GET /fail6/error registered");

    my $response = dancer_response(
        GET => '/fail6/error',
    );
    is($response->{status}, 400, "code-fail http-status 500") or diag(explain($response));

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error_code    => 500,
            error_message => "Example error code\n",
            error_data    => { },
        },
        "GET /fail6/error"
    ) or diag(explain($response));
}

{
    note("call returns a error_response()");
    restish '/fail7' => {
        publish => sub {
            return {
                'GET@error' => dispatch_item(
                    code    => sub {
                        my $err = error_response(
                            error_code => -12345,
                            error_message => "You cannot do that",
                        );
                        Dancer::RPCPlugin::ErrorResponse->register_error_responses(restish => { -12345 => 409 });
                        return $err;
                    },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([GET => '/fail7/error'], "GET /fail7/error registered");

    my $response = dancer_response(
        GET => '/fail7/error',
    );
    is($response->{status}, 409, "code-fail http-status 409") or diag(explain($response));

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error_code    => -12345,
            error_message => "You cannot do that",
            error_data    => undef,
        },
        "GET /fail7/error (code returns error_response())"
    ) or diag(explain($response));
}

{
    note("call throws a error_response()");
    restish '/fail8' => {
        publish => sub {
            return {
                'GET@error' => dispatch_item(
                    code    => sub {
                        my $err = error_response(
                            error_code => -12345,
                            error_message => "You cannot do that",
                        );
                        Dancer::RPCPlugin::ErrorResponse->register_error_responses(restish => { -12345 => 409 });
                        die $err;
                    },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([GET => '/fail8/error'], "GET /fail8/error registered");

    my $response = dancer_response(
        GET => '/fail8/error',
    );
    is($response->{status}, 409, "code-fail http-status 409") or diag(explain($response));

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error_code    => -12345,
            error_message => "You cannot do that",
            error_data    => undef,
        },
        "GET /fail8/error (code throws error_response())"
    ) or diag(explain($response));
}

{
    note("call returns non-ref");
    restish '/return-text' => {
        publish => sub {
            return {
                'GET@plain-text' => dispatch_item(
                    code => sub {
                        content_type('text/plain');
                        return "Plain text\n2 lines";
                    },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([GET => '/return-text/plain-text'], "GET /return-text/plain-text");
    my $response = dancer_response(GET => '/return-text/plain-text');
    is(
        $response->{content},
        "Plain text\n2 lines",
        "got plain text"
    ) or diag(explain($response));
}

done_testing();
