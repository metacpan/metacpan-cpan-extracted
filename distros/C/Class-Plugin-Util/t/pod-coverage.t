#!perl -T

use Test::More;

if ( not $ENV{CLASSPLUGINUTIL_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{CLASSPLUGINUTIL_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
