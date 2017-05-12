use strict;

use Test::More;
use Test::Exception;

use Business::MollieAPI;
use Data::Dumper;
use JSON::XS;

SKIP: {
    skip 'Specify TEST_MOLLIE_TESTMODE_KEY to run tests', 5 unless $ENV{TEST_MOLLIE_TESTMODE_KEY};

    my $api = Business::MollieAPI->new(
        api_key => $ENV{TEST_MOLLIE_TESTMODE_KEY},
    );

    my $methods = $api->methods->all;

    ok($methods);

    ok(ref($methods), 'HASH');
    ok(exists $methods->{count}, 'has count');
    ok(exists $methods->{totalCount}, 'has total_count');
    ok(exists $methods->{offset}, 'has offset');
}

done_testing();

