use strict;
use warnings;
use Test::Exception tests => 1;
use FindBin;
use Dancer::Plugin::Tapir;

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
lives_ok {
    setup_tapir_handler
        thrift_idl    => $FindBin::Bin . '/thrift/example.thrift',
        handler_class => 'MyWebApp::Handler';
} "Setup with args";
