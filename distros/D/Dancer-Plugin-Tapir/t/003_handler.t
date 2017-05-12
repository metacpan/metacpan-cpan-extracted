use strict;
use warnings;
use Test::More tests => 6;
use FindBin;
use Dancer qw(config);
use Dancer::Test;
use Dancer::Plugin::Tapir;

# We're going to redefine methods; let's ignore warnings about it
$Tapir::Server::Handler::Signatures::ALLOW_REDEFINE = 1;

# Avoid errors with "require MyWebApp::Handler"
$INC{'MyWebApp/Handler.pm'} = undef;

{
    package MyWebApp::Handler;

    use Moose;
    use Tapir::Server::Handler::Signatures;
    extends 'Tapir::Server::Handler::Class';

    set_service 'Accounts';

    method createAccount ($username, $password) {
        print "createAccount called with $username and $password\n";
        $call->set_result({
            id         => 42,
            allocation => 1000,
        });
    }

    method getAccount ($username) {
        print "getAccount called with $username\n";
        $call->set_result({
            id         => 42,
            error      => "this will fail",
            allocation => 1000,
        });
    }
}

setup_tapir_handler
    thrift_idl    => $FindBin::Bin . '/thrift/example.thrift',
    handler_class => 'MyWebApp::Handler';

response_status_is [ GET => '/' ], 404, "No root route";

response_status_is [ GET => '/accounts' ], 404, "No GET /accounts";
response_status_is [ POST => '/accounts' ], 400, "POST /accounts exists (but throws user error without args)";
response_status_is [ POST => '/accounts?username=johndoe&password=abc123' ], 200, "POST /accounts with args";

response_status_is [ GET => '/account/johndoe' ], 500, "GET /account/:username threw internal error due to invalid set_result() call";

{
    package MyWebApp::Handler;
    method getAccount ($username) {
        $call->set_result({
            id         => 42,
            allocation => 1000,
        });
    }
}

response_status_is [ GET => '/account/johndoe' ], 200, "GET /account/:username with valid set_result()";
