use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# An insert probe cannot tell an expired entry from a live one -- both are
# SHM_IS_LIVE -- so a table whose slots are all held by expired entries must
# still accept an insert, or a map keyed by identities that never repeat wedges
# for good while keys() reports nothing.

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

# A long default TTL: only the fillers expire, so the key each case then inserts
# cannot expire before the assertion that looks for it.
sub filled_to_capacity {
    my $m = Data::HashMap::Shared::SI->new("$dir/x" . $seq++ . ".shm", 8, 0, 3600);
    $m->put_ttl("old-$_", $_, 1) for 1 .. $m->capacity;
    is $m->size, $m->capacity, "table filled to capacity (" . $m->capacity . ")";
    return $m;
}

# --- every insert path reclaims -------------------------------------------
# One TTL window for all six maps, not one each.
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

# --- a genuinely full table still refuses ---------------------------------
{
    my $m = Data::HashMap::Shared::SI->new("$dir/live.shm", 8, 0, 900);
    $m->put("live-$_", $_) for 1 .. $m->capacity;
    ok !$m->put('overflow', 1), 'a table full of LIVE entries still refuses';
    is $m->size, $m->capacity, '  ... and nothing was evicted to make room';
}

# --- a permanent entry is never reclaimed ---------------------------------
{
    my $m = Data::HashMap::Shared::II->new("$dir/perm.shm", 8, 0, 1);
    $m->put_ttl(999, 42, 0);                       # permanent
    $m->put($_, $_) for 1 .. $m->capacity - 1;
    Time::HiRes::sleep(1.2);
    $m->put(1000 + $_, $_) for 1 .. 2 * $m->capacity;
    is $m->get(999), 42, 'a permanent entry survives repeated reclaim';
}

# --- the reclaim is accounted, not silent ---------------------------------
{
    my $m = Data::HashMap::Shared::SI->new("$dir/stat.shm", 8, 0, 1);
    $m->put("e$_", $_) for 1 .. $m->capacity;
    Time::HiRes::sleep(1.2);
    is $m->stats->{expired}, 0, 'nothing counted as expired before the reclaim';
    $m->put('trigger', 1);
    cmp_ok $m->stats->{expired}, '>', 0, 'the reclaimed entry is counted in stats';
}

# --- a saturated table is flushed whole, not one slot per insert ------------
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


# --- an LRU map evicts when the ARENA is exhausted, not only when the entry
# --- count reaches max_size: otherwise the cache freezes holding its oldest
# --- entries, which is the opposite of what a cache is for.
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

# a map WITHOUT LRU must still refuse -- never evict what the caller did not ask
# to have evicted
{
    my $p = Data::HashMap::Shared::SS->new("$dir/noarena.shm", 1000, 0, 0, 0, 4096);
    my $fail = 0;
    for my $i (1 .. 200) { $p->put("k$i", 'y' x 400) or $fail++ }
    cmp_ok $fail, '>', 0, 'a non-LRU map with a full arena still refuses';
    is $p->stats->{evictions}, 0, '  ... and evicts nothing';
}


# --- arena eviction must reach every insert path, not just put ---------------
# The reclaim above was wired into all six insert paths; the arena-eviction
# retry initially reached only put_inner, so add/swap/get_or_set/incr/max still
# refused -- and the counters croaked rather than returning false.
{
    my $V = 'x' x 400;
    my $seq2 = 0;
    my $full_arena = sub {
        # An explicit small arena is the binding constraint with no slack: the
        # default one leaves free blocks behind and a following insert finds
        # room without ever needing to evict, which is not the state under test.
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

    # string keys need arena space too, and these croak rather than return false
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

    # and a map with no LRU still refuses every one of them
    my $p = Data::HashMap::Shared::SS->new("$dir/noevict.shm", 1000, 0, 0, 0, 8192);
    my $n = 0;
    while ($p->put("f$n", $V)) { last if ++$n > 500 }
    ok !$p->add('a', $V), 'without LRU, add still refuses';
    $p->swap('b', $V);
    ok !$p->exists('b'),  '  ... swap too';
    ok !defined $p->get_or_set('c', $V), '  ... and get_or_set';
    is $p->stats->{evictions}, 0, '  ... having evicted nothing';
}


# --- an unsatisfiable insert must not destroy the cache to discover that ------
# Arena blocks are exact size classes and are never coalesced, so a request the
# whole arena could not hold is not made satisfiable by any number of evictions.
# Without a guard the retry loop evicted until the map was empty and then failed
# anyway.
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


# --- a doomed insert costs at most one entry per store, whatever its size ----
# The whole-arena guard only catches a request larger than the arena.  A request
# that fits the arena but matches no size class the eviction frees is equally
# unsatisfiable, because blocks are exact classes and never coalesce -- and the
# retry loop used to evict until the map was empty discovering that.
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

    # an arena-backed KEY is guarded the same way as a value
    my $m = $cache->();
    my ($size, $ev) = ($m->size, $m->stats->{evictions});
    $m->put('z' x 300, 'y' x 5000);
    cmp_ok $size - $m->size, '<=', 1, 'a long key with an oversize value costs at most one entry';

    # the other direction: a class smaller than every block present is equally
    # unsatisfiable, because blocks are never split either.  The arena is tiled
    # exactly by eight 1024-byte blocks, so no bump remainder serves the request.
    my $s = Data::HashMap::Shared::SS->new("$dir/small.shm", 1000, 900, 0, 0, 16 + 8 * 1024);
    my $j = 0;
    while ($s->put("b$j", 'b' x 1000)) { last if ++$j > 40 }
    my ($fails, $ev2) = (0, $s->stats->{evictions});
    for (1 .. 4) { $fails++ unless $s->put("s$_", 'a' x 100) }
    is $fails, 4, 'a request in a class no entry holds fails, smaller than every block present';
    is $s->stats->{evictions} - $ev2, 4, '  ... each failure having evicted one entry blindly';

    # an insert whose arena-backed key is stored, then whose value evicts and
    # still fails, costs two entries and releases the key block again
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


# --- the eviction is aimed at the request's size class ------------------------
# Among the 32 oldest entries the victim is the oldest holding a block of the
# request's own class; only when none of them does is the tail evicted blindly.
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

done_testing;
