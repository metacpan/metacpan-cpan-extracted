#! perl -w
use strict;
use lib 't/lib';

use Test::More;

use Dancer qw/:syntax !pass/;
use Dancer::Plugin::RPC::JSONRPC;
use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::ErrorResponse;

use Dancer::Test;

{ # default publish => 'pod' ; Batch-mode
    set(plugins => {
        'RPC::JSONRPC' => {
            '/endpoint' => {
                'TestProject::SystemCalls' => {
                    'system.ping' => 'do_ping',
                    'system.version' => 'do_version',
                },
            },
        }
    });
    jsonrpc '/endpoint' => { };

    route_exists([POST => '/endpoint'], "/endpoint registered");

    my $response = dancer_response(
        POST => '/endpoint',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json([
                {
                    jsonrpc => '2.0',
                    method  => 'system.ping',
                    id      => 42,
                },
                {
                    jsonrpc => '2.0',
                    method  => 'system.version',
                    id      => 43,
                }
            ]),
        }
    );

    my $ping = from_json('{"response": true}');
    if (JSON->VERSION >= 2.90) {
        my $t = 1;
        $ping->{response} = bless \$t, 'JSON::PP::Boolean';
    }

    my @results = map $_->{result}, @{from_json($response->{content})};
    is_deeply(
        \@results,
        [
            $ping,
            {software_version => '1.0'},
        ],
        "system.ping"
    ) or diag(explain(\@results));
}

{ # publish is code that returns the dispatch-table
    jsonrpc '/endpoint2' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'code.ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub { return callback_success() },
    };

    route_exists([POST => '/endpoint2'], "/endpoint2 registered");

    my $response = dancer_response(
        POST => '/endpoint2',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'code.ping',
                    id      => 42,
                }
            ),
        }
    );

    my $ping = from_json('{"response": true}');
    if (JSON->VERSION >= 2.90) {
        my $t = 1;
        $ping->{response} = bless \$t, 'JSON::PP::Boolean';
    }

    is_deeply(
        from_json($response->{content})->{result},
        $ping,
        "code.ping"
    );
}

{ # callback fails
    jsonrpc '/endpoint_fail' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'fail.ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
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

    route_exists([POST => '/endpoint_fail'], "/endpoint_fail registered");

    my $response = dancer_response(
        POST => '/endpoint_fail',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.ping',
                    id      => 42,
                }
            ),
        }
    );

    is_deeply(
        from_json($response->{content})->{error},
        {code => -500, message =>"Force callback error"},
        "fail.ping"
    ) or diag($response->{content});
}

{ # callback dies
    jsonrpc '/endpoint_fail2' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'fail.ping' => dispatch_item(
                    code => \&TestProject::SystemCalls::do_ping,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            die "terrible death\n";
        },
    };

    route_exists([POST => '/endpoint_fail2'], "/endpoint_fail registered");

    my $response = dancer_response(
        POST => '/endpoint_fail2',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.ping',
                    id      => 42,
                }
            ),
        }
    );

    is_deeply(
        from_json($response->{content})->{error},
        {code => 500, message =>"terrible death\n"},
        "fail.ping"
    );
}

{ # code_wrapper dies
    jsonrpc '/endpoint_fail3' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'fail.ping' => dispatch_item(
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
        },
    };

    route_exists([POST => '/endpoint_fail3'], "/endpoint_fail3 registered");

    my $response = dancer_response(
        POST => '/endpoint_fail3',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.ping',
                    id      => 42,
                }
            ),
        }
    );

    my $error = from_json($response->{content})->{error};
    is_deeply(
        $error,
        {code => 500, message =>"code_wrapper died\n"},
        "fail.ping (code_wrapper died)"
    ) or diag(explain($error));
}

{ # callback returns unknown object
    jsonrpc '/endpoint_fail4' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'fail.ping' => dispatch_item(
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
        },
    };

    route_exists([POST => '/endpoint_fail4'], "/endpoint_fail4 registered");

    my $response = dancer_response(
        POST => '/endpoint_fail4',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.ping',
                    id      => 42,
                }
            ),
        }
    );

    my $error = from_json($response->{content})->{error};
    is_deeply(
        $error,
        {
            code    => -32603,
            message => "Internal error: 'callback_result' wrong class SomeRandomClass",
        },
        "fail.ping (callback wrong class)"
    ) or diag(explain($error));
}

{ # code_wrapper returns unknown object
    jsonrpc '/endpoint_fail5' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'fail.ping' => dispatch_item(
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
        },
    };

    route_exists([POST => '/endpoint_fail5'], "/endpoint_fail5 registered");

    my $response = dancer_response(
        POST => '/endpoint_fail5',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.ping',
                    id      => 42,
                }
            ),
        }
    );

    my $error = from_json($response->{content})->{result};
    is_deeply(
        $error,
        {easter => 'egg'},
        "fail.ping (code_wrapper object)"
    ) or diag(explain($error));
}


{ # rpc-call fails
    jsonrpc '/endpoint_error' => {
        publish => sub {
            return {
                'fail.error' => dispatch_item(
                    code => sub { die "Example error code\n" },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([POST => '/endpoint_error'], "/endpoint_error registered");

    my $response = dancer_response(
        POST => '/endpoint_error',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.error',
                    id      => 42,
                }
            ),
        }
    );

    is_deeply(
        from_json($response->{content})->{error},
        {code => 500, message =>"Example error code\n"},
        "fail.error"
    );
}

{ # return an error_response()
    jsonrpc '/endpoint_fault' => {
        publish => sub {
            return {
                'fail.error' => dispatch_item(
                    code => sub { error_response(error_code => 42, error_message => "Boo!") },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    route_exists([POST => '/endpoint_fault'], "/endpoint_fault registered");

    my $response = dancer_response(
        POST => '/endpoint_fault',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
            body => to_json(
                {
                    jsonrpc => '2.0',
                    method  => 'fail.error',
                    id      => 42,
                }
            ),
        }
    );

    is_deeply(
        from_json($response->{content})->{error},
        {code => 42, message =>"Boo!"},
        "fail.error"
    ) or diag(explain($response));
}

done_testing();
