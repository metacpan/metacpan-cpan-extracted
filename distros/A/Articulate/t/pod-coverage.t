use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN {
  plan skip_all => 'POD Coverage tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}

eval "use Test::Pod::Coverage";

if ($@) {
  plan skip_all => "Test::Pod::Coverage required for testing POD Coverage";
}
else {
  &Test::Pod::Coverage::pod_coverage_ok($_)
    for &Test::Pod::Coverage::all_modules;
}

done_testing;
