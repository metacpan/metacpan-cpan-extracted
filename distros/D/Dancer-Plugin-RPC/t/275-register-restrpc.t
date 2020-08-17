#! perl -I. -w
use t::Test::abeltje;

use Dancer qw/:syntax !pass !warning/;
use Dancer::Plugin::RPC::RESTRPC;
use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::ErrorResponse;

use Dancer::Test;


{
    note("default publish (config)");
    set(plugins => {
        'RPC::RESTRPC' => {
            '/rest/system' => {
                'TestProject::SystemCalls' => {
                    'ping' => 'do_ping',
                    'version' => 'do_version',
                },
            },
        }
    });
    restrpc '/rest/system' => { };

    route_exists([POST => '/rest/system/ping'], "/rest/system registered");

    my $response = dancer_response(
        POST => '/rest/system/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        from_json('{"response": true}'),
        "/rest/system/ping"
    );
}

{
    note("publish is code that returns the dispatch-table");
    restrpc '/rest/systeem' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'ping' => dispatch_item(
                    code => TestProject::SystemCalls->can('do_ping'),
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub { return callback_success(); },
    };

    route_exists([POST => '/rest/systeem/ping'], "/rest/systeem/ping registered");

    my $response = dancer_response(
        POST => '/rest/systeem/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    #diag(explain($response));
    my $result = from_json($response->{content});
    is_deeply(
        $result,
        from_json('{"response": true}'),
        "/rest/systeem/ping"
    );
}

{
    note("callback fails");
    restrpc '/rest/failsystem' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'ping' => dispatch_item(
                    code => TestProject::SystemCalls->can('do_ping'),
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            return callback_fail(
                error_code    => -500,
                error_message => "Force callback error",
            );
        },
    };

    route_exists([POST => '/rest/failsystem/ping'], "/rest/failsystem/ping registered");

    my $response = dancer_response(
        POST => '/rest/failsystem/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    # diag(explain($response));
    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error => {
                code    => -500,
                message => "Force callback error"
            }
        },
        "/rest/failsystem/ping"
    );
}

{
    note("callback dies");
    restrpc '/rest/morefail' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            die "terrible death\n";
        },
    };

    route_exists([POST => '/rest/morefail/ping'], "/rest/morefail/ping registered");

    my $response = dancer_response(
        POST => '/rest/morefail/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    #diag(explain($response));
    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {error => {code => 500, message =>"terrible death\n"}},
        "/rest/morefail/ping"
    );
}

{
    note("code_wrapper dies");
    restrpc '/rest/fail3' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            return callback_success();
        },
        code_wrapper => sub {
            die "code_wrapper died\n";
        }
    };

    route_exists([POST => '/rest/fail3/ping'], "/rest/fail3/ping registered");

    my $response = dancer_response(
        POST => '/rest/fail3/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {error => {code => -32500, message =>"code_wrapper died\n"}},
        "/rest/fail3/ping (code_wrapper died)"
    ) or diag(explain($result));
}

{
    note("callback returns unknown object");
    restrpc '/rest/fail4' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            bless {easter => 'egg'}, 'SomeRandomClass';
        },
        code_wrapper => sub {
            return 'pang';
        }
    };

    route_exists([POST => '/rest/fail4/ping'], "/rest/fail4/ping registered");

    my $response = dancer_response(
        POST => '/rest/fail4/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {
            error => {
                code    => 500,
                message => "Internal error: 'callback_result' wrong class SomeRandomClass"
            }
        },
        "/rest/fail4/ping (callback wrong class)"
    ) or diag(explain($result));
}

{
    note("code_wrapper returns unknown object");
    restrpc '/rest/fail5' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            return callback_success();
        },
        code_wrapper => sub {
            bless {easter => 'egg'}, 'SomeRandomClass';
        }
    };

    route_exists([POST => '/rest/fail5/ping'], "/rest/fail5/ping registered");

    my $response = dancer_response(
        POST => '/rest/fail5/ping',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {easter => 'egg'},
        "/rest/fail5/ping (code_wrapper object)"
    ) or diag(explain($result));
}

{
    note("rpc-call fails");
    restrpc '/rest/error' => {
        publish => sub {
            return {
                'code_fail' => dispatch_item(
                    code => sub { die "Example error code\n" },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([POST => '/rest/error/code_fail'], "/rest/error/code_fail registered");

    my $response = dancer_response(
        POST => '/rest/error/code_fail',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {error => {code => -32500, message =>"Example error code\n"}},
        "/rest/error/code_fail"
    );
}

{
    note("return an error_response()");
    restrpc '/rest/fault' => {
        publish => sub {
            return {
                'code_error' => dispatch_item(
                    code => sub { error_response(error_code => 42, error_message => "Boo!") },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([POST => '/rest/fault/code_error'], "/rest/fault/code_error registered");

    my $response = dancer_response(
        POST => '/rest/fault/code_error',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $result = from_json($response->{content});
    is_deeply(
        $result,
        {error => {code => 42, message =>"Boo!"}},
        "/rest/fault/code_error"
    ) or diag(explain($result));
}

done_testing();
