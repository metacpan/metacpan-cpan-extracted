use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SS;

# An insert probe cannot tell an expired entry from a live one (both are
# SHM_IS_LIVE), so a table full of expired entries must still accept an insert.

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

# long default TTL: only the fillers expire, not the key a case inserts
# afterwards
sub filled_to_capacity {
    my $m = Data::HashMap::Shared::SI->new("$dir/x" . $seq++ . ".shm", 8, 0, 3600);
    $m->put_ttl("old-$_", $_, 1) for 1 .. $m->capacity;
    is $m->size, $m->capacity, "table filled to capacity (" . $m->capacity . ")";
    return $m;
}

# one TTL wait shared by all six maps
my @cases = (
    [ put        => sub { $_[0]->put($_[1], 1) } ],
    [ add        => sub { $_[0]->add($_[1], 1) } ],
    [ swap       => sub { $_[0]->swap($_[1], 1); $_[0]->exists($_[1]) } ],
    [ incr       => sub { eval { $_[0]->incr($_[1]) } } ],
    [ max        => sub { eval { $_[0]->max($_[1], 5) } } ],
    [ get_or_set => sub { defined $_[0]->get_or_set($_[1], 7) } ],
);
my @maps = map { filled_to_capacity() } @cases;
Time::HiRes::sleep(1.2);
for my $i (0 .. $#cases) {
    my ($name, $code) = @{ $cases[$i] };
    my $m = $maps[$i];
    my @live = $m->keys;
    is scalar @live, 0, "$name: every entry has expired";
    ok $code->($m, 'fresh'), "$name reclaims an expired slot instead of failing";
    ok $m->exists('fresh'), "  ... and the new key is really there";
}

{
    my $m = Data::HashMap::Shared::SI->new("$dir/live.shm", 8, 0, 900);
    $m->put("live-$_", $_) for 1 .. $m->capacity;
    ok !$m->put('overflow', 1), 'a table full of LIVE entries still refuses';
    is $m->size, $m->capacity, '  ... and nothing was evicted to make room';
}

{
    my $m = Data::HashMap::Shared::II->new("$dir/perm.shm", 8, 0, 1);
    $m->put_ttl(999, 42, 0);
    $m->put($_, $_) for 1 .. $m->capacity - 1;
    Time::HiRes::sleep(1.2);
    $m->put(1000 + $_, $_) for 1 .. 2 * $m->capacity;
    is $m->get(999), 42, 'a permanent entry survives repeated reclaim';
}

{
    my $m = Data::HashMap::Shared::SI->new("$dir/stat.shm", 8, 0, 1);
    $m->put("e$_", $_) for 1 .. $m->capacity;
    Time::HiRes::sleep(1.2);
    is $m->stats->{expired}, 0, 'nothing counted as expired before the reclaim';
    $m->put('trigger', 1);
    cmp_ok $m->stats->{expired}, '>', 0, 'the reclaimed entry is counted in stats';
}

{
    my $m = Data::HashMap::Shared::SI->new("$dir/whole.shm", 8, 0, 1);
    $m->put("e$_", $_) for 1 .. $m->capacity;
    Time::HiRes::sleep(1.2);
    ok $m->put('fresh', 1), 'an insert into a table of expired entries succeeds';
    is $m->size, 1, '  ... having flushed every expired entry, not only the slot it took';
    is $m->stats->{expired}, $m->capacity, '  ... all of them billed as expired';

    my $p = Data::HashMap::Shared::SI->new("$dir/part.shm", 8, 0, 3600);
    $p->put_ttl("x$_", $_, 1) for 1 .. 5;
    $p->put("live$_", $_) for 6 .. $p->capacity;
    Time::HiRes::sleep(1.2);
    ok $p->put('fresh', 1), 'an insert into a full table holding five expired entries succeeds';
    is $p->size, $p->capacity - 4, '  ... flushing exactly the five';
    is $p->stats->{expired}, 5, '  ... billed as expired';
}

# the insert that crosses the design load must flush expired entries first: a
# partial flush leaves free slots, so "no free slot" may never come
{
    # TTL 2, not 1: a 1s TTL can expire mid-fill at a clock tick and be flushed
    # before the table reaches its load
    my $top = Data::HashMap::Shared::SI->new("$dir/top.shm", 1000, 0, 3600);
    $top->put_ttl("old-$_", $_, 2) for 1 .. $top->max_entries;
    my $mid = Data::HashMap::Shared::SI->new("$dir/mid.shm", 10_000, 0, 3600);
    $mid->put_ttl("old-$_", $_, 2) for 1 .. 700;
    my $cap = $mid->capacity;
    Time::HiRes::sleep(2.2);

    $top->put("new-$_", $_) for 1 .. 20;
    cmp_ok $top->size, '<=', 20, 'at the largest table: the expired entries are flushed';
    cmp_ok $top->stats->{expired}, '>=', $top->max_entries, '  ... all of them';

    $mid->put("new-$_", $_) for 1 .. 100;
    cmp_ok $mid->size, '<=', 100, 'below it: the expired entries are flushed';
    is $mid->capacity, $cap, "  ... and the table stays at $cap slots rather than growing";
}


{
    my $c = Data::HashMap::Shared::SS->new("$dir/arena.shm", 1000, 500);
    my $v = 'x' x 400;                       # default arena is ~128 KB
    my ($ok, $fail) = (0, 0);
    for my $i (1 .. 2000) { $c->put("key$i", $v) ? $ok++ : $fail++ }
    is $fail, 0, 'an LRU cache keeps accepting once the arena is full';
    cmp_ok $c->stats->{evictions}, '>', 0, '  ... by evicting';
    ok defined $c->get('key2000'), '  ... the newest key is present';
    ok !defined $c->get('key1'),   '  ... and the oldest was evicted';
}

{
    my $p = Data::HashMap::Shared::SS->new("$dir/noarena.shm", 1000, 0, 0, 0, 4096);
    my $fail = 0;
    for my $i (1 .. 200) { $p->put("k$i", 'y' x 400) or $fail++ }
    cmp_ok $fail, '>', 0, 'a non-LRU map with a full arena still refuses';
    is $p->stats->{evictions}, 0, '  ... and evicts nothing';
}


{
    my $V = 'x' x 400;
    my $seq2 = 0;
    my $full_arena = sub {
        # a small explicit arena leaves no slack: the default one leaves free
        # blocks behind, so a following insert would fit without evicting
        my $m = Data::HashMap::Shared::SS->new("$dir/ae" . $seq2++ . ".shm", 1000, 500, 0, 0, 8192);
        my $n = 0;
        while ($m->put("fill-$n", $V)) { last if ++$n > 500 }
        return $m;
    };
    for my $case (
        [ put        => sub { $_[0]->put($_[1], $V) } ],
        [ add        => sub { $_[0]->add($_[1], $V) } ],
        [ swap       => sub { $_[0]->swap($_[1], $V); $_[0]->exists($_[1]) } ],
        [ get_or_set => sub { defined $_[0]->get_or_set($_[1], $V) } ],
    ) {
        my ($name, $code) = @$case;
        ok $code->($full_arena->(), 'fresh'), "$name evicts when the arena is exhausted";
    }

    # string keys need arena space too, and the counters croak rather than
    # return false
    my $counters = sub {
        my $m = Data::HashMap::Shared::SI->new("$dir/ac" . $seq2++ . ".shm", 1000, 500, 0, 0, 8192);
        my $n = 0;
        while ($m->put('k' x 200 . "-$n", $n)) { last if ++$n > 5000 }
        return $m;
    };
    ok eval { $counters->()->incr('y' x 200 . '-new'); 1 },
        'incr evicts rather than croaking when the arena is exhausted';
    ok eval { $counters->()->max('z' x 200 . '-new', 5); 1 },
        'max evicts rather than croaking when the arena is exhausted';

    my $p = Data::HashMap::Shared::SS->new("$dir/noevict.shm", 1000, 0, 0, 0, 8192);
    my $n = 0;
    while ($p->put("f$n", $V)) { last if ++$n > 500 }
    ok !$p->add('a', $V), 'without LRU, add still refuses';
    $p->swap('b', $V);
    ok !$p->exists('b'),  '  ... swap too';
    ok !defined $p->get_or_set('c', $V), '  ... and get_or_set';
    is $p->stats->{evictions}, 0, '  ... having evicted nothing';
}


# arena blocks are exact size classes and never coalesce: no number of evictions
# makes a request larger than the whole arena fit
{
    my $m = Data::HashMap::Shared::SS->new("$dir/oversize.shm", 1000, 500, 0, 0, 8192);
    my $n = 0;
    while ($m->put("f-$n", 'x' x 400)) { last if ++$n > 500 }
    my $before     = $m->stats->{evictions};
    my $size_before = $m->size;
    cmp_ok $size_before, '>', 0, 'the cache holds entries before the oversize insert';

    ok !$m->put('huge', 'y' x 100_000), 'an insert larger than the arena is refused';
    is $m->stats->{evictions} - $before, 0, '  ... without evicting anything';
    is $m->size, $size_before, '  ... leaving the cache intact';

    ok $m->put('normal', 'z' x 400), 'a fitting insert still evicts and succeeds';
}


# a request that fits the arena but matches no size class the eviction frees is
# equally unsatisfiable
{
    my $seq3 = 0;
    my $cache = sub {                       # 15 entries of 200B in a 4096B arena
        my $m = Data::HashMap::Shared::SS->new("$dir/gd" . $seq3++ . ".shm", 1000, 500, 0, 0, 4096);
        my $n = 0;
        while ($m->put("k$n", 'x' x 200)) { last if ++$n > 100 }
        return $m;
    };
    for my $case ([200, 'satisfiable'], [400, 'wrong size class'], [900, 'wrong size class']) {
        my ($len, $why) = @$case;
        my $m = $cache->();
        my ($size, $ev) = ($m->size, $m->stats->{evictions});
        my $ok = $m->put('new', 'y' x $len);
        cmp_ok $m->stats->{evictions} - $ev, '<=', 1,
            "a ${len}B insert ($why) evicts at most one entry";
        cmp_ok $size - $m->size, '<=', 1, "  ... and costs at most one entry";
        ok $ok, "  ... and a ${len}B insert succeeds" if $len == 200;
    }

    my $m = $cache->();
    my ($size, $ev) = ($m->size, $m->stats->{evictions});
    $m->put('z' x 300, 'y' x 5000);
    cmp_ok $size - $m->size, '<=', 1, 'a long key with an oversize value costs at most one entry';

    # a class smaller than every block present: blocks are never split and this
    # arena is tiled exactly by eight 1024-byte blocks, so only compaction can
    # serve it
    my $s = Data::HashMap::Shared::SS->new("$dir/small.shm", 1000, 900, 0, 0, 16 + 8 * 1024);
    my $j = 0;
    while ($s->put("b$j", 'b' x 1000)) { last if ++$j > 40 }
    my ($ev2, $used2) = ($s->stats->{evictions}, $s->arena_used);
    ok !$s->put('s1', 'a' x 100), 'a request in a class no entry holds fails the first time';
    is $s->stats->{evictions} - $ev2, 1, '  ... having evicted one entry blindly';
    ok $s->put('s2', 'a' x 100), '  ... and the next insert compacts that block free and fits';
    cmp_ok $s->arena_used, '<', $used2, '  ... which is the reclaim, visible in arena_used';
    ok $s->put('s3', 'a' x 100), '  ... as do further inserts of the same class';
    is $s->stats->{evictions} - $ev2, 1, '  ... without evicting a second time';
    is $s->get('s2'), 'a' x 100, '  ... storing the value intact';
    my $larges = grep { ($s->get("b$_") // '') eq 'b' x 1000 } 0 .. 40;
    my $smalls = grep { ($s->get("s$_") // '') eq 'a' x 100 } 1 .. 3;
    is $larges + $smalls, $s->size, '  ... and every entry present reads back its own value';

    my $two = Data::HashMap::Shared::SS->new("$dir/two.shm", 1000, 500, 0, 0, 4096);
    my $t = 0;
    while ($two->put("k$t", 'x' x 200)) { last if ++$t > 100 }
    my ($sz, $ev3) = ($two->size, $two->stats->{evictions});
    ok !$two->put('K' x 200, 'y' x 900), 'a 256-class key with a 1024-class value is refused';
    is $two->stats->{evictions} - $ev3, 2, '  ... after evicting twice, once for each store';
    is $sz - $two->size, 2, '  ... costing two entries';
    $ev3 = $two->stats->{evictions};
    my $free = 0;
    for (1 .. 4) { last unless $two->put("z$_", 'x' x 200) && $two->stats->{evictions} == $ev3; $free++ }
    is $free, 2, '  ... and the two freed blocks, the key block among them, serve the next inserts';
}


# among the 32 oldest entries the victim is the oldest holding a block of the
# request's class; if none does, the tail is evicted blindly
{
    my $fixture = sub {                 # $n class-256 entries, one class-4096 entry,
        my ($n) = @_;                   # then class-256 fillers up to exactly the arena
        my $w = Data::HashMap::Shared::SS->new("$dir/win$n.shm", 1000, 900, 0, 0, 65536);
        $w->put("b$_", 'b' x 200) for 1 .. $n;
        $w->put('A', 'A' x 3000);
        $w->put("c$_", 'c' x 200) for 1 .. int((65536 - 16 - 256 * $n - 4096) / 256);
        return $w;
    };
    my $w = $fixture->(20);
    my ($size, $ev) = ($w->size, $w->stats->{evictions});
    ok $w->put('Z', 'Z' x 3000), 'a 4096-class request evicts the one 4096-class entry among the oldest 32';
    ok !defined $w->get('A'), '  ... which was the twenty-first oldest, not the tail';
    is $w->stats->{evictions} - $ev, 1, '  ... at one eviction';
    is $w->size, $size, '  ... leaving the size unchanged';

    $w = $fixture->(40);
    ($size, $ev) = ($w->size, $w->stats->{evictions});
    ok !$w->put('Z', 'Z' x 3000), 'the same request fails when that entry is the forty-first oldest';
    ok defined $w->get('A'), '  ... which survives beyond the search window';
    is $w->stats->{evictions} - $ev, 1, '  ... after one blind eviction';
    is $w->size, $size - 1, '  ... costing one entry';
}

# long strings fill the arena before the table: a refused store flushes expired
# entries as a missing slot does, sparing the entry an overwrite replaces
{
    my $long = sub { sprintf '%0100d', $_[0] };
    my $si = Data::HashMap::Shared::SI->new(undef, 1000, 0, 2);
    my $n = 0;
    $n++ while $n < 5000 && $si->put($long->($n), 1);
    cmp_ok $n, '<', $si->capacity, 'long keys fill the arena before the table';
    my $is = Data::HashMap::Shared::IS->new(undef, 1000, 0, 2);
    my $m = 0;
    $m++ while $m < 5000 && $is->put($m, $long->($m));
    my $ss = Data::HashMap::Shared::SS->new(undef, 64, 0, 2);
    my $s = 0;
    $s++ while $s < 5000 && $ss->put("k$s", $long->($s));
    Time::HiRes::sleep(3.1);
    is scalar(grep { $si->put($long->(900_000 + $_), 1) } 1 .. 5), 5,
        'a new long key is stored once the arena holds only expired ones';
    is scalar(grep { $is->put(900_000 + $_, $long->($_)) } 1 .. 5), 5, '  ... and a new long value';
    ok $ss->put('k0', 'y' x 100), 'an overwrite of an expired entry on a full arena succeeds';
    is $ss->get('k0'), 'y' x 100, '  ... keeping the entry it replaces';
    is $ss->size, 1, '  ... while the other expired entries are flushed';
}

{
    my $m = Data::HashMap::Shared::SS->new(undef, 100_000, 0, 2, 0, 16 + 768 * 16);
    my $i = 0;
    $i++ while $i < 800 && $m->put("k$i", 'v' x 10);
    is $i . '/' . $m->capacity, '768/1024', 'the arena fills at the design load';
    Time::HiRes::sleep(3.1);
    ok $m->put("n$_", 'w' x 10), "insert $_ after every entry expired" for 1 .. 2;
    is $m->capacity, 1024, '  ... compacts the table in place rather than doubling it';
}

{
    my $s = Data::HashMap::Shared::SS->new(undef, 1000, 10, 0, 0, 8192);
    $s->put("k$_", 'v' x 400) for 1 .. 10;
    my $huge = 'y' x 100_000;
    ok !$s->$_('huge', $huge), "$_ of a value no arena holds is refused at max_size"
        for qw(put add swap get_or_set set_multi);
    is $s->stats->{evictions}, 0, '  ... evicting nothing';
    is $s->size, 10, '  ... so the cache keeps every entry';

    my $c = Data::HashMap::Shared::SI->new(undef, 1000, 10, 0, 0, 4096);
    $c->put("k$_", $_) for 1 .. 10;
    ok !eval { $c->incr('K' x 5000); 1 }, 'incr of a key no arena holds croaks at max_size';
    ok !eval { $c->max('K' x 5000, 1); 1 }, '  ... as does max';
    is $c->stats->{evictions}, 0, '  ... evicting nothing';
    is $c->size, 10, '  ... so every counter stays';
}

done_testing;
