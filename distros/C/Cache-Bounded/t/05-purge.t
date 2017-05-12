use Cache::Bounded;
use Test::Simple tests => 3;
use strict;


my $cache = new Cache::Bounded ({ size => 25, interval => 25 });

for ( 1 .. 20 ) {
  $cache->set($_,$_);
}

ok(scalar(keys %{$cache->{cache}}) == 20);

for ( 1 .. 20 ) {
  $cache->set($_,$_);
}

ok(scalar(keys %{$cache->{cache}}) == 20);

for ( 1 .. 20 ) {
  $cache->set('foo'.$_,$_);
}

ok(scalar(keys %{$cache->{cache}}) == 11);

# 11 is result due to: 
# 20 INSERTIONS - no flush
# 20 REPEAT INSETRTIONS - interval check at 5th (25 total) - no flush
# 20 NEW INSERTIONS - interval check at 10th (50 total), cache purge & insertion, then
#                   - 10 more new items