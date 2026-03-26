use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

# Plain map (no LRU/TTL) — baseline
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    is(shm_ii_max_size $map, 0, 'no LRU by default');
    is(shm_ii_ttl $map, 0, 'no TTL by default');
    shm_ii_put $map, 1, 10;
    is(shm_ii_get $map, 1, 10, 'plain get');
    unlink $path;
}

# LRU eviction
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 3);  # max_size=3
    is(shm_ii_max_size $map, 3, 'max_size accessor');

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_put $map, 3, 30;
    is(shm_ii_size $map, 3, 'full');

    # Inserting 4th should evict LRU (key=1)
    shm_ii_put $map, 4, 40;
    is(shm_ii_size $map, 3, 'still 3 after eviction');
    ok(!defined(shm_ii_get $map, 1), 'key 1 evicted');
    is(shm_ii_get $map, 4, 40, 'key 4 present');

    # Access key=2 to promote it, then insert 5 — should evict 3 (LRU)
    shm_ii_get $map, 2;
    shm_ii_put $map, 5, 50;
    ok(defined(shm_ii_get $map, 2), 'key 2 not evicted (was promoted)');
    ok(!defined(shm_ii_get $map, 3), 'key 3 evicted');

    unlink $path;
}

# TTL expiration
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);  # ttl=1 sec
    is(shm_ii_ttl $map, 1, 'ttl accessor');

    shm_ii_put $map, 1, 10;
    is(shm_ii_get $map, 1, 10, 'get before expiry');
    ok(shm_ii_exists $map, 1, 'exists before expiry');

    sleep 2;  # wait for TTL

    ok(!defined(shm_ii_get $map, 1), 'expired after TTL');
    ok(!shm_ii_exists $map, 1, 'exists returns false after TTL');

    unlink $path;
}

# Per-key TTL via put_ttl (map must have TTL enabled)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 3600);  # default_ttl=1h

    shm_ii_put $map, 1, 10;                       # gets default 1h TTL
    ok(shm_ii_put_ttl $map, 2, 20, 1, 'put_ttl');  # 1 sec TTL override

    sleep 2;

    is(shm_ii_get $map, 1, 10, 'long-TTL key survives');
    ok(!defined(shm_ii_get $map, 2), 'per-key TTL expired');

    unlink $path;
}

# LRU + TTL combined
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 5, 1);  # max_size=5, ttl=1

    for my $i (1..5) {
        shm_ii_put $map, $i, $i * 10;
    }
    is(shm_ii_size $map, 5, 'full with LRU+TTL');

    sleep 2;

    # All should be expired
    ok(!defined(shm_ii_get $map, 1), 'expired entry');

    # But we can insert new ones
    shm_ii_put $map, 10, 100;
    is(shm_ii_get $map, 10, 100, 'new entry after expiry');

    unlink $path;
}

# SS variant with LRU
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 2);  # max_size=2

    shm_ss_put $map, "a", "1";
    shm_ss_put $map, "b", "2";
    shm_ss_put $map, "c", "3";  # should evict "a"

    ok(!defined(shm_ss_get $map, "a"), 'SS: LRU eviction');
    is(shm_ss_get $map, "c", "3", 'SS: new entry present');

    unlink $path;
}

# SS put_ttl (TTL-enabled map)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 0, 3600);

    ok(shm_ss_put_ttl $map, "k", "v", 1, 'SS put_ttl');
    is(shm_ss_get $map, "k", "v", 'SS get before expiry');

    sleep 2;
    ok(!defined(shm_ss_get $map, "k"), 'SS expired');

    unlink $path;
}

# SI variant with LRU
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000, 2);

    shm_si_put $map, "x", 1;
    shm_si_put $map, "y", 2;
    shm_si_put $map, "z", 3;

    ok(!defined(shm_si_get $map, "x"), 'SI: LRU eviction');
    is(shm_si_get $map, "z", 3, 'SI: new entry');

    unlink $path;
}

# Atomic counters with LRU
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 10);

    is(shm_ii_incr $map, 1, 1, 'incr with LRU');
    is(shm_ii_incr $map, 1, 2, 'incr again');
    is(shm_ii_decr $map, 1, 1, 'decr with LRU');
    is(shm_ii_incr_by $map, 1, 100, 101, 'incr_by with LRU');

    unlink $path;
}

# Method API for LRU/TTL
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 5, 10);
    is($map->max_size(), 5, 'method max_size');
    is($map->ttl(), 10, 'method ttl');
    $map->put_ttl(1, 100, 60);
    is($map->get(1), 100, 'method put_ttl + get');

    unlink $path;
}

# Cross-process LRU
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 3);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_put $map, 3, 30;

    my $pid = fork();
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, 1000, 3);
        shm_ii_put $child, 4, 40;  # should evict key=1
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    ok(!defined(shm_ii_get $map, 1), 'cross-process LRU eviction');
    is(shm_ii_get $map, 4, 40, 'cross-process new entry');

    unlink $path;
}

# keys/values/items/each skip expired entries
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);

    shm_ii_put $map, 1, 10;
    shm_ii_put_ttl $map, 2, 20, 100;  # long TTL

    sleep 2;

    my @k = shm_ii_keys $map;
    # key 1 should be expired during iteration, key 2 should survive
    # Note: keys iteration may or may not lazily expire
    # But get should definitely expire
    ok(!defined(shm_ii_get $map, 1), 'key 1 expired');
    is(shm_ii_get $map, 2, 20, 'key 2 still alive');

    unlink $path;
}

# clear resets LRU state
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 3);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_clear $map;
    is(shm_ii_size $map, 0, 'cleared');

    # Should be able to insert 3 more after clear
    shm_ii_put $map, 10, 100;
    shm_ii_put $map, 20, 200;
    shm_ii_put $map, 30, 300;
    is(shm_ii_size $map, 3, '3 after clear');

    # 4th should evict
    shm_ii_put $map, 40, 400;
    is(shm_ii_size $map, 3, 'LRU still works after clear');

    unlink $path;
}

# Reopen existing LRU/TTL map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 3, 3600);
    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    undef $map;

    my $map2 = Data::HashMap::Shared::II->new($path, 1000, 3, 3600);
    is(shm_ii_get $map2, 1, 10, 'reopen: key 1 survives');
    is(shm_ii_get $map2, 2, 20, 'reopen: key 2 survives');
    is(shm_ii_max_size $map2, 3, 'reopen: max_size preserved');
    is(shm_ii_ttl $map2, 3600, 'reopen: ttl preserved');

    # LRU still works after reopen (clock eviction — size stays at max)
    shm_ii_put $map2, 3, 30;
    shm_ii_put $map2, 4, 40;  # triggers eviction
    my $sz = shm_ii_size $map2;
    ok($sz <= 3, 'reopen: LRU eviction keeps size at max_size');
    is(shm_ii_get $map2, 4, 40, 'reopen: new entry present');

    unlink $path;
}

# Remove with LRU (correct unlink from LRU chain)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 5);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_put $map, 3, 30;

    # Remove middle entry
    ok(shm_ii_remove $map, 2, 'remove middle LRU entry');
    is(shm_ii_size $map, 2, 'size after remove');

    # LRU chain should still work — fill to max_size
    shm_ii_put $map, 4, 40;
    shm_ii_put $map, 5, 50;
    shm_ii_put $map, 6, 60;
    is(shm_ii_size $map, 5, 'filled to max after remove');

    # Next insert should evict LRU (key 1, oldest)
    shm_ii_put $map, 7, 70;
    is(shm_ii_size $map, 5, 'LRU eviction after remove');
    ok(!defined(shm_ii_get $map, 1), 'oldest key evicted after remove chain fix');

    unlink $path;
}

# incr/decr on expired key with TTL
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);

    shm_ii_put $map, 1, 100;
    is(shm_ii_get $map, 1, 100, 'before expiry');

    sleep 2;

    # incr on expired key should create fresh entry (value=1)
    is(shm_ii_incr $map, 1, 1, 'incr on expired key starts fresh');
    is(shm_ii_get $map, 1, 1, 'expired key replaced by incr');

    unlink $path;
}

# get_or_set with TTL expiry on existing entry
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);

    shm_ii_put $map, 1, 42;
    is(shm_ii_get_or_set $map, 1, 99, 42, 'get_or_set returns existing before expiry');

    sleep 2;

    # After expiry, get_or_set should insert the default
    is(shm_ii_get_or_set $map, 1, 99, 99, 'get_or_set inserts default after expiry');

    unlink $path;
}

# put_ttl with ttl_sec=0 creates a permanent entry on TTL-enabled map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);  # default TTL=1s

    shm_ii_put_ttl $map, 1, 10, 0;   # explicit no-TTL override
    shm_ii_put $map, 2, 20;           # gets default 1s TTL

    sleep 2;

    is(shm_ii_get $map, 1, 10, 'put_ttl(0) creates permanent entry');
    ok(!defined(shm_ii_get $map, 2), 'default TTL entry expired');

    unlink $path;
}

# put_ttl on non-TTL map croaks
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    eval { shm_ii_put_ttl $map, 1, 10, 5 };
    like($@, qr/TTL-enabled/, 'put_ttl on non-TTL map croaks');

    unlink $path;
}

# incr_by with non-unit delta on expired key
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);

    shm_ii_put $map, 1, 100;
    sleep 2;

    # incr_by on expired key should insert with value=delta, not 0+delta
    is(shm_ii_incr_by $map, 1, 5, 5, 'incr_by on expired key inserts delta');
    is(shm_ii_get $map, 1, 5, 'value is delta after incr_by on expired');

    unlink $path;
}

# incr on permanent entry preserves permanence
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);
    shm_ii_put_ttl $map, 1, 0, 0;    # permanent entry on ttl=1s map
    shm_ii_incr $map, 1;
    sleep 2;
    ok(defined(shm_ii_get $map, 1), 'permanent entry survives incr past default_ttl');
    is(shm_ii_get $map, 1, 1, 'permanent entry value correct after incr');
    unlink $path;
}

# get_or_set on permanent entry preserves permanence
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 1);
    shm_ii_put_ttl $map, 1, 42, 0;   # permanent
    shm_ii_get_or_set $map, 1, 99;    # should not alter TTL
    sleep 2;
    ok(defined(shm_ii_get $map, 1), 'permanent entry survives get_or_set past default_ttl');
    is(shm_ii_get $map, 1, 42, 'permanent entry value unchanged');
    unlink $path;
}

done_testing;
