#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use Dancer::RPCPlugin::ErrorResponse;

{
    my $er = error_response(
        error_code    => 42,
        error_message => "The error is in the message",
    );
    isa_ok($er, 'Dancer::RPCPlugin::ErrorResponse');
    is($er->error_code, 42, "->error_code()");
    is($er->error_data, undef, "->error_data()");

    is_deeply(
        $er->as_xmlrpc_fault,
        {
            faultCode   => 42,
            faultString => "The error is in the message",
        },
        "->as_xmlrpc_fault()"
    );
    is_deeply(
        $er->as_jsonrpc_error,
        {
            error => {
                code    => 42,
                message => "The error is in the message",
            }
        },
        "->as_jsonrpc_error()"
    );
}

{
    my $er = error_response(
        error_code    => 42,
        error_message => "The error is in the message",
        error_data    => {one => 2},
    );
    isa_ok($er, 'Dancer::RPCPlugin::ErrorResponse');
    is($er->error_code, 42, "->error_code()");
    is_deeply($er->error_data, {one => 2}, "->error_data()");

    is_deeply(
        $er->as_xmlrpc_fault,
        {
            faultCode   => 42,
            faultString => "The error is in the message",
        },
        "->as_xmlrpc_fault()"
    );
    is_deeply(
        $er->as_jsonrpc_error,
        {
            error => {
                code    => 42,
                message => "The error is in the message",
                data    => {one => 2},
            }
        },
        "->as_jsonrpc_error()"
    );
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
