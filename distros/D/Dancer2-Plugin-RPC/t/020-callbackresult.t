#! perl -I. -w
use t::Test::abeltje;

use Dancer2::RPCPlugin::CallbackResultFactory;

subtest 'Success' => sub {
    my $success = callback_success();
    isa_ok($success, 'Dancer2::RPCPlugin::CallbackResult::Success');
    ok($success->does('Dancer2::RPCPlugin::CallbackResult'), "Role used");

    is("$success", "success", "->as_string");
};

subtest 'Fail' => sub {
    my $fail = callback_fail(
        error_code => 42,
        error_message => 'forty two',
    );
    isa_ok($fail, 'Dancer2::RPCPlugin::CallbackResult::Fail');
    ok($fail->does('Dancer2::RPCPlugin::CallbackResult'), "Role used");

    is("$fail", "fail (42 => forty two)", "->as_string");
};

abeltje_done_testing();
