use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN {
  plan skip_all => 'POD Coverage tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}

eval "use Test::Pod::Coverage";

plan skip_all => "Test::Pod::Coverage required for testing POD Coverage" if $@;

pod_coverage_ok( $_ ) for all_modules;

done_testing;
