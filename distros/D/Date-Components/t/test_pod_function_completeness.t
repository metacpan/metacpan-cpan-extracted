# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
eval {use Test::Pod::Coverage 1.08};
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD" if $@;
plan tests => 1;
pod_coverage_ok( "Date::Components" );
