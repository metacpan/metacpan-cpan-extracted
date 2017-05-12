#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn';
#all_pod_coverage_ok();
plan tests => 4;

pod_coverage_ok( 'DashProfiler' );
pod_coverage_ok( 'DashProfiler::Core' );
pod_coverage_ok( 'DashProfiler::Sample' );
pod_coverage_ok( 'DashProfiler::Apache', { coverage_class => 'Pod::Coverage::CountParents' } );

