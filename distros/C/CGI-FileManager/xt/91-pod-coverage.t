
use Test::More;
plan skip_all => 'Needs Test::Pod::Coverage' if not eval "use Test::Pod::Coverage; 1";
all_pod_coverage_ok();
