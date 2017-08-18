use strict;
use Test::More;
BEGIN {
    if (! $ENV{TEST_POD_COVERAGE}) {
        plan skip_all => "Enable TEST_POD_COVERAGE to run this test";
    }
}

use Test::Requires;

test_requires 'Test::Pod::Coverage';

Test::Pod::Coverage::all_pod_coverage_ok({
    trustme => [ 'BUILD' ]
});
