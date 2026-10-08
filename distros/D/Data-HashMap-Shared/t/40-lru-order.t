use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;

# The LRU tests elsewhere assert how many entries survive; these pin which one
# is evicted (a wrong victim leaves the count correct).

my $dir = File::Temp::tempdir(CLEANUP => 1);

{
    my $path = File::Spec->catfile($dir, 'order.shm');
    my $map = Data::HashMap::Shared::II->new($path, 100_000, 100);
    $map->put($_, $_) for 1 .. 100;
    is($map->size, 100, 'filled to max_size');

    my $before = $map->capacity;
    $map->reserve(20_000);                        # rebuilds the recency chain
    cmp_ok($map->capacity, '>', $before, 'reserve grew the table');
    is($map->size, 100, '  ... without losing entries');

    $map->put(101, 101);
    is($map->stats->{evictions}, 1, 'inserting past max_size evicted exactly one');
    ok(!defined($map->get(1)),   'the coldest entry was evicted after a resize');
    ok(defined($map->get(100)),  '  ... and the hottest was kept');
    ok(defined($map->get(101)),  '  ... and the new entry is present');
}

{
    my $path = File::Spec->catfile($dir, 'skip.shm');
    # lru_skip 90 skips nine promotions in ten, but never the tail's: otherwise
    # refreshing it could not save it
    my $map = Data::HashMap::Shared::II->new($path, 100_000, 50, 0, 90);
    $map->put($_, $_) for 1 .. 50;
    is($map->size, 50, 'filled to max_size with lru_skip=90');

    $map->touch(1);              # key 1 is the tail
    $map->put(51, 51);

    ok(defined($map->get(1)),  'a touched tail entry survives with lru_skip set');
    ok(!defined($map->get(2)), '  ... and the entry behind it was evicted instead');
}


{
    my $path = File::Spec->catfile($dir, 'stats.shm');
    my $map = Data::HashMap::Shared::II->new($path, 100_000, 5, 1);  # max_size 5, ttl 1s
    $map->put($_, $_) for 1 .. 5;
    Time::HiRes::sleep(1.2);

    my $before = $map->stats;
    $map->put(6, 6);
    my $after = $map->stats;

    is($after->{expired} - $before->{expired}, 1,
       'reclaiming an expired entry is billed as an expiry');
    is($after->{evictions} - $before->{evictions}, 0,
       '  ... and not as an eviction');
}

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
