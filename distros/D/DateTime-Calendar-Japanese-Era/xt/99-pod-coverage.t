use strict;
use Test::More;

BEGIN {
    eval "use Test::Pod::Coverage";
    if ($@) {
        plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
    } else {
        my @modules = grep { $_ ne 'Gungho::Plugin::RequestTimer' } Test::Pod::Coverage::all_modules();
        plan tests => scalar(@modules);
        Test::Pod::Coverage::pod_coverage_ok($_) for @modules;
    }
}
