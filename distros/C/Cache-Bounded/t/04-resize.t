use Cache::Bounded;
use Test::Simple tests => 2;
use strict;


my $cache = new Cache::Bounded ({ size => 25, interval => 25 });

for ( 1 .. 24 ) {
  $cache->set($_,$_);
}

ok(scalar(keys %{$cache->{cache}}) == 24,'basic insertions');

$cache->set(25,25);

ok(scalar(keys %{$cache->{cache}}) == 1,'cache purged and resized');