use strict;
use Test::More;

plan skip_all => "Enable TEST_POD environment variable to test POD"
    if not $ENV{TEST_POD} and not -d '.git';

plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
    if not eval "use Test::Pod::Coverage; 1";

Test::Pod::Coverage::all_pod_coverage_ok();
