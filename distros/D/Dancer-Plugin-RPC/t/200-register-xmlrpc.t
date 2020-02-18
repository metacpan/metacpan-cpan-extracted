#! perl -w
use strict;
use lib 't/lib';

use Test::More;

use Dancer qw/:syntax !pass/;
use Dancer::Plugin::RPC::XMLRPC;
use Dancer::RPCPlugin::CallbackResult;
use Dancer::RPCPlugin::DispatchItem;
use Dancer::RPCPlugin::ErrorResponse;

use Dancer::Test;

use RPC::XML;
use RPC::XML::ParserFactory;
my $p = RPC::XML::ParserFactory->new();

{
    note("default publish (config)");
    set(plugins => {
        'RPC::XMLRPC' => {
            '/endpoint' => {
                'TestProject::SystemCalls' => {
                    'system.ping' => 'do_ping',
                    'system.version' => 'do_version',
                },
            },
        }
    });
    xmlrpc '/endpoint' => { };

    route_exists([POST => '/endpoint'], "/endpoint registered");

    my $response = dancer_response(
        POST => '/endpoint',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new(
                'system.ping',
            )->as_string,
        }
    );

    is($response->status, 200, "Success produces HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;

    is_deeply(
        $result->value,
        { response => 1 },
        "system.ping"
    );
}

{
    note("publish is code that returns the dispatch-table");
    xmlrpc '/endpoint2' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'code.ping' => dispatch_item(
                    code => TestProject::SystemCalls->can('do_ping'),
                    package => 'TestProject::SystemCalls',
                ),
            };
        },
        callback => sub { return callback_success(); },
    };

    route_exists([POST => '/endpoint2'], "/endpoint2 registered");

    my $response = dancer_response(
        POST => '/endpoint2',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new(
                'code.ping',
            )->as_string,
        }
    );

    is($response->status, 200, "Success produces HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        { response => 1 },
        "code.ping"
    );
}

{
    note("callback fails");
    xmlrpc '/endpoint_fail' => {
        publish => sub {
            eval { require TestProject::SystemCalls; };
            error("Cannot load: $@") if $@;
            return {
                'fail.ping' => dispatch_item(
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

    route_exists([POST => '/endpoint_fail'], "/endpoint_fail registered");

    my $response = dancer_response(
        POST => '/endpoint_fail',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.ping')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {faultCode => -500, faultString =>"Force callback error"},
        "fail.ping"
    );
}

{
    note("callback dies");
    xmlrpc '/endpoint_fail2' => {
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

    route_exists([POST => '/endpoint_fail2'], "/endpoint_fail2 registered");

    my $response = dancer_response(
        POST => '/endpoint_fail2',
        {
            headers => [
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.ping')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {faultCode => -32500, faultString =>"terrible death\n"},
        "fail.ping"
    );
}

{
    note("code_wrapper dies");
    xmlrpc '/endpoint_fail3' => {
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
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.ping')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {faultCode => -32500, faultString =>"code_wrapper died\n"},
        "fail.ping (code_wrapper)"
    );
}

{
    note("callback returns unknown object");
    xmlrpc '/endpoint_fail4' => {
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
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.ping')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {
            faultCode   => -32500,
            faultString => "Internal error: 'callback_result' wrong class SomeRandomClass"
        },
        "fail.ping (callback wrong class)"
    ) or diag(explain($result->value));
}

{
    note("code_wrapper returns unknown object");
    xmlrpc '/endpoint_fail5' => {
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
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.ping')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {easter => 'egg'},
        "fail.ping (code_wrapper object)"
    ) or diag(explain($result->value));
}

{
    note("rpc-call fails");
    xmlrpc '/endpoint_error' => {
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
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.error')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {faultCode => -32500, faultString =>"Example error code\n"},
        "fail.error"
    );
}

{
    note("return an error_response()");
    xmlrpc '/endpoint_fault' => {
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
                'Content-Type' => 'text/xml',
            ],
            body => RPC::XML::request->new('fail.error')->as_string,
        }
    );

    is($response->status, 200, "Errors produce HTTP 200 OK");
    my $result = $p->parse($response->{content})->value;
    is_deeply(
        $result->value,
        {faultCode => 42, faultString =>"Boo!"},
        "fail.error"
    ) or diag(explain($result->value));
}

done_testing();
