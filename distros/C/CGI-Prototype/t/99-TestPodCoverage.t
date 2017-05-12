#!perl
use Test::More;
plan skip_all => "Test::Pod::Coverage required for testing POD"
  unless eval "use Test::Pod::Coverage; 1";
all_pod_coverage_ok();
