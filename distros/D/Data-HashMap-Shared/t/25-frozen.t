use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Anchored on the message: croak appends " at t/25-frozen.t line N" to
# everything raised here, so a bare /frozen|read-only/ matches any exception
# this file provokes, from any check.
my $FROZEN = qr/is frozen \(read-only\)|cannot freeze a read-only handle/;

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
    like exception(sub { $ro->put(1, 1) }),      $FROZEN, 'put croaks on read-only view';
    like exception(sub { $ro->add(5, 5) }),      $FROZEN, 'add croaks on read-only view';
    like exception(sub { $ro->incr(1) }),        $FROZEN, 'incr croaks on read-only view';
    like exception(sub { $ro->decr(1) }),        $FROZEN, 'decr croaks on read-only view';
    like exception(sub { $ro->incr_by(1, 3) }),  $FROZEN, 'incr_by croaks on read-only view';
    like exception(sub { $ro->max(1, 9) }),      $FROZEN, 'max croaks on read-only view';
    like exception(sub { $ro->min(1, -9) }),     $FROZEN, 'min croaks on read-only view';
    like exception(sub { $ro->remove(1) }),      $FROZEN, 'remove croaks on read-only view';
    like exception(sub { $ro->clear }),          $FROZEN, 'clear croaks on read-only view';
    like exception(sub { $ro->get_or_set(1,0) }),$FROZEN, 'get_or_set croaks on read-only view';
    like exception(sub { $ro->freeze }),         $FROZEN, 'freeze croaks on read-only view';
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
     $FROZEN, 'read-write reopen of a sealed file is refused (create path)';
{
    open my $fh, '+<', $path or die "open $path: $!";
    like exception(sub { Data::HashMap::Shared::II->new_from_fd(fileno $fh) }),
         $FROZEN, 'new_from_fd of a sealed file is refused (open_fd path)';
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

    like exception(sub { $ro->put("x", "y") }),    $FROZEN, 'SS put croaks on read-only view';
    like exception(sub { $ro->remove("key-1") }),  $FROZEN, 'SS remove croaks on read-only view';
    like exception(sub { $ro->clear }),            $FROZEN, 'SS clear croaks on read-only view';
}

# Regression (0.19): a sealed file has no writers, so an odd seq or a held lock
# word is residue from a writer that raced the freeze and then died.  A PROT_READ
# view cannot repair it (the CAS would fault the mapping) and nothing else can
# either -- a read-write attach refuses a sealed file -- so every reader used to
# block in the seqlock forever.  It must be refused at open instead.  (An earlier
# 0.19 build SIGSEGV'd in this state; the one after it hung.)
{
    my $p = "$dir/residue.hm";
    { my $m = Data::HashMap::Shared::II->new($p, 64);
      $m->put($_, $_) for 1 .. 10;
      $m->freeze; }

    ok( Data::HashMap::Shared::II->new_readonly($p), 'sealed file opens read-only when clean' );

    my $poke = sub {
        my ($off, $v) = @_;
        open my $f, '+<:raw', $p or die $!;
        seek $f, $off, 0 or die $!;
        print $f pack('L', $v);
        close $f or die $!;
    };
    my $dead = fork // die "fork: $!";
    POSIX::_exit(0) unless $dead;
    waitpid $dead, 0;

    $poke->(64, 21);                                  # ShmHeader.seq, left odd
    like exception(sub { Data::HashMap::Shared::II->new_readonly($p) }),
         qr/mid-update|crashed writer/,
         'sealed file with an odd seq is refused, not opened into a hang';
    $poke->(64, 20);

    $poke->(128, 0x80000000 | $dead);                 # ShmHeader.wlock, dead holder
    like exception(sub { Data::HashMap::Shared::II->new_readonly($p) }),
         qr/mid-update|crashed writer/,
         'sealed file with a held lock word is refused';
    $poke->(128, 0);

    ok( Data::HashMap::Shared::II->new_readonly($p),
        'and opens again once the residue is cleared' );
}

# Regression (0.19): a resize deferred while an iterator was live outlives
# freeze(), and flush_deferred was the one write-lock path with no frozen check
# -- so ending the iterator resized a SEALED file (capacity and table_gen both
# changed).  No race is needed; it is deterministic.  A crash inside that resize
# left residue on a frozen file that no API could then open at all.
{
    my $read_hdr = sub {
        open my $f, '<:raw', $_[0] or die $!;
        my $b = do { local $/; <$f> };
        close $f;
        return {
            table_cap => unpack('L', substr($b, 20, 4)),
            table_gen => unpack('L', substr($b, 156, 4)),
            sealed    => unpack('C', substr($b, 96, 1)),
        };
    };

    for my $case (
        ['cursor DESTROY', sub { my ($m) = @_; my $c = $m->cursor; $c->next; sub { undef $c } }],
        ['each exhausted', sub { my ($m) = @_; my @kv = $m->each;      sub { 1 while my @x = $m->each } }],
    ) {
        my ($label, $start) = @$case;
        my $p = "$dir/deferred-$label.hm";
        $p =~ s/\s+/-/g;
        my $m = Data::HashMap::Shared::II->new($p, 4096);
        $m->put($_, $_) for 1 .. 3000;
        my $finish = $start->($m);          # iteration in flight
        $m->remove($_) for 1 .. 2950;       # shrink wanted, but deferred
        $m->freeze;

        my $before = $read_hdr->($p);
        is $before->{sealed}, 1, "$label: file is sealed before the iterator ends";
        $finish->();                        # would run the deferred resize
        my $after = $read_hdr->($p);

        is $after->{table_cap}, $before->{table_cap},
            "$label: sealed file keeps its capacity";
        is $after->{table_gen}, $before->{table_gen},
            "$label: sealed file is not resized when the iterator ends";
    }
}


# Every mutator croaks, in every one of the ten separately compiled variants,
# through both kinds of handle: the one that froze the map (readonly == 1) and
# one opened BEFORE the freeze, which has readonly == 0 with sealed == 1 -- so a
# guard that consults only `readonly` lets that handle write into a sealed file.
{
    my %by_variant = (
        II   => { key => 1,       val => 1,       counters => 1 },
        SI   => { key => 'k',     val => 1,       counters => 1 },
        I16  => { key => 1,       val => 1,       counters => 1 },
        I32  => { key => 1,       val => 1,       counters => 1 },
        SI16 => { key => 'k',     val => 1,       counters => 1 },
        SI32 => { key => 'k',     val => 1,       counters => 1 },
        IS   => { key => 1,       val => 'v',     counters => 0 },
        SS   => { key => 'k',     val => 'v',     counters => 0 },
        I16S => { key => 1,       val => 'v',     counters => 0 },
        I32S => { key => 1,       val => 'v',     counters => 0 },
    );

    for my $v (sort keys %by_variant) {
        my $class = "Data::HashMap::Shared::$v";
        unless (eval "require $class; 1") { fail("load $class: $@"); next }
        my ($k, $val, $counters) = @{ $by_variant{$v} }{qw(key val counters)};

        # a TTL map, so put_ttl/add_ttl/update_ttl exercise the frozen guard on a
        # map where the operation is otherwise legal (REQUIRE_TTL sits after the
        # guard, so $FROZEN would catch a lost guard on a non-TTL map too)
        my $path = "$dir/prefreeze-$v.hm";
        my $writer = $class->new($path, 1024, 0, 3600);   # opened before the freeze
        $writer->put($k, $val);
        my $freezer = $class->new($path, 1024, 0, 3600);
        $freezer->freeze;

        ok !$writer->readonly, "$v: the pre-freeze handle is not marked read-only";
        ok $freezer->readonly,  "$v: the freezing handle is";

        for my $which ([$freezer, 'the frozen handle'], [$writer, 'a pre-freeze handle']) {
            my ($m, $how) = @$which;
            my %mut = (
                put          => sub { $m->put($k, $val) },
                add          => sub { $m->add($k, $val) },
                update       => sub { $m->update($k, $val) },
                remove       => sub { $m->remove($k) },
                clear        => sub { $m->clear },
                swap         => sub { $m->swap($k, $val) },
                cas          => sub { $m->cas($k, $val, $val) },
                cas_take     => sub { $m->cas_take($k, $val) },
                get_or_set   => sub { $m->get_or_set($k, $val) },
                take         => sub { $m->take($k) },
                pop          => sub { $m->pop },
                shift        => sub { $m->shift },
                drain        => sub { $m->drain(3) },
                set_multi    => sub { $m->set_multi($k, $val) },
                remove_multi => sub { $m->remove_multi($k) },
                reserve      => sub { $m->reserve(1 << 20) },
                flush_expired         => sub { $m->flush_expired },
                flush_expired_partial => sub { $m->flush_expired_partial(8) },
                freeze       => sub { $m->freeze },
                persist      => sub { $m->persist($k) },
                touch        => sub { $m->touch($k) },
                set_ttl      => sub { $m->set_ttl($k, 1) },
                put_ttl      => sub { $m->put_ttl($k, $val, 1) },
                add_ttl      => sub { $m->add_ttl($k, $val, 1) },
                update_ttl   => sub { $m->update_ttl($k, $val, 1) },
            );
            if ($counters) {
                $mut{incr}    = sub { $m->incr($k) };
                $mut{decr}    = sub { $m->decr($k) };
                $mut{incr_by} = sub { $m->incr_by($k, 5) };
                $mut{max}     = sub { $m->max($k, 1) };
                $mut{min}     = sub { $m->min($k, -1) };
            }
            like exception($mut{$_}), $FROZEN, "$v: '$_' croaks through $how"
                for sort keys %mut;
        }
    }
}

done_testing;
