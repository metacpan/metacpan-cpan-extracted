use Test::More;
use Business::MollieAPI;

my $api = Business::MollieAPI->new();
Moo::Role->apply_roles_to_object($api, 'Business::MollieAPI::TestLog');

SKIP: {
    skip 'Specify TEST_MOLLIE_TESTMODE_KEY to run tests', 7 unless $ENV{TEST_MOLLIE_TESTMODE_KEY};
    $api->api_key($ENV{TEST_MOLLIE_TESTMODE_KEY});

    my $methods = $api->methods->all;

    is($api->log_response_called, 1);
    my $msg = $api->log_response_message;
    ok(exists $msg->{response});
    ok(exists $msg->{request});
}

done_testing();
