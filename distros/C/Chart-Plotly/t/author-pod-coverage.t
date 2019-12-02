#!perl

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use Test::More;

use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

eval "use Devel::IPerl";
plan skip_all => "Devel::IPerl required for testing POD" if $@;

all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::TrustPod' } );
