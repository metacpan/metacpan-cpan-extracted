use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

# capacity and tombstones
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    ok((shm_ii_capacity $map) >= 16, 'initial capacity >= 16');
    is(shm_ii_tombstones $map, 0, 'no tombstones initially');

    shm_ii_put $map, $_, $_ * 10 for 1..100;
    ok((shm_ii_capacity $map) >= 100, 'capacity grew');

    shm_ii_remove $map, $_ for 1..10;
    ok((shm_ii_tombstones $map) > 0, 'tombstones after remove');
    is(shm_ii_size $map, 90, 'size after remove');

    # method API
    is($map->capacity(), shm_ii_capacity $map, 'method capacity');
    is($map->tombstones(), shm_ii_tombstones $map, 'method tombstones');

    unlink $path;
}

# ttl_remaining
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 60);

    shm_ii_put $map, 1, 10;  # default 60s TTL
    my $rem = shm_ii_ttl_remaining $map, 1;
    ok(defined $rem, 'ttl_remaining defined');
    ok($rem > 50 && $rem <= 60, "ttl_remaining in range: $rem") or diag("rem=$rem");

    shm_ii_put_ttl $map, 2, 20, 0;  # permanent
    is(shm_ii_ttl_remaining $map, 2, 0, 'permanent entry: ttl_remaining = 0');

    # non-existent key
    ok(!defined(shm_ii_ttl_remaining $map, 999), 'ttl_remaining undef for missing key');

    # method API
    is($map->ttl_remaining(1), shm_ii_ttl_remaining $map, 1, 'method ttl_remaining');

    unlink $path;
}

# ttl_remaining on non-TTL map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;
    ok(!defined(shm_ii_ttl_remaining $map, 1), 'ttl_remaining undef on non-TTL map');
    unlink $path;
}

# SS ttl_remaining
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 0, 30);
    shm_ss_put $map, "key", "val";
    my $rem = shm_ss_ttl_remaining $map, "key";
    ok($rem > 25 && $rem <= 30, "SS ttl_remaining in range: $rem") or diag("rem=$rem");
    ok(!defined(shm_ss_ttl_remaining $map, "nope"), 'SS ttl_remaining undef for missing');
    unlink $path;
}

# cursor_seek
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..20;

    my $cur = shm_ii_cursor $map;
    ok(shm_ii_cursor_seek $cur, 10, 'seek found key 10');

    my ($k, $v) = shm_ii_cursor_next $cur;
    is($k, 10, 'cursor_next after seek returns sought key');
    is($v, 100, 'cursor_next after seek returns correct value');

    # seek non-existent
    ok(!shm_ii_cursor_seek $cur, 999, 'seek returns false for missing key');

    # method API
    my $cur2 = $map->cursor();
    ok($cur2->seek(5), 'method cursor->seek');
    my ($k2, $v2) = $cur2->next();
    is($k2, 5, 'method next after seek');

    unlink $path;
}

# SS cursor_seek
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "alpha", "1";
    shm_ss_put $map, "beta", "2";
    shm_ss_put $map, "gamma", "3";

    my $cur = shm_ss_cursor $map;
    ok(shm_ss_cursor_seek $cur, "beta", 'SS seek');
    my ($k, $v) = shm_ss_cursor_next $cur;
    is($k, "beta", 'SS cursor_next after seek');
    is($v, "2", 'SS correct value after seek');

    unlink $path;
}

# Sharded cursor_seek (exercises the target != c->current branch where
# v0.09 added the iter_pos/gen reset for the target shard).
{
    my $prefix = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($prefix, 4, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..50;

    my $cur = shm_ii_cursor $map;
    # Advance the cursor at least once so iter_pos/shard_idx are non-default.
    my ($k0, $v0) = shm_ii_cursor_next $cur;
    ok(defined $k0, 'sharded cursor advanced before seek');

    # Seek a key that exists (very likely on a different shard).
    ok((shm_ii_cursor_seek $cur, 42), 'sharded cursor_seek found key 42');
    my ($k, $v) = shm_ii_cursor_next $cur;
    is($k, 42, 'cursor_next after sharded seek returns sought key');
    is($v, 420, 'cursor_next after sharded seek returns correct value');

    # Seek a key that doesn't exist (covers iter_pos reset path).
    ok(!(shm_ii_cursor_seek $cur, 99999), 'sharded seek missing key returns false');
    # cursor_next must still return forward entries (not crash, not stall).
    my $more = 0;
    while (my ($k2, $v2) = shm_ii_cursor_next $cur) { $more++ }
    cmp_ok($more, '>=', 0, 'cursor_next after sharded seek-miss completes without stall');

    unlink glob "$prefix*";
}

# Sharded stats/accessors report aggregate totals across all shards
# (regression guard: max_entries/max_size/mmap_size must sum the shards, not
# report shard 0 only -- otherwise size/max_entries load factor is wrong).
{
    my $shards = 4;
    # reference single shard with identical per-shard parameters
    my $sp = tmpfile();
    # max_size high enough that the 200 puts below never evict (tests size
    # aggregation), but nonzero so max_size aggregation is meaningful.
    my $single = Data::HashMap::Shared::II->new($sp, 1000, 1000);  # max_entries, max_size
    my $s_me = shm_ii_max_entries $single;
    my $s_ms = shm_ii_max_size $single;
    my $s_mm = shm_ii_mmap_size $single;
    unlink $sp;

    my $prefix = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($prefix, $shards, 1000, 1000);
    is(shm_ii_max_entries $map, $shards * $s_me, 'sharded max_entries sums across shards');
    is(shm_ii_max_size $map,    $shards * $s_ms, 'sharded max_size sums across shards');
    is(shm_ii_mmap_size $map,   $shards * $s_mm, 'sharded mmap_size sums across shards');

    shm_ii_put $map, $_, $_ for 1..200;
    is(shm_ii_size $map, 200, 'sharded size counts all shards');

    my $st = $map->stats;
    is($st->{max_entries}, $shards * $s_me, 'stats max_entries aggregate matches accessor');
    is($st->{mmap_size},   $shards * $s_mm, 'stats mmap_size aggregate matches accessor');
    is($st->{size}, 200, 'stats size aggregate');

    unlink glob "$prefix*";
}

# cursor_seek with TTL expired key
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);
    shm_ii_put $map, 1, 10;
    sleep 4;
    my $cur = shm_ii_cursor $map;
    ok(!shm_ii_cursor_seek $cur, 1, 'seek expired key returns false');
    unlink $path;
}

done_testing;
