use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;

# The LRU tests elsewhere assert how MANY entries survive, not WHICH.  That let
# two injected defects survive both suites: a resize can rebuild the recency
# chain backwards, so the map evicts its hottest entry instead of its coldest;
# and the promotion-skip optimisation can skip the tail, so the entry a caller
# just refreshed is evicted anyway.  Both leave the entry count perfectly correct.

my $dir = File::Temp::tempdir(CLEANUP => 1);

# --- the victim after a resize -------------------------------------------
{
    my $path = File::Spec->catfile($dir, 'order.shm');
    my $map = Data::HashMap::Shared::II->new($path, 100_000, 100);   # max_size 100
    $map->put($_, $_) for 1 .. 100;
    is($map->size, 100, 'filled to max_size');

    my $before = $map->capacity;
    $map->reserve(20_000);                        # rebuilds the recency chain
    cmp_ok($map->capacity, '>', $before, 'reserve grew the table');
    is($map->size, 100, '  ... without losing entries');

    $map->put(101, 101);                          # one over: evict the coldest
    is($map->stats->{evictions}, 1, 'inserting past max_size evicted exactly one');
    ok(!defined($map->get(1)),   'the coldest entry was evicted after a resize');
    ok(defined($map->get(100)),  '  ... and the hottest was kept');
    ok(defined($map->get(101)),  '  ... and the new entry is present');
}

# --- the tail is exempt from the promotion skip ---------------------------
{
    my $path = File::Spec->catfile($dir, 'skip.shm');
    # lru_skip 90: nine promotions in ten are skipped as an optimisation, but
    # the tail must never be skipped or refreshing it cannot save it.
    my $map = Data::HashMap::Shared::II->new($path, 100_000, 50, 0, 90);
    $map->put($_, $_) for 1 .. 50;
    is($map->size, 50, 'filled to max_size with lru_skip=90');

    $map->touch(1);              # key 1 is the tail; refreshing it must count
    $map->put(51, 51);           # forces one eviction

    ok(defined($map->get(1)),  'a touched tail entry survives with lru_skip set');
    ok(!defined($map->get(2)), '  ... and the entry behind it was evicted instead');
}


# When eviction reaches an entry that had already expired, that is an expiry,
# not an eviction.  Both counters are asserted elsewhere, but never in the one
# state where the code has to choose between them.
{
    my $path = File::Spec->catfile($dir, 'stats.shm');
    my $map = Data::HashMap::Shared::II->new($path, 100_000, 5, 1);  # max_size 5, ttl 1s
    $map->put($_, $_) for 1 .. 5;
    Time::HiRes::sleep(1.2);                                   # the whole map is now expired

    my $before = $map->stats;
    $map->put(6, 6);                           # needs a slot; the tail is expired
    my $after = $map->stats;

    is($after->{expired} - $before->{expired}, 1,
       'reclaiming an expired entry is billed as an expiry');
    is($after->{evictions} - $before->{evictions}, 0,
       '  ... and not as an eviction');
}

# Every entry recently read: an eviction spares 64 of them, then takes the next
# rather than walking the whole cache.
{
    my $map = Data::HashMap::Shared::II->new(undef, 1000, 200);
    $map->put($_, $_) for 1 .. 200;
    $map->get($_) for 1 .. 200;
    $map->put(201, 201);
    my @gone = grep { !$map->exists($_) } 1 .. 200;
    is("@gone", '65', 'an eviction spares 64 recently read entries, then takes the 65th');
}

{
    my $map = Data::HashMap::Shared::II->new(undef, 3000, 1000, 3600);
    $map->put_ttl($_, $_, 1) for 1 .. 1000;
    $map->get($_) for 1 .. 1000;
    Time::HiRes::sleep(2.1);
    $map->put($_, $_) for 1001 .. 2000;
    is(scalar(grep { $map->exists($_) } 1001 .. 2000), 1000,
        'eviction does not spare a read entry that has since expired');
    is($map->stats->{evictions}, 0, '  ... and evicts nothing live');
}

done_testing;
