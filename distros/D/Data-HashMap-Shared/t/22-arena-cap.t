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
my $big = "x" x 50_000;

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4);
    is($m->arena_cap, 4096, 'default arena_cap floors at 4096 for a tiny max_entries');
    ok(!$m->put("k", $big), 'default arena rejects a 50KB value (the motivating incident)');
    unlink $p;
}

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 1 << 20);
    is($m->arena_cap, 1 << 20, 'explicit arena_cap is honored');
    ok($m->put("k",  $big), 'large value stored with an explicit arena');
    is(length($m->get("k")), 50_000, '  ...and reads back intact');
    ok($m->put("k2", $big), 'a second large value fits too');
    unlink $p;
}

{
    my $p = tmp();
    { my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 1 << 20); $m->put("k", $big); }
    my $r = Data::HashMap::Shared::SS->new($p, 1);
    is($r->arena_cap, 1 << 20, 'reopen keeps the stored arena_cap (ctor arg ignored)');
    is(length($r->get("k")), 50_000, 'large value survives reopen');
    my $r2 = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 999);
    is($r2->arena_cap, 1 << 20, 'reopen ignores a differing arena_cap arg too');
    unlink $p;
}

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 100);
    is($m->arena_cap, 4096, 'arena_cap below the floor clamps up to 4096');
    unlink $p;
}

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::II->new($p, 100, 0, 0, 0, 1 << 20);
    is($m->arena_cap, 0, 'int-only variant has no arena; arena_cap arg ignored (0)');
    $m->put(1, 42); $m->incr_by(2, 9);
    is($m->get(1), 42, 'int-only map works normally with an arena_cap arg present');
    unlink $p;
}

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::IS->new($p, 4, 0, 0, 0, 1 << 20);
    ok($m->put(1, $big), 'IS (string value) honors explicit arena_cap');
    is(length($m->get(1)), 50_000, '  ...value intact');
    unlink $p;
}

{
    my $prefix = tmp();
    my $shards = 4;
    my $m = Data::HashMap::Shared::SS->new_sharded($prefix, $shards, 4, 0, 0, 0, 1 << 20);
    is($m->arena_cap, $shards * (1 << 20), 'sharded arena_cap aggregates the per-shard caps');
    ok($m->put("k", $big), 'large value stored in a sharded map with a per-shard arena');
    is(length($m->get("k")), 50_000, '  ...and reads back intact');
    unlink glob "$prefix*";
}

{
    my $m = Data::HashMap::Shared::SS->new_memfd("dhm_arena_test", 4, 0, 0, 0, 1 << 20);
    is($m->arena_cap, 1 << 20, 'new_memfd honors explicit arena_cap');
    ok($m->put("k", $big), 'large value stored in a memfd-backed map');
    is(length($m->get("k")), 50_000, '  ...value intact');
}

{
    my $bigkey = "k" x 20_000;
    my $p = tmp();
    my $d = Data::HashMap::Shared::SI->new($p, 4);
    ok(!$d->put($bigkey, 1), 'SI: default arena rejects a 20KB key');
    unlink $p;

    my $p2 = tmp();
    my $m = Data::HashMap::Shared::SI->new($p2, 4, 0, 0, 0, 1 << 20);
    ok($m->put($bigkey, 42), 'SI: explicit arena_cap stores a 20KB key');
    is($m->get($bigkey), 42, '  ...and looks it up');
    unlink $p2;
}

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 1000, 0, 0, 0, 4096);
    my $val = "v" x 1000;
    my $stored = 0;
    for my $i (1 .. 100) { $m->put("k$i", $val) ? $stored++ : last }
    cmp_ok($stored, '>', 0,   'arena-full: some values stored before exhaustion');
    cmp_ok($stored, '<', 100, 'arena-full: put returns false once the arena is exhausted (graceful)');
    is($m->get("k1"), $val,   'arena-full: earlier entries remain intact');
    unlink $p;
}

{
    my $p = tmp();
    my $m = Data::HashMap::Shared::SS->new($p, 4, 0, 0, 0, 0);
    is($m->arena_cap, 4096, 'explicit arena_cap=0 falls back to the default');
    unlink $p;
}

done_testing;
