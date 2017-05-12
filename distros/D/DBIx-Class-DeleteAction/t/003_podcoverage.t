# -*- perl -*-

# t/003_podcoverage.t - check pod coverage

use Test::More tests=>1;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

pod_coverage_ok( 
    "DBIx::Class::DeleteAction", 
    "POD is covered" );