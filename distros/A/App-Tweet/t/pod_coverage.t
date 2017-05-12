use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => 'DEVELOPMENT environment variable not set'
  unless exists $ENV{DEVELOPMENT};
plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
  if $@;
all_pod_coverage_ok();
