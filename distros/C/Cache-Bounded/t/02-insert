use Cache::Bounded;
use Test::Simple tests => 2500;
use strict;

my $cache = new Cache::Bounded;

for ( 1 .. 2500 ) {
  ok($cache->set($_,$_));
}
