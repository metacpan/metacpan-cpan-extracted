#perl -T 

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "We don't POD coverage yet to tell the truth";

all_pod_coverage_ok();
