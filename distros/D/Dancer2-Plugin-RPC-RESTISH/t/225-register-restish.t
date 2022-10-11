#! perl -I. -w
use t::Test::abeltje;

use Dancer2;

use Dancer2::Plugin::RPC::RESTISH;
use Dancer2::RPCPlugin::CallbackResultFactory;
use Dancer2::RPCPlugin::DispatchItem;
use Dancer2::RPCPlugin::ErrorResponse;

use HTTP::Request;
use Plack::Test;

{
    note("default publish == 'config'");
    set(
        plugins => {
            'RPC::RESTISH' => {
                '/endpoint' => {
                    'TestProject::SystemCalls' => {
                        'GET@ping'    => 'do_ping',
                        'GET@version' => 'do_version',
                    },
                },
            }
        },
        log      => ($ENV{TEST_DEBUG} ? 'debug' : 'error'),
        encoding => 'utf-8',
       );

    restish '/endpoint' => { };

    my $tester = Plack::Test->create(main->to_app());
    my $response = $tester->request(
        HTTP::Request->new(GET => '/endpoint/ping')
    );

    my $ping = from_json('{"response": true}');

    is_deeply(
        from_json($response->content),
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
                'GET@version' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => TestProject::SystemCalls->can('do_version'),
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub { return callback_success(); },
    };

    my $tester = Plack::Test->create(main->to_app());
    my $response = $tester->request(
        HTTP::Request->new(GET => '/endpoint2/version')
    );

    is_deeply(
        from_json($response->content),
        { software_version => $TestProject::SystemCalls::VERSION },
        "GET /endpoint2/version"
    ) or diag(explain($response->content));
}

{
    note("callback fails");
    restish '/fail1' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => Dancer2::RPCPlugin::DispatchItem->new(
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

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail1/version')
    );

    is($response->code, 403, "callback http-status 403") or diag(explain($response));

    my $result = $response->header('content-type') eq 'application/json'
        ? from_json($response->content)
        : $response->content;
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
                'GET@version' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            die "terrible death\n";
        },
    };

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail2/version')
    );
    is($response->code, 500, "callback http-status 500") or diag(explain($response));

    my $result = $response->header('content-type') eq 'application/json'
        ? from_json($response->content)
        : $response->content;
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
                'GET@version' => Dancer2::RPCPlugin::DispatchItem->new(
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

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail3/version')
    );
    is($response->code, 400, "callback http-status 500") or diag(explain($response));

    my $result = from_json($response->content);
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
    note("callback checks \$Dancer2::RPCPlugin::ROUTE_INFO");
    restish '/callback' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version/:api_version' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => \&TestProject::SystemCalls::do_version,
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub {
            my ($request, $method_name, $method_args) = @_;

            # Access only for 'small-letter-v' with a version
            return $Dancer2::RPCPlugin::ROUTE_INFO->{rpc_method} =~ qr{version/v\d+$}
                ? callback_success()
                : callback_fail(
                    error_code    => -32601,
                    error_message => "Access denied for $Dancer2::RPCPlugin::ROUTE_INFO->{rpc_method}",
                );
        },
    };

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/callback/version/v2')
    );
    is($response->code, 200, "callback http-status 200") or diag(explain($response));

    $response = $tester->request(
        HTTP::Request->new(GET => '/callback/version/V2')
    );
    is($response->code, 403, "'/callback/version/V2' is not valid")
        or diag(explain($response));

    my $error = from_json($response->content);
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
                'GET@version' => Dancer2::RPCPlugin::DispatchItem->new(
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

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail4/version')
    );
    is($response->code, 400, "code-wrapper http-status 500") or diag(explain($response));

    my $result = from_json($response->content);
    is_deeply(
        $result,
        {
            error_code    => 500,
            error_message => "code_wrapper died\n",
            error_data    => {},
        },
        "GET /fail4/version (code_wrapper dies)"
    ) or diag(explain($response));
}

{
    note("code_wrapper returns unknown object");
    restish '/fail5' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'GET@version' => Dancer2::RPCPlugin::DispatchItem->new(
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

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail5/version')
    );
    is($response->code, 200, "code-wrapper http-status 200") or diag(explain($response));

    my $result = from_json($response->content);
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
                'GET@error' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => sub { die "Example error code\n" },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail6/error')
    );
    is($response->code, 400, "code-fail http-status 500") or diag(explain($response));

    my $result = from_json($response->content);
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
                'GET@error' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => sub {
                        my $err = error_response(
                            error_code => -12345,
                            error_message => "You cannot do that",
                        );
                        Dancer2::RPCPlugin::ErrorResponse->register_error_responses(
                            restish => { -12345 => 409 }
                        );
                        return $err;
                    },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail7/error')
    );
    is($response->code, 409, "code-fail http-status 409") or diag(explain($response));

    my $result = from_json($response->content);
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
                'GET@error' => Dancer2::RPCPlugin::DispatchItem->new(
                    code    => sub {
                        my $err = error_response(
                            error_code => -12345,
                            error_message => "You cannot do that",
                        );
                        Dancer2::RPCPlugin::ErrorResponse->register_error_responses(
                            restish => { -12345 => 409 }
                        );
                        die $err;
                    },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/fail8/error')
    );
    is($response->code, 409, "code-fail http-status 409") or diag(explain($response));

    my $result = from_json($response->content);
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
                'GET@plain-text' => Dancer2::RPCPlugin::DispatchItem->new(
                    code => sub {
                        content_type('text/plain');
                        return "Plain text\n2 lines";
                    },
                    package => __PACKAGE__,
                ),
            };
        },
    };

    my $tester = Plack::Test->create(main->to_app());

    my $response = $tester->request(
        HTTP::Request->new(GET => '/return-text/plain-text')
    );
    is(
        $response->content,
        "Plain text\n2 lines",
        "got plain text"
    ) or diag(explain($response));
}

abeltje_done_testing();
