use strict;
use Test::More;
BEGIN {
    if (! $ENV{'TEST_AUTHOR'}) {
        plan(skip_all => "TEST_AUTHOR environment variable is not set");
    }
}
use Test::Requires;
test_requires 'Test::Pod::Coverage';

Test::Pod::Coverage::all_pod_coverage_ok({
    trustme => [ 'BUILD' ]
});
