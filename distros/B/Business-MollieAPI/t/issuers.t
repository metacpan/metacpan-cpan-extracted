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

    my $issuers = $api->issuers->all;

    ok($issuers);

    ok(ref($issuers), 'HASH');
    ok(exists $issuers->{count});
    ok(exists $issuers->{totalCount});
    ok(exists $issuers->{offset});
    ok(exists $issuers->{data});
    ok(ref($issuers->{data}) eq 'ARRAY');
}

done_testing();

