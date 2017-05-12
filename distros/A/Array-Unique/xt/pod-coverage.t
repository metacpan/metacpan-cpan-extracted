use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => 'Needs Test::Pod::Coverage' if $@;
#all_pod_coverage_ok();
plan tests => 1;
pod_coverage_ok('Array::Unique');

