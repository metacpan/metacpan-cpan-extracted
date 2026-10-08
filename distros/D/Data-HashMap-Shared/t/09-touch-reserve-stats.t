use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 10);

    shm_ii_put_ttl $map, 1, 10, 3;
    cmp_ok($map->ttl_remaining(1), '<=', 3, 'entry starts on its own short TTL');

    ok(shm_ii_touch $map, 1, 'touch returns true for existing key');

    cmp_ok($map->ttl_remaining(1), '>=', 9, 'touch reset the TTL to the map default');

    ok(!shm_ii_touch $map, 999, 'touch returns false for missing key');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 3);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_put $map, 3, 30;

    shm_ii_touch $map, 1;

    shm_ii_put $map, 4, 40;
    ok(!defined(shm_ii_get $map, 2), 'LRU evicted key 2 after touch promoted key 1');
    is(shm_ii_get $map, 1, 10, 'touched key 1 survived eviction');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 10);
    shm_ii_put_ttl $map, 1, 10, 100;
    my $before = shm_ii_ttl_remaining $map, 1;
    ok($before > 50, "per-key TTL set (before touch): $before");
    shm_ii_touch $map, 1;
    my $after = shm_ii_ttl_remaining $map, 1;
    ok($after <= 10, "touch resets to default TTL: $after");
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 10);
    shm_ii_put_ttl $map, 1, 10, 0;
    my $before = shm_ii_ttl_remaining $map, 1;
    is($before, 0, 'permanent entry has ttl_remaining=0');
    shm_ii_touch $map, 1;
    my $after = shm_ii_ttl_remaining $map, 1;
    is($after, 0, 'touch does not change permanent entry TTL');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;
    ok(!shm_ii_touch $map, 1, 'touch returns false on plain map (no-op)');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);
    shm_ii_put $map, 1, 10;
    Time::HiRes::sleep(1.2);
    ok(!shm_ii_touch $map, 1, 'touch returns false for expired key');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 0, 3);
    shm_ss_put $map, "hello", "world";
    ok(shm_ss_touch $map, "hello", 'SS touch');
    ok(!shm_ss_touch $map, "nope", 'SS touch missing');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000, 0, 3);
    shm_si_put $map, "key", 42;
    ok(shm_si_touch $map, "key", 'SI touch');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 10);
    shm_ii_put $map, 1, 10;
    ok($map->touch(1), 'method touch');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100000);

    my $cap_before = shm_ii_capacity $map;
    ok(shm_ii_reserve $map, 1000, 'reserve returns true');
    my $cap_after = shm_ii_capacity $map;
    ok($cap_after >= 1000, "capacity after reserve >= 1000: $cap_after");
    ok($cap_after > $cap_before, "capacity grew: $cap_before -> $cap_after");

    ok(shm_ii_reserve $map, 10, 'reserve smaller is no-op');
    is(shm_ii_capacity $map, $cap_after, 'capacity unchanged after smaller reserve');

    shm_ii_put $map, $_, $_ for 1..1000;
    is(shm_ii_capacity $map, $cap_after, 'no resize after pre-reserved inserts');

    ok($map->reserve(2000), 'method reserve');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    ok(!(shm_ii_reserve $map, 500), 'reserve beyond max_table_cap returns false');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 100000);
    ok(shm_ss_reserve $map, 500, 'SS reserve');
    ok((shm_ss_capacity $map) >= 500, 'SS capacity after reserve');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 5);

    is(shm_ii_stat_evictions $map, 0, 'no evictions initially');

    shm_ii_put $map, $_, $_ * 10 for 1..5;
    is(shm_ii_stat_evictions $map, 0, 'no evictions at capacity');

    shm_ii_put $map, 6, 60;
    is(shm_ii_stat_evictions $map, 1, '1 eviction after exceeding LRU capacity');

    shm_ii_put $map, 7, 70;
    shm_ii_put $map, 8, 80;
    is(shm_ii_stat_evictions $map, 3, '3 total evictions');

    is($map->stat_evictions(), 3, 'method stat_evictions');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);

    is(shm_ii_stat_expired $map, 0, 'no expirations initially');

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    Time::HiRes::sleep(1.2);

    my $v = shm_ii_get $map, 1;
    ok(!defined $v, 'get returns undef for expired entry');

    shm_ii_flush_expired $map;
    is(shm_ii_stat_expired $map, 2, '2 total after flush');

    is($map->stat_expired(), 2, 'method stat_expired');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 3);

    shm_ii_put $map, $_, $_ for 1..3;
    shm_ii_put $map, 4, 40;
    is(shm_ii_stat_evictions $map, 1, 'eviction before clear');

    shm_ii_clear $map;
    is(shm_ii_stat_evictions $map, 1, 'eviction count survives clear');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;
    is(shm_ii_stat_evictions $map, 0, 'stat_evictions 0 on plain map');
    is(shm_ii_stat_expired $map, 0, 'stat_expired 0 on plain map');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 2);

    shm_ss_put $map, "a", "1";
    shm_ss_put $map, "b", "2";
    shm_ss_put $map, "c", "3";
    is(shm_ss_stat_evictions $map, 1, 'SS stat_evictions');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    is($map->path, $path, 'II path returns backing file path');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    is($map->path, $path, 'SS path returns backing file path');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000);
    is($map->path, $path, 'SI path returns backing file path');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 30);

    $map->put_ttl(2, 100, 5);
    $map->swap(2, 200);
    my (undef, $t) = $map->get_with_ttl(2);
    ok(defined $t && $t > 10, "swap refreshes an existing entry's TTL to default (got @{[$t // 'undef']})");

    $map->put_ttl(1, 100, 0);
    $map->swap(1, 200);
    my (undef, $tp) = $map->get_with_ttl(1);
    is($tp, 0, 'swap leaves a permanent entry permanent');
    unlink $path;
}

done_testing;
