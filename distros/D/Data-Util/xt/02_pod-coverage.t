#!perl -w

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

local $SIG{__WARN__} = sub{ 1 }; # not to concern about 'redefine' warnings
for my $module (all_modules()) {
	next if $module =~ m/PurePerl$/;
	pod_coverage_ok($module, {
		also_private => [qw(unimport regex_ref is_regex_ref)],
	});
}

done_testing;
