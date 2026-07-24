use strict;
use warnings;
use Test::More;
use Data::CountingBloomFilter::Shared;

# constructors: capacity + default fp_rate, and explicit fp_rate
my $cbf = Data::CountingBloomFilter::Shared->new(undef, 1000);
isa_ok $cbf, 'Data::CountingBloomFilter::Shared';
is $cbf->capacity, 1000, 'capacity stored';
cmp_ok abs($cbf->fp_rate - 0.01), '<', 1e-9, 'default fp_rate is 0.01';
ok !defined($cbf->path), 'anonymous path is undef';

my $cbf2 = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.001);
cmp_ok abs($cbf2->fp_rate - 0.001), '<', 1e-9, 'explicit fp_rate honored';

# geometry sanity: counters a power of two, k >= 1
my $counters = $cbf->counters;
ok $counters >= 64, 'counters >= 64';
is $counters & ($counters - 1), 0, 'counters is a power of two';
cmp_ok $cbf->hashes, '>=', 1, 'k >= 1';
cmp_ok $cbf2->hashes, '>', $cbf->hashes, 'tighter fp_rate uses more hashes';

# add returns 1 (probably new) the first time, 0 on re-add
is $cbf->add("hello"), 1, 'first add of a fresh item returns 1 (probably new)';
is $cbf->add("hello"), 0, 're-add of the same item returns 0 (already present)';

# contains: true for an added item, false for a never-added one
ok $cbf->contains("hello"), 'contains true for an added item';
ok !$cbf->contains("never-added-xyz"), 'contains false for a never-added item';

# remove: a present item becomes absent; remove of an absent item is a no-op
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000);
    $h->add("r");
    ok $h->contains("r"), 'present before remove';
    is $h->remove("r"), 1, 'remove of a present item returns 1';
    ok !$h->contains("r"), 'absent after remove';
    is $h->remove("r"), 0, 'remove of an already-absent item returns 0';
    is $h->remove("never-added"), 0, 'remove of a never-added item returns 0';
}

# count_of: occurrence count 0..15, tracks add/remove, saturates at 15
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000);
    is $h->count_of("z"), 0, 'count_of is 0 for a never-added item';
    $h->add("z");
    is $h->count_of("z"), 1, 'count_of is 1 after one add';
    ok $h->contains("z"), 'contains true whenever count_of > 0';
    $h->add("z"); $h->add("z");
    is $h->count_of("z"), 3, 'count_of tracks three adds';
    is $h->remove("z"), 1, 'remove of a present item';
    is $h->count_of("z"), 2, 'count_of drops to 2 after one remove';
    # remove down to zero
    $h->remove("z"); $h->remove("z");
    is $h->count_of("z"), 0, 'count_of is 0 after removing every copy';
    ok !$h->contains("z"), 'contains false once count_of hits 0';
    # wide-char item croaks before the lock (like contains)
    ok !eval { $h->count_of("snow-\x{2603}"); 1 }, 'count_of croaks on a wide-char item';
    like $@, qr/[Ww]ide/, 'count_of wide-char croak mentions Wide character';
    ok !eval { $h->remove("snow-\x{2603}"); 1 }, 'remove croaks on a wide-char item';
}

# saturation: counters cap at 15; a saturated item cannot be fully removed
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000);
    $h->add("sat") for 1 .. 20;
    is $h->count_of("sat"), 15, 'count_of saturates at 15 (4-bit counters)';
    is $h->remove("sat"), 1, 'remove of a saturated item returns 1 (present)';
    $h->remove("sat") for 1 .. 20;
    ok $h->contains("sat"), 'saturated item stays present (stuck-at-15 counters)';
    is $h->count_of("sat"), 15, 'saturated counters stay stuck at 15 through removes';
}

# k=1 / smallest geometry: fp_rate ~0.5 clamps to k=1 and the 64-counter floor.
# With a single probe, count_of is that one exact counter -- multiplicity is stored.
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 10, 0.5);
    is $h->hashes, 1, 'fp_rate 0.5 clamps to k=1';
    is $h->counters, 64, 'tiny capacity hits the 64-counter floor';
    $h->add("a") for 1 .. 5;
    is $h->count_of("a"), 5, 'k=1: count_of is the single exact counter (5 adds)';
    $h->remove("a") for 1 .. 2;
    is $h->count_of("a"), 3, 'k=1: count_of tracks removes exactly';
    ok $h->contains("a"), 'k=1: still present';
    $h->remove("a") for 1 .. 3;
    ok !$h->contains("a"), 'k=1: absent after removing every copy';
}

# no false negatives: add 1000 items, every one must be contained
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add("k-$_") for 0 .. 999;
    my $miss = 0;
    $h->contains("k-$_") or $miss++ for 0 .. 999;
    is $miss, 0, 'no false negatives: all 1000 added items are contained';
}

# add/remove churn keeps the survivors present and forgets the removed
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 4000, 0.001);
    $h->add("live-$_")  for 0 .. 999;
    $h->add("dead-$_")  for 0 .. 999;
    $h->remove("dead-$_") for 0 .. 999;      # remove exactly what we added
    my $miss = 0; $h->contains("live-$_") or $miss++ for 0 .. 999;
    is $miss, 0, 'churn: all live items still contained (no false negatives)';
    # the removed set is very likely gone (allow a few collision survivors)
    my $still = 0; $h->contains("dead-$_") and $still++ for 0 .. 999;
    cmp_ok $still, '<', 50, 'churn: nearly all removed items are gone';
}

# add_many returns count of probably-new items
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    my $added = $h->add_many([ map { "m-$_" } 1 .. 1000 ]);
    is $added, 1000, 'add_many reports all 1000 distinct items as new';
    is $h->add_many([ map { "m-$_" } 1 .. 1000 ]), 0, 're-add_many of the same set reports 0 new';
    is $h->count_of("m-1"), 2, 'add_many twice -> count_of 2';
}

# stats keys + fill_ratio in [0,1]
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add_many([ map { "s-$_" } 1 .. 500 ]);
    my $st = $h->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(capacity fp_rate counters hashes counters_set count fill_ratio ops mmap_size);
    is $st->{capacity}, 1000, 'stats capacity';
    is $st->{counters}, $h->counters, 'stats counters matches accessor';
    is $st->{hashes}, $h->hashes, 'stats hashes matches accessor';
    cmp_ok $st->{counters_set}, '>', 0, 'some counters are set after adds';
    cmp_ok $st->{fill_ratio}, '>=', 0, 'fill_ratio >= 0';
    cmp_ok $st->{fill_ratio}, '<=', 1, 'fill_ratio <= 1';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the add_many write';
    {
        my $b4 = $h->stats->{ops};
        is $h->add_many([]), 0, 'empty add_many adds nothing';
        is $h->stats->{ops}, $b4 + 1, 'an empty add_many still counts as one write op';
    }
}

# count estimate is sane for a known number of distinct adds
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 10_000, 0.01);
    $h->add("c-$_") for 0 .. 4999;
    my $n = $h->count;
    cmp_ok $n, '>', 4000, 'count estimate above 4000 for 5000 adds';
    cmp_ok $n, '<', 6000, 'count estimate below 6000 for 5000 adds';
}

# clear -> counters_set 0, contains false
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add("gone");
    ok $h->contains("gone"), 'present before clear';
    $h->clear;
    is $h->stats->{counters_set}, 0, 'clear -> counters_set 0';
    ok !$h->contains("gone"), 'clear -> contains false';
}

# merge: counter-wise saturating add of two filters with the same geometry
{
    my $a = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    my $b = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    $a->add_many([ map { "A-$_" } 1 .. 500 ]);
    $b->add_many([ map { "B-$_" } 1 .. 500 ]);
    ok !$a->contains("B-1"), 'a does not contain b items before merge';
    $a->merge($b);
    ok $a->contains("A-1"), 'merge keeps a items';
    ok $a->contains("B-1"), 'merge unions in b items';
    my $miss = 0;
    $a->contains("B-$_") or $miss++ for 1 .. 500;
    is $miss, 0, 'merge: no false negatives for any merged-in item';
    # counts add: merge a filter into itself-shaped counts
    my $c = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    my $d = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    $c->add("dup"); $c->add("dup");   # count 2
    $d->add("dup");                   # count 1
    $c->merge($d);
    is $c->count_of("dup"), 3, 'merge sums counts (2 + 1 = 3)';
    # merge saturates the summed count at 15
    my $e = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    my $f = Data::CountingBloomFilter::Shared->new(undef, 2000, 0.01);
    $e->add("s") for 1 .. 10;
    $f->add("s") for 1 .. 10;
    $e->merge($f);
    is $e->count_of("s"), 15, 'merge saturates the summed count at 15 (10 + 10 -> 15)';
}

# self-merge must not deadlock and doubles counts (counter-wise add of self)
{
    my $s = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    $s->add_many([ map { "s-$_" } 1 .. 300 ]);
    my $ok = eval { local $SIG{ALRM} = sub { die "deadlock\n" }; alarm 5; $s->merge($s); alarm 0; 1 };
    ok $ok, 'self-merge does not deadlock';
    my $sm = 0; $s->contains("s-$_") or $sm++ for 1 .. 300;
    is $sm, 0, 'self-merge keeps all items';
    is $s->count_of("s-1"), 2, 'self-merge doubles the count (1 + 1)';
}

# error paths: bad capacity / fp_rate
ok !eval { Data::CountingBloomFilter::Shared->new(undef, 0); 1 }, 'capacity 0 rejected';
like $@, qr/capacity/, 'capacity 0 croak mentions capacity';
ok !eval { Data::CountingBloomFilter::Shared->new(undef, 1000, 0); 1 }, 'fp_rate 0 rejected';
like $@, qr/fp_rate/, 'fp_rate 0 croak mentions fp_rate';
ok !eval { Data::CountingBloomFilter::Shared->new(undef, 1000, 1); 1 }, 'fp_rate 1 rejected';
like $@, qr/fp_rate/, 'fp_rate 1 croak mentions fp_rate';
ok !eval { Data::CountingBloomFilter::Shared->new(undef, 1000, 1.5); 1 }, 'fp_rate 1.5 rejected';
like $@, qr/fp_rate/, 'fp_rate 1.5 croak mentions fp_rate';
ok !eval { Data::CountingBloomFilter::Shared->new(undef, 10**12, 0.01); 1 }, 'over-cap capacity rejected';
like $@, qr/too large/, 'over-cap capacity croak mentions too large';

# error paths: new_memfd has the identical guards
ok !eval { Data::CountingBloomFilter::Shared->new_memfd('x', 0); 1 }, 'new_memfd capacity 0 rejected';
like $@, qr/capacity/, 'new_memfd capacity 0 croak mentions capacity';
ok !eval { Data::CountingBloomFilter::Shared->new_memfd('x', 1000, 0); 1 }, 'new_memfd fp_rate 0 rejected';
like $@, qr/fp_rate|rate/, 'new_memfd fp_rate 0 croak mentions rate';
ok !eval { Data::CountingBloomFilter::Shared->new_memfd('x', 1000, 1.5); 1 }, 'new_memfd fp_rate 1.5 rejected';
like $@, qr/fp_rate|rate/, 'new_memfd fp_rate 1.5 croak mentions rate';

# error path: add_many requires an array reference
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    ok !eval { $h->add_many("notaref"); 1 }, 'add_many croaks on a non-arrayref scalar';
    like $@, qr/array reference/, 'add_many non-arrayref croak mentions array reference';
    ok !eval { $h->add_many({}); 1 }, 'add_many croaks on a hashref';
    like $@, qr/array reference/, 'add_many hashref croak mentions array reference';
    ok !eval { $h->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char item';
    like $@, qr/[Ww]ide/, 'add wide-char croak mentions Wide character';
}

# error path: merge of mismatched geometry croaks
{
    my $a = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    my $b = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.001);   # different k/counters
    ok !eval { $a->merge($b); 1 }, 'merge of mismatched geometry croaks';
    like $@, qr/mismatch/, 'merge mismatch croak message';
}

# file-backed reopen: add, sync, reopen, still contains + counts persist
my $path = "/tmp/cbf-basic-$$.bin";
unlink $path;
{
    my $w = Data::CountingBloomFilter::Shared->new($path, 5000, 0.01);
    is $w->path, $path, 'file-backed path';
    $w->add_many([ map { "p-$_" } 1 .. 3000 ]);
    $w->add("twice"); $w->add("twice");
    $w->sync;
}
{
    my $r = Data::CountingBloomFilter::Shared->new($path, 1, 0.5);   # caller args ignored on reopen
    is $r->capacity, 5000, 'reopen: stored capacity wins';
    cmp_ok abs($r->fp_rate - 0.01), '<', 1e-9, 'reopen: stored fp_rate wins';
    ok $r->contains("p-1500"), 'reopen: membership persisted';
    is $r->count_of("twice"), 2, 'reopen: counts persisted';
    my $miss = 0;
    $r->contains("p-$_") or $miss++ for 1 .. 3000;
    is $miss, 0, 'reopen: no false negatives after persistence';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::CountingBloomFilter::Shared->new($path, 1000, 0.01); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# new_from_fd error path: a valid fd over a non-CBF file is rejected
{
    my $jp = "/tmp/cbf-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;
    print $fh "not a counting bloom table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::CountingBloomFilter::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-CBF file';
    like $@, qr/too small|invalid|Bloom/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# memfd round-trip shares the counter array
{
    my $m  = Data::CountingBloomFilter::Shared->new_memfd('cbf', 1000, 0.01);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::CountingBloomFilter::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->capacity, 1000, 'reopened memfd capacity';
    $m->add("shared-x");
    ok $m2->contains("shared-x"), 'new_from_fd shares the counter array';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::CountingBloomFilter::Shared->new_memfd(undef, 100, 0.01);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# class-method unlink
my $cu = "/tmp/cbf-cu-$$.bin";
unlink $cu;
{ my $w = Data::CountingBloomFilter::Shared->new($cu, 100, 0.01); $w->sync; }
ok -e $cu, 'backing file exists';
Data::CountingBloomFilter::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/cbf-iu-$$.bin";
unlink $iu;
{
    my $w = Data::CountingBloomFilter::Shared->new($iu, 100, 0.01);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# opt-in file mode: an explicit octal mode is applied exactly at create
# (fchmod after the O_EXCL create), and the default is owner-only 0600.
{
    my $mp = "/tmp/cbf-mode-$$.bin";
    unlink $mp;
    { my $w = Data::CountingBloomFilter::Shared->new($mp, 100, 0.01, 0660); }
    is +((stat $mp)[2] & 07777), 0660, 'explicit file mode 0660 honored at create';
    unlink $mp;
    { my $d = Data::CountingBloomFilter::Shared->new($mp, 100, 0.01); }
    is +((stat $mp)[2] & 07777), 0600, 'default file mode is 0600 (owner-only)';
    unlink $mp;
}

# lock-leak regression: a wide-char element makes add_many croak, and a
# follow-up contains() under an alarm proves the write lock was not leaked.
{
    my $h = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add("ascii-seed");
    ok !eval { $h->add_many(["good-elem", "snow-\x{2603}"]); 1 }, 'add_many croaks on a wide-char element';
    # bytes are resolved for every element BEFORE the lock, so a mid-batch croak
    # adds nothing at all -- the good element before the wide-char is not stored.
    ok !$h->contains("good-elem"), 'add_many is atomic on croak (good element not added)';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $c = $h->contains("ascii-seed");
        alarm 0;
        1;
    };
    ok $survived, 'write lock not leaked: contains works after the caught add_many croak';
}

# DESTROY nulls the handle: use-after-destroy croaks, double DESTROY is a no-op
{
    my $i = Data::CountingBloomFilter::Shared->new(undef, 100, 0.01);
    $i->add("x");
    $i->DESTROY;
    eval { $i->contains("x") };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
