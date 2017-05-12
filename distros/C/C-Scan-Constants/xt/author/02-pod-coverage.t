# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 06-pod-coverage.t'

#########################


use Test::More;
eval "use Test::Pod::Coverage tests => 1";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
pod_coverage_ok( "C::Scan::Constants",
                 "C::Scan::Constants is covered as expected");
