use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD"
	if $@;
plan skip_all => '$ENV{TEST_POD} is not set'
	unless((($ENV{USER} || '') eq 'ewilhelm') or exists($ENV{TEST_POD}));

all_pod_files_ok();

# vi:syntax=perl:ts=4:sw=4:noet
