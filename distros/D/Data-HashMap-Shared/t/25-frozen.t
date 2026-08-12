use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Frozen (read-only) mode: freeze() seals a file-backed map immutable; a consumer
# opens it with new_readonly (O_RDONLY / PROT_READ) and queries it lock-free.
# The critical property under test is that NOTHING writes the PROT_READ mapping
# on any read/iterate path -- a stray write would SIGSEGV, not just misbehave.

my $dir = tempdir(CLEANUP => 1);
my $N   = 1000;   # >> SHM_INITIAL_CAP (16): forces several rehashes, a large table to iterate

sub exception {
    my $code = shift;
    my $err;
    { local $@; eval { $code->(); 1 } or $err = $@; }
    return $err;
}

# ---------------------------------------------------------------------------
# II (int64 -> int64), no LRU / no TTL: producer builds + freezes
# ---------------------------------------------------------------------------
my $path = "$dir/ii.hm";
{
    my $m = Data::HashMap::Shared::II->new($path, 100000);
    ok !$m->frozen,   'fresh map is not frozen';
    ok !$m->readonly, 'read-write handle is not read-only';
    $m->put($_, $_ * 7) for 1 .. $N;
    $m->set_multi(-1 => 100, -2 => 200);
    is $m->size, $N + 2, 'producer populated all entries';
    my $cap = $m->capacity;
    ok $cap > 16, 'table rehashed past the initial capacity';

    $m->freeze;
    ok $m->frozen,   'frozen after ->freeze';
    ok $m->readonly, 'freezing handle becomes read-only';
    is $m->size, $N + 2, 'size unchanged by freeze';
    is $m->capacity, $cap, 'capacity unchanged by freeze';

    # Every mutator croaks on the (now frozen) producer handle.
    my %mut = (
        put          => sub { $m->put(1, 1) },
        add          => sub { $m->add(77, 77) },
        update       => sub { $m->update(1, 2) },
        remove       => sub { $m->remove(1) },
        clear        => sub { $m->clear },
        incr         => sub { $m->incr(1) },
        decr         => sub { $m->decr(1) },
        incr_by      => sub { $m->incr_by(1, 5) },
        max          => sub { $m->max(1, 1e9) },
        min          => sub { $m->min(1, -1e9) },
        swap         => sub { $m->swap(1, 3) },
        cas          => sub { $m->cas(1, 7, 8) },
        cas_take     => sub { $m->cas_take(1, 7) },
        get_or_set   => sub { $m->get_or_set(1, 0) },
        take         => sub { $m->take(1) },
        pop          => sub { $m->pop },
        shift        => sub { $m->shift },
        drain        => sub { $m->drain(3) },
        set_multi    => sub { $m->set_multi(5, 5) },
        remove_multi => sub { $m->remove_multi(1, 2) },
        reserve      => sub { $m->reserve(1 << 20) },
        flush_expired=> sub { $m->flush_expired },
        freeze       => sub { $m->freeze },
    );
    like exception($mut{$_}), qr/frozen|read-only/, "mutator '$_' croaks on a frozen handle"
        for sort keys %mut;
}

# ---------------------------------------------------------------------------
# II consumer: read-only PROT_READ view -- every read + full iteration
# ---------------------------------------------------------------------------
{
    my $ro = Data::HashMap::Shared::II->new_readonly($path);
    isa_ok $ro, 'Data::HashMap::Shared::II';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';
    is $ro->size, $N + 2, 'read-only size';

    # get() for every key -- lock-free reads over the PROT_READ mapping.
    my $bad = 0;
    for (1 .. $N) { my $v = $ro->get($_); $bad++ unless defined $v && $v == $_ * 7; }
    is $bad, 0, "get() matches producer for all $N keys via the PROT_READ view";
    is $ro->get(-1), 100, 'get() of a negative key';
    ok !defined $ro->get(1 << 30), 'get() of an absent key is undef';
    ok  $ro->exists(5),        'exists() true';
    ok !$ro->exists(1 << 30),  'exists() false';
    my ($gv, $gttl) = $ro->get_with_ttl(9);
    is $gv, 63, 'get_with_ttl() value on the read-only view';

    # Full iteration via each() on the PROT_READ handle: a hidden per-iteration
    # write into the mapping (cursor position / clock bit) would fault here.
    my %seen;
    while (my ($k, $v) = $ro->each) { $seen{$k} = $v }
    is scalar(keys %seen), $N + 2, 'each() visited every entry on the read-only handle';
    my $each_bad = 0;
    $each_bad++ for grep { ($seen{$_} // -1) != $_ * 7 } 1 .. $N;
    is $each_bad, 0, 'each() yielded the correct value for every key';

    # keys / values / items / to_hash (list-context methods -- capture the list)
    my @all_k = $ro->keys;   is scalar(@all_k), $N + 2,       'keys() count';
    my @all_v = $ro->values; is scalar(@all_v), $N + 2,       'values() count';
    my @all_i = $ro->items;  is scalar(@all_i), ($N + 2) * 2, 'items() flat count';
    my $h = $ro->to_hash;
    is scalar(keys %$h), $N + 2, 'to_hash() count';
    is $h->{5}, 35, 'to_hash() value';

    # Cursor: an independent iterator (a SECOND handle) over the read-only map.
    my %cseen;
    my $c = $ro->cursor;
    while (my ($k, $v) = $c->next) { $cseen{$k} = $v }
    is scalar(keys %cseen), $N + 2, 'cursor fully iterated the read-only map (PROT_READ)';
    my $cur_bad = 0;
    $cur_bad++ for grep { ($cseen{$_} // -1) != $_ * 7 } 1 .. $N;
    is $cur_bad, 0, 'cursor yielded the correct value for every key';
    $c->reset;
    my ($k1) = $c->next;
    ok defined $k1, 'cursor reset re-yields from the start';
    ok $c->seek(5), 'cursor seek to an existing key on the read-only view';

    # Diagnostics
    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen == 1';
    is $st->{readonly}, 1, 'stats.readonly == 1';
    is $st->{size}, $N + 2, 'stats.size';
    ok $ro->capacity  > 0, 'capacity readable read-only';
    ok $ro->mmap_size > 0, 'mmap_size readable read-only';
    is $ro->path,  $path, 'path readable read-only';
    is $ro->memfd, -1,    'memfd -1 (file-backed) read-only';
    eval { $ro->sync };
    ok !$@, 'sync is a silent no-op on the read-only view';

    # Mutators croak on the read-only view. incr/incr_by/max/min write under the
    # READ lock (atomic RMW), so this guard is the only thing preventing a
    # PROT_READ fault for them -- exercise them explicitly.
    like exception(sub { $ro->put(1, 1) }),      qr/frozen|read-only/, 'put croaks on read-only view';
    like exception(sub { $ro->add(5, 5) }),      qr/frozen|read-only/, 'add croaks on read-only view';
    like exception(sub { $ro->incr(1) }),        qr/frozen|read-only/, 'incr croaks on read-only view';
    like exception(sub { $ro->decr(1) }),        qr/frozen|read-only/, 'decr croaks on read-only view';
    like exception(sub { $ro->incr_by(1, 3) }),  qr/frozen|read-only/, 'incr_by croaks on read-only view';
    like exception(sub { $ro->max(1, 9) }),      qr/frozen|read-only/, 'max croaks on read-only view';
    like exception(sub { $ro->min(1, -9) }),     qr/frozen|read-only/, 'min croaks on read-only view';
    like exception(sub { $ro->remove(1) }),      qr/frozen|read-only/, 'remove croaks on read-only view';
    like exception(sub { $ro->clear }),          qr/frozen|read-only/, 'clear croaks on read-only view';
    like exception(sub { $ro->get_or_set(1,0) }),qr/frozen|read-only/, 'get_or_set croaks on read-only view';
    like exception(sub { $ro->freeze }),         qr/read-only/,        'freeze croaks on read-only view';
}

# ---------------------------------------------------------------------------
# Two independent read-only views of the same file, concurrently
# ---------------------------------------------------------------------------
{
    my $a = Data::HashMap::Shared::II->new_readonly($path);
    my $b = Data::HashMap::Shared::II->new_readonly($path);
    ok $a->get(10) == 70 && $b->get(10) == 70, 'two read-only views query the same file';
}

# ---------------------------------------------------------------------------
# LRU-enabled map: get()/get_with_ttl set the clock (accessed) bit IN the
# mapping. On a PROT_READ frozen view that store must be skipped, or it faults.
# max_size >= entries so no eviction occurs (all keys survive to be read back).
# ---------------------------------------------------------------------------
{
    my $lp = "$dir/lru.hm";
    {
        my $m = Data::HashMap::Shared::II->new($lp, 100000, 100000);  # max_size enables LRU (lru_accessed array)
        $m->put($_, $_ + 1) for 1 .. $N;
        $m->freeze;
    }
    my $ro = Data::HashMap::Shared::II->new_readonly($lp);
    ok $ro->frozen && $ro->readonly, 'LRU map: read-only view frozen';
    my $bad = 0;
    for (1 .. $N) { my $v = $ro->get($_); $bad++ unless defined $v && $v == $_ + 1; }  # get() would fault w/o the clock-bit guard
    is $bad, 0, 'LRU map: get() over every key without faulting the PROT_READ clock bit';
    my ($lv, $lttl) = $ro->get_with_ttl(3);
    is $lv, 4, 'LRU map: get_with_ttl() without faulting the clock bit';
    my %seen;
    my $c = $ro->cursor;
    while (my ($k, $v) = $c->next) { $seen{$k} = $v }
    is scalar(keys %seen), $N, 'LRU map: cursor fully iterated the read-only view';
}

# ---------------------------------------------------------------------------
# Refuse a read-write reopen of a sealed file -- both open paths
# ---------------------------------------------------------------------------
like exception(sub { Data::HashMap::Shared::II->new($path, 100000) }),
     qr/frozen|read-only/, 'read-write reopen of a sealed file is refused (create path)';
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::HashMap::Shared::II->new_from_fd(fileno $fh) }),
         qr/frozen|read-only/, 'new_from_fd of a sealed file is refused (open_fd path)';
    close $fh;
}

# ---------------------------------------------------------------------------
# new_readonly error paths
# ---------------------------------------------------------------------------
{
    my $u = "$dir/unsealed.hm";
    { my $m = Data::HashMap::Shared::II->new($u, 1000); $m->put(1, 1); }
    like exception(sub { Data::HashMap::Shared::II->new_readonly($u) }),
         qr/not frozen/, 'new_readonly on an unsealed file croaks';
}
like exception(sub { Data::HashMap::Shared::II->new_readonly("$dir/nope.hm") }),
     qr/open|No such/, 'new_readonly on a missing path croaks';
like exception(sub { Data::HashMap::Shared::II->new_readonly(undef) }),
     qr/required/, 'new_readonly requires a path';
like exception(sub { Data::HashMap::Shared::SS->new_readonly($path) }),
     qr/variant|corrupt|magic|mismatch/i, 'new_readonly rejects a wrong-variant sealed file';

# ---------------------------------------------------------------------------
# SS (string -> string): the arena read path under PROT_READ + full iteration
# ---------------------------------------------------------------------------
{
    my $sp = "$dir/ss.hm";
    {
        my $m = Data::HashMap::Shared::SS->new($sp, 100000, 0, 0, 0, 1 << 21);
        $m->put("key-$_", "val-$_") for 1 .. $N;
        $m->freeze;
    }
    my $ro = Data::HashMap::Shared::SS->new_readonly($sp);
    ok $ro->frozen && $ro->readonly, 'SS read-only view frozen + readonly';
    is $ro->get("key-5"),  "val-5",  'SS get() from the arena via PROT_READ';
    is $ro->get("key-999"),"val-999",'SS get() of a rehash-spanning key';
    ok !defined $ro->get("absent"),  'SS get() of an absent key is undef';

    my %cseen;
    my $c = $ro->cursor;
    while (my ($k, $v) = $c->next) { $cseen{$k} = $v }
    is scalar(keys %cseen), $N, 'SS cursor visited every arena entry (PROT_READ, no fault)';
    is $cseen{"key-42"}, "val-42", 'SS cursor value correct';

    my %eseen;
    while (my ($k, $v) = $ro->each) { $eseen{$k} = $v }
    is scalar(keys %eseen), $N, 'SS each() visited every entry';

    is_deeply [sort keys %cseen], [sort keys %eseen], 'SS cursor and each agree on the key set';

    like exception(sub { $ro->put("x", "y") }),    qr/frozen|read-only/, 'SS put croaks on read-only view';
    like exception(sub { $ro->remove("key-1") }),  qr/frozen|read-only/, 'SS remove croaks on read-only view';
    like exception(sub { $ro->clear }),            qr/frozen|read-only/, 'SS clear croaks on read-only view';
}

done_testing;
