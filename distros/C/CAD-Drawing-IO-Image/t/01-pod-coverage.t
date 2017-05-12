use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
	if $@;
plan skip_all => '$ENV{TEST_POD_COVERAGE} is not set'
	unless((($ENV{USER} || '') eq 'ewilhelm') or exists($ENV{TEST_POD_COVERAGE}));

all_pod_coverage_ok();

# vi:syntax=perl:ts=4:sw=4:noet
