use Cache::Bounded;
use Test::Simple tests => 2500;
use strict;

my $cache = new Cache::Bounded;
$cache->set('foo','foo');

for ( 1 .. 2500 ) {
  ok($cache->get('foo') eq 'foo');
}
