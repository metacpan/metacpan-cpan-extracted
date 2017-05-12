use Test::More;
plan skip_all => 'set TEST_POD_COVERAGE to run this test' unless $ENV{TEST_POD_COVERAGE};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok();
