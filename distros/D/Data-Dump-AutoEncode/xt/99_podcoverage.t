use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set RELEASE_TESTING to enable this test' unless $ENV{RELEASE_TESTING};

all_pod_coverage_ok();
