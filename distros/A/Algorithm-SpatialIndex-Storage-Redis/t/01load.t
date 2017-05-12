use strict;
use warnings;
use Test::More;

my @modules = (
  map { "Algorithm::SpatialIndex::" . $_ }
  qw(
    Storage::Redis
  )
);
plan tests => scalar(@modules);

use_ok($_) for @modules;


