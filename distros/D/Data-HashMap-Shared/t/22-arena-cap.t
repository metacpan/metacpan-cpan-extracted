use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::II;

sub tmp { File::Temp::tempnam(File::Spec->tmpdir, 'shm_arena') . '.shm' }

# ctor: new($path, $max_entries, $max_size, $ttl, $lru_skip, $arena_cap)
my $big = "x" x 50_000;   # 50 KB value — far larger than a small map's default arena

# ---- the motivating problem: default arena is sized from max_entries ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4);   # arena = max(4*128, 4096) = 4096
    is($m->arena_cap, 4096, 'default arena_cap floors at 4096 for a tiny max_entries');
    ok(!$m->put("k", $big), 'default arena rejects a 50KB value (the motivating incident)');
    unlink $p;
}

# ---- explicit arena_cap decouples string storage from entry count ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 1 << 20);  # 1 MB arena, 4-entry table
    is($m->arena_cap, 1 << 20, 'explicit arena_cap is honored');
    ok($m->put("k",  $big), 'large value stored with an explicit arena');
    is(length($m->get("k")), 50_000, '  ...and reads back intact');
    ok($m->put("k2", $big), 'a second large value fits too');
    unlink $p;
}

# ---- reopen ignores the arg; the stored arena_cap wins ----
{
    my $p = tmp();
    { my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 1 << 20); $m->put("k", $big); }
    my $r = Data::HashMap::Shared::SS->new($p, 1);          # no arena_cap arg
    is($r->arena_cap, 1 << 20, 'reopen keeps the stored arena_cap (ctor arg ignored)');
    is(length($r->get("k")), 50_000, 'large value survives reopen');
    my $r2 = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 999);  # different arg, still ignored
    is($r2->arena_cap, 1 << 20, 'reopen ignores a differing arena_cap arg too');
    unlink $p;
}

# ---- clamp: floor 4096 ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 100);  # below the floor
    is($m->arena_cap, 4096, 'arena_cap below the floor clamps up to 4096');
    unlink $p;
}

# ---- int-only variant: arena_cap arg is a harmless no-op (no arena) ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::II->new($p, 100, 0, 0, 0, 1 << 20);
    is($m->arena_cap, 0, 'int-only variant has no arena; arena_cap arg ignored (0)');
    $m->put(1, 42); $m->incr_by(2, 9);
    is($m->get(1), 42, 'int-only map works normally with an arena_cap arg present');
    unlink $p;
}

# ---- string VALUE side (IS: int key, string value) honors arena_cap ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::IS->new($p, 4, 0, 0, 0, 1 << 20);
    ok($m->put(1, $big), 'IS (string value) honors explicit arena_cap');
    is(length($m->get(1)), 50_000, '  ...value intact');
    unlink $p;
}

# ---- sharded: arena_cap is per-shard (aggregate = shards * cap) ----
{
    my $prefix = tmp();
    my $shards = 4;
    my $m = Data::HashMap::Shared::SS->new_sharded($prefix, $shards, 4, 0, 0, 0, 1 << 20);
    is($m->arena_cap, $shards * (1 << 20), 'sharded arena_cap aggregates the per-shard caps');
    ok($m->put("k", $big), 'large value stored in a sharded map with a per-shard arena');
    is(length($m->get("k")), 50_000, '  ...and reads back intact');
    unlink glob "$prefix*";
}

# ---- new_memfd honors arena_cap ----
{
    my $m = Data::HashMap::Shared::SS->new_memfd("dhm_arena_test", 4, 0, 0, 0, 1 << 20);
    is($m->arena_cap, 1 << 20, 'new_memfd honors explicit arena_cap');
    ok($m->put("k", $big), 'large value stored in a memfd-backed map');
    is(length($m->get("k")), 50_000, '  ...value intact');
}

# ---- string-KEY variants (SI) keep keys in the arena, so arena_cap governs
# large keys the same way it governs large values ----
{
    my $bigkey = "k" x 20_000;   # 20 KB key (well past the inline threshold -> arena)
    my $p = tmp();
    my $d = Data::HashMap::Shared::SI->new($p, 4);              # default arena 4096
    ok(!$d->put($bigkey, 1), 'SI: default arena rejects a 20KB key');
    unlink $p;

    my $p2 = tmp();
    my $m = Data::HashMap::Shared::SI->new($p2, 4, 0, 0, 0, 1 << 20);
    ok($m->put($bigkey, 42), 'SI: explicit arena_cap stores a 20KB key');
    is($m->get($bigkey), 42, '  ...and looks it up');
    unlink $p2;
}

# ---- a too-small custom arena fails gracefully (put returns false, no crash),
# leaving earlier entries intact ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 1000, 0, 0, 0, 4096);  # roomy table, tiny 4KB arena
    my $val = "v" x 1000;   # ~1KB each -> only a few fit in 4KB
    my $stored = 0;
    for my $i (1 .. 100) { $m->put("k$i", $val) ? $stored++ : last }
    cmp_ok($stored, '>', 0,   'arena-full: some values stored before exhaustion');
    cmp_ok($stored, '<', 100, 'arena-full: put returns false once the arena is exhausted (graceful)');
    is($m->get("k1"), $val,   'arena-full: earlier entries remain intact');
    unlink $p;
}

# ---- explicit arena_cap => 0 is identical to omitting it (default sizing) ----
{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 0);
    is($m->arena_cap, 4096, 'explicit arena_cap=0 falls back to the default');
    unlink $p;
}

done_testing;
