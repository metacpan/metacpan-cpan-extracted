#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
my $trustme = { trustme => [qr/^(igroup_by|str_row_equal|num_row_equal)$/] };
all_pod_coverage_ok();
