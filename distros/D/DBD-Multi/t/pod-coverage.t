use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage - $@" if $@;
plan skip_all => 'Pod not available for individual methods in DBD::Multi, use DBI instead.';
all_pod_coverage_ok();
