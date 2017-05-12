#!perl

use Test::More;
my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 1;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

pass('Pod::Coverage');
eval "use Test::Pod::Coverage 1.04";
diag("Test::Pod::Coverage 1.04 required for testing POD coverage") if $@;
#all_pod_coverage_ok();
