use strict;
use warnings;
use Test::More;
use Data::BloomFilter::Shared;

# constructors: capacity + default fp_rate, and explicit fp_rate
my $bf = Data::BloomFilter::Shared->new(undef, 1000);
isa_ok $bf, 'Data::BloomFilter::Shared';
is $bf->capacity, 1000, 'capacity stored';
cmp_ok abs($bf->fp_rate - 0.01), '<', 1e-9, 'default fp_rate is 0.01';
ok !defined($bf->path), 'anonymous path is undef';

my $bf2 = Data::BloomFilter::Shared->new(undef, 1000, 0.001);
cmp_ok abs($bf2->fp_rate - 0.001), '<', 1e-9, 'explicit fp_rate honored';

# geometry sanity: bits a power of two, k >= 1
my $bits = $bf->bits;
ok $bits >= 64, 'bits >= 64';
is $bits & ($bits - 1), 0, 'bits is a power of two';
cmp_ok $bf->hashes, '>=', 1, 'k >= 1';
# tighter fp_rate -> more hashes
cmp_ok $bf2->hashes, '>', $bf->hashes, 'tighter fp_rate uses more hashes';

# add returns 1 (probably new) the first time, 0 on re-add
is $bf->add("hello"), 1, 'first add of a fresh item returns 1 (probably new)';
is $bf->add("hello"), 0, 're-add of the same item returns 0 (already present)';

# contains: true for an added item, false for a never-added one
ok $bf->contains("hello"), 'contains true for an added item';
ok !$bf->contains("never-added-xyz"), 'contains false for a never-added item';

# no false negatives: add 1000 items, every one must be contained
{
    my $h = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add("k-$_") for 0 .. 999;
    my $miss = 0;
    $h->contains("k-$_") or $miss++ for 0 .. 999;
    is $miss, 0, 'no false negatives: all 1000 added items are contained';
}

# add_many returns count of probably-new items
{
    my $h = Data::BloomFilter::Shared->new(undef, 2000, 0.01);
    my $added = $h->add_many([ map { "m-$_" } 1 .. 1000 ]);
    is $added, 1000, 'add_many reports all 1000 distinct items as new';
    is $h->add_many([ map { "m-$_" } 1 .. 1000 ]), 0, 're-add_many of the same set reports 0 new';
}

# stats keys + fill_ratio in [0,1]
{
    my $h = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add_many([ map { "s-$_" } 1 .. 500 ]);
    my $st = $h->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(capacity fp_rate bits hashes bits_set count fill_ratio ops mmap_size);
    is $st->{capacity}, 1000, 'stats capacity';
    is $st->{bits}, $h->bits, 'stats bits matches accessor';
    is $st->{hashes}, $h->hashes, 'stats hashes matches accessor';
    cmp_ok $st->{bits_set}, '>', 0, 'some bits are set after adds';
    cmp_ok $st->{fill_ratio}, '>=', 0, 'fill_ratio >= 0';
    cmp_ok $st->{fill_ratio}, '<=', 1, 'fill_ratio <= 1';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the add_many write';
    {
        my $b4 = $h->stats->{ops};
        is $h->add_many([]), 0, 'empty add_many adds nothing';
        is $h->stats->{ops}, $b4 + 1, 'an empty add_many still counts as one write op';
    }
}

# count estimate is sane (within range for a known number of distinct adds)
{
    my $h = Data::BloomFilter::Shared->new(undef, 10_000, 0.01);
    $h->add("c-$_") for 0 .. 4999;
    my $n = $h->count;
    cmp_ok $n, '>', 4000, 'count estimate above 4000 for 5000 adds';
    cmp_ok $n, '<', 6000, 'count estimate below 6000 for 5000 adds';
}

# clear -> bits_set 0, contains false
{
    my $h = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add("gone");
    ok $h->contains("gone"), 'present before clear';
    $h->clear;
    is $h->stats->{bits_set}, 0, 'clear -> bits_set 0';
    ok !$h->contains("gone"), 'clear -> contains false';
}

# merge: union of two filters with the same capacity + fp_rate
{
    my $a = Data::BloomFilter::Shared->new(undef, 2000, 0.01);
    my $b = Data::BloomFilter::Shared->new(undef, 2000, 0.01);
    $a->add_many([ map { "A-$_" } 1 .. 500 ]);
    $b->add_many([ map { "B-$_" } 1 .. 500 ]);
    ok !$a->contains("B-1"), 'a does not contain b items before merge';
    $a->merge($b);
    ok $a->contains("A-1"), 'merge keeps a items';
    ok $a->contains("B-1"), 'merge unions in b items';
    my $miss = 0;
    $a->contains("B-$_") or $miss++ for 1 .. 500;
    is $miss, 0, 'merge: no false negatives for any merged-in item';
}

# self-merge is a no-op and must not deadlock (the snapshot releases the read
# lock before taking the write lock, so the same handle is locked sequentially)
{
    my $s = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    $s->add_many([ map { "s-$_" } 1 .. 300 ]);
    my $before = $s->stats->{bits_set};
    my $ok = eval { local $SIG{ALRM} = sub { die "deadlock\n" }; alarm 5; $s->merge($s); alarm 0; 1 };
    ok $ok, 'self-merge does not deadlock';
    is $s->stats->{bits_set}, $before, 'self-merge is a no-op (bits unchanged)';
    my $sm = 0; $s->contains("s-$_") or $sm++ for 1 .. 300;
    is $sm, 0, 'self-merge keeps all items';
}

# error paths: bad capacity / fp_rate
ok !eval { Data::BloomFilter::Shared->new(undef, 0); 1 }, 'capacity 0 rejected';
like $@, qr/capacity/, 'capacity 0 croak mentions capacity';
ok !eval { Data::BloomFilter::Shared->new(undef, 1000, 0); 1 }, 'fp_rate 0 rejected';
like $@, qr/fp_rate/, 'fp_rate 0 croak mentions fp_rate';
ok !eval { Data::BloomFilter::Shared->new(undef, 1000, 1); 1 }, 'fp_rate 1 rejected';
like $@, qr/fp_rate/, 'fp_rate 1 croak mentions fp_rate';
ok !eval { Data::BloomFilter::Shared->new(undef, 1000, 1.5); 1 }, 'fp_rate 1.5 rejected';
like $@, qr/fp_rate/, 'fp_rate 1.5 croak mentions fp_rate';
# a capacity so large the optimal bit array would exceed the 2^38 cap must
# croak (not silently produce an undersized filter with a broken fp_rate)
ok !eval { Data::BloomFilter::Shared->new(undef, 10**12, 0.01); 1 }, 'over-cap capacity rejected';
like $@, qr/too large/, 'over-cap capacity croak mentions too large';

# error paths: new_memfd has the identical guards
ok !eval { Data::BloomFilter::Shared->new_memfd('x', 0); 1 }, 'new_memfd capacity 0 rejected';
like $@, qr/capacity/, 'new_memfd capacity 0 croak mentions capacity';
ok !eval { Data::BloomFilter::Shared->new_memfd('x', 1000, 0); 1 }, 'new_memfd fp_rate 0 rejected';
like $@, qr/fp_rate|rate/, 'new_memfd fp_rate 0 croak mentions rate';
ok !eval { Data::BloomFilter::Shared->new_memfd('x', 1000, 1.5); 1 }, 'new_memfd fp_rate 1.5 rejected';
like $@, qr/fp_rate|rate/, 'new_memfd fp_rate 1.5 croak mentions rate';

# error path: add_many requires an array reference
{
    my $bf = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    ok !eval { $bf->add_many("notaref"); 1 }, 'add_many croaks on a non-arrayref scalar';
    like $@, qr/array reference/, 'add_many non-arrayref croak mentions array reference';
    ok !eval { $bf->add_many({}); 1 }, 'add_many croaks on a hashref';
    like $@, qr/array reference/, 'add_many hashref croak mentions array reference';

    # single add of a wide-char item croaks (codepoint > 255 -> SvPVbyte)
    ok !eval { $bf->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char item';
    like $@, qr/[Ww]ide/, 'add wide-char croak mentions Wide character';
}

# error path: merge of mismatched geometry croaks
{
    my $a = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    my $b = Data::BloomFilter::Shared->new(undef, 1000, 0.001);   # different k/bits
    ok !eval { $a->merge($b); 1 }, 'merge of mismatched geometry croaks';
    like $@, qr/mismatch/, 'merge mismatch croak message';
}

# file-backed reopen: add, sync, reopen, still contains
my $path = "/tmp/bloom-basic-$$.bin";
unlink $path;
{
    my $w = Data::BloomFilter::Shared->new($path, 5000, 0.01);
    is $w->path, $path, 'file-backed path';
    $w->add_many([ map { "p-$_" } 1 .. 3000 ]);
    $w->sync;
}
{
    my $r = Data::BloomFilter::Shared->new($path, 1, 0.5);   # caller args ignored on reopen
    is $r->capacity, 5000, 'reopen: stored capacity wins';
    cmp_ok abs($r->fp_rate - 0.01), '<', 1e-9, 'reopen: stored fp_rate wins';
    ok $r->contains("p-1500"), 'reopen: membership persisted';
    my $miss = 0;
    $r->contains("p-$_") or $miss++ for 1 .. 3000;
    is $miss, 0, 'reopen: no false negatives after persistence';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::BloomFilter::Shared->new($path, 1000, 0.01); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# new_from_fd error path: a valid fd over a non-Bloom file is rejected
{
    my $jp = "/tmp/bloom-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;   # real filehandle -> fileno is valid
    print $fh "not a bloom table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::BloomFilter::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-Bloom file';
    like $@, qr/too small|invalid|Bloom/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# memfd round-trip shares the bit array
{
    my $m  = Data::BloomFilter::Shared->new_memfd('bloom', 1000, 0.01);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::BloomFilter::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->capacity, 1000, 'reopened memfd capacity';
    $m->add("shared-x");
    ok $m2->contains("shared-x"), 'new_from_fd shares the bit array';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::BloomFilter::Shared->new_memfd(undef, 100, 0.01);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# class-method unlink
my $cu = "/tmp/bloom-cu-$$.bin";
unlink $cu;
{ my $w = Data::BloomFilter::Shared->new($cu, 100, 0.01); $w->sync; }
ok -e $cu, 'backing file exists';
Data::BloomFilter::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/bloom-iu-$$.bin";
unlink $iu;
{
    my $w = Data::BloomFilter::Shared->new($iu, 100, 0.01);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# lock-leak regression: a wide-char element makes add_many croak, and a
# follow-up contains() under an alarm proves the write lock was not leaked.
{
    my $h = Data::BloomFilter::Shared->new(undef, 1000, 0.01);
    $h->add("ascii-seed");
    # codepoint > 255 (snowman) so SvPVbyte raises "Wide character"
    ok !eval { $h->add_many(["ok", "snow-\x{2603}"]); 1 }, 'add_many croaks on a wide-char element';
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
    my $i = Data::BloomFilter::Shared->new(undef, 100, 0.01);
    $i->add("x");
    $i->DESTROY;
    eval { $i->contains("x") };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
