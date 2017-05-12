use strict;
use warnings;
use Test::Exception tests => 9;
use FindBin;
use Dancer qw(config);
use Dancer::Plugin::Tapir;

throws_ok { setup_tapir_handler } qr/Missing configuration settings/, "Omit settings";

my %tapir_config = (
    thrift_idl    => $FindBin::Bin . '/thrift/example.thrift',
    handler_class => 'MyWebApp::Handler',
);
config->{plugins}{Tapir} = \%tapir_config;

{
    local $tapir_config{thrift_idl} = "/made/up/file";
    throws_ok { setup_tapir_handler } qr/Invalid thrift_idl file/, "Pass a non-existant thrift_idl file name";
}

{
    local $tapir_config{thrift_idl} = $FindBin::Bin . '/thrift/bad.thrift';
    throws_ok { setup_tapir_handler } qr/Parsing failed to consume all of the input/, "Pass a bad thrift_idl file";
}

{
    local $tapir_config{thrift_idl} = $FindBin::Bin . '/thrift/invalid.thrift';
    throws_ok { setup_tapir_handler } qr/the following errors were found.+has no comments/s, "Pass a thrift file which fails the validation check";
}

throws_ok { setup_tapir_handler } qr/Failed to load MyWebApp::Handler/, "Handler doesn't load";

$INC{'MyWebApp/Handler.pm'} = undef;

throws_ok { setup_tapir_handler } qr/must be a subclass of Tapir/, "Handler invalid subclass";

{
    package MyWebApp::Handler;

    use Moose;
    use Tapir::Server::Handler::Signatures;
    extends 'Tapir::Server::Handler::Class';
}

throws_ok { setup_tapir_handler } qr/didn't call service/, "Handler didn't call service()";

{
    package MyWebApp::Handler;

    set_service 'Accounts';

    method getAccount ($username) {
        print "getAccount called with $username\n";
        $call->set_result({
            id         => 42,
            error      => "this will fail",
            allocation => 1000,
        });
    }
}

throws_ok { setup_tapir_handler } qr/doesn't handle method createAccount/, "Missing methods";

{
    package MyWebApp::Handler;
    method createAccount { }
}

lives_ok { setup_tapir_handler } "Setup now completes without errors";
