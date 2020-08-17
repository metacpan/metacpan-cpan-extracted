#! perl -I. -w
use t::Test::abeltje;

use Dancer::RPCPlugin::CallbackResult;

{
    my $cbr = callback_success();
    isa_ok($cbr, 'Dancer::RPCPlugin::CallbackResult');
    isa_ok($cbr, 'Dancer::RPCPlugin::CallbackResult::Success');

    is("$cbr", "success", "stringify-overload");

    my $e = exception {$cbr->does_not_exist};
    like($e, qr/^Unknown attribute does_not_exist/, "unknown attirbute");
}

{
    my $cbr = callback_fail(
        error_code => 42,
        error_message => "The error is in the message",
    );
    isa_ok($cbr, 'Dancer::RPCPlugin::CallbackResult');
    isa_ok($cbr, 'Dancer::RPCPlugin::CallbackResult::Fail');

    is("$cbr", "fail (42 => The error is in the message)", "stringify-overload");
}

done_testing();
