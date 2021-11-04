#!perl

use strict;
use Test2::V0;
use Test::Pod::Coverage 1.04;

# all_pod_coverage_ok() is buggy in 1.06 when there are modules
# in arch/. Let's reimplement it here:

my @modules = Test::Pod::Coverage::all_modules();
map {s/^arch::// } @modules; # Bug waz zere

for my $module ( @modules ) {
    pod_coverage_ok( $module, "Pod coverage on $module");
}

done_testing;
