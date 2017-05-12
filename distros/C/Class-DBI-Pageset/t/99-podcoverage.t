use strict;
use warnings;
use Test::More;

plan( skip_all => 'Author test. Set TEST_AUTHOR to a true value to run.' )
    unless $ENV{TEST_AUTHOR};

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    if $@;
all_pod_coverage_ok();
