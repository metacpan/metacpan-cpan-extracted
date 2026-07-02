use strict;
use warnings;
use Test::More;
use Data::CountMinSketch::Shared;

# constructors: default epsilon/delta, and explicit
my $cms = Data::CountMinSketch::Shared->new(undef);
isa_ok $cms, 'Data::CountMinSketch::Shared';
ok !defined($cms->path), 'anonymous path is undef';

my $cms2 = Data::CountMinSketch::Shared->new(undef, 0.0001, 0.0001);
# tighter epsilon -> wider; tighter delta -> deeper
cmp_ok $cms2->width, '>', $cms->width, 'tighter epsilon uses a wider matrix';
cmp_ok $cms2->depth, '>=', $cms->depth, 'tighter delta uses at least as many rows';

# geometry sanity: width a power of two, depth in [1,32]
my $w = $cms->width;
ok $w >= 2, 'width >= 2';
is $w & ($w - 1), 0, 'width is a power of two';
cmp_ok $cms->depth, '>=', 1, 'depth >= 1';
cmp_ok $cms->depth, '<=', 32, 'depth <= 32';

# add then estimate >= 1
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    my $t = $h->add("hello");
    is $t, 1, 'add returns the new grand total (1 after one add)';
    cmp_ok $h->estimate("hello"), '>=', 1, 'estimate of an added item is >= 1';
}

# add with a count n -> estimate >= n, and total tracks it
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    my $t = $h->add("bob", 5);
    is $t, 5, 'add with count returns total 5';
    cmp_ok $h->estimate("bob"), '>=', 5, 'estimate of "bob" after add 5 is >= 5';
    my $t2 = $h->add("bob", 3);
    is $t2, 8, 'second add accumulates the total to 8';
    cmp_ok $h->estimate("bob"), '>=', 8, 'estimate of "bob" now >= 8';
}

# never underestimates: a known multiset
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    $h->add("a") for 1 .. 5;
    $h->add("b") for 1 .. 3;
    $h->add("c");
    cmp_ok $h->estimate("a"), '>=', 5, 'estimate("a") >= 5 (true count)';
    cmp_ok $h->estimate("b"), '>=', 3, 'estimate("b") >= 3 (true count)';
    cmp_ok $h->estimate("c"), '>=', 1, 'estimate("c") >= 1 (true count)';
    # a never-added item: 0 or at worst a small collision count
    my $never = $h->estimate("never-added-xyz");
    cmp_ok $never, '<=', 9, 'estimate of a never-added item is small (<= total)';
    is $h->total, 9, 'total tracks the sum of increments (5+3+1)';
}

# add_many adds one per element, returns count, accumulates total
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    my $added = $h->add_many([ map { "m-$_" } 1 .. 1000 ]);
    is $added, 1000, 'add_many reports 1000 elements added';
    is $h->total, 1000, 'add_many added 1000 to the total';
    # adding the same set again doubles each count
    $h->add_many([ map { "m-$_" } 1 .. 1000 ]);
    is $h->total, 2000, 'second add_many accumulates the total to 2000';
    cmp_ok $h->estimate("m-1"), '>=', 2, 'estimate("m-1") >= 2 after two add_many passes';
}

# stats keys + epsilon/delta sane
{
    my $h = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
    $h->add_many([ map { "s-$_" } 1 .. 500 ]);
    my $st = $h->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(width depth total cells epsilon delta ops mmap_size);
    is $st->{width}, $h->width, 'stats width matches accessor';
    is $st->{depth}, $h->depth, 'stats depth matches accessor';
    is $st->{cells}, $h->cells, 'stats cells matches accessor';
    is $st->{cells}, $st->{width} * $st->{depth}, 'cells == width * depth';
    is $st->{total}, 500, 'stats total tracks the adds';
    cmp_ok $st->{epsilon}, '>', 0, 'epsilon > 0';
    cmp_ok $st->{epsilon}, '<', 1, 'epsilon < 1';
    cmp_ok $st->{delta}, '>', 0, 'delta > 0';
    cmp_ok $st->{delta}, '<', 1, 'delta < 1';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the add_many write';
    {
        my $b4 = $h->stats->{ops};
        is $h->add_many([]), 0, 'empty add_many adds nothing';
        is $h->stats->{ops}, $b4 + 1, 'an empty add_many still counts as one write op';
        is $h->total, 500, 'empty add_many leaves the total unchanged';
    }
}

# clear -> total 0, estimate 0
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    $h->add("gone") for 1 .. 4;
    cmp_ok $h->estimate("gone"), '>=', 4, 'present before clear';
    $h->clear;
    is $h->total, 0, 'clear -> total 0';
    is $h->estimate("gone"), 0, 'clear -> estimate 0';
}

# merge: two sketches with the same epsilon/delta sum counts
{
    my $a = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
    my $b = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
    $a->add("x") for 1 .. 7;
    $b->add("x") for 1 .. 4;
    $b->add("y") for 1 .. 2;
    my $ax = $a->estimate("x");
    my $bx = $b->estimate("x");
    my $by = $b->estimate("y");
    $a->merge($b);
    is $a->estimate("x"), $ax + $bx, 'merge: estimate("x") is the sum of the two estimates';
    is $a->estimate("y"), $by, 'merge: estimate("y") picked up from b';
    is $a->total, 7 + 4 + 2, 'merge: total is the sum of the two totals';
}

# self-merge must not deadlock (snapshot releases read lock before write lock)
{
    my $s = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
    $s->add("s-$_") for 1 .. 50;
    my $before = $s->total;
    my $ok = eval { local $SIG{ALRM} = sub { die "deadlock\n" }; alarm 5; $s->merge($s); alarm 0; 1 };
    ok $ok, 'self-merge does not deadlock';
    is $s->total, 2 * $before, 'self-merge doubles every count (total doubles)';
}

# error paths: bad epsilon / delta
ok !eval { Data::CountMinSketch::Shared->new(undef, 0, 0.001); 1 }, 'epsilon 0 rejected';
like $@, qr/epsilon/, 'epsilon 0 croak mentions epsilon';
ok !eval { Data::CountMinSketch::Shared->new(undef, 1, 0.001); 1 }, 'epsilon 1 rejected';
like $@, qr/epsilon/, 'epsilon 1 croak mentions epsilon';
ok !eval { Data::CountMinSketch::Shared->new(undef, 1.5, 0.001); 1 }, 'epsilon 1.5 rejected';
like $@, qr/epsilon/, 'epsilon 1.5 croak mentions epsilon';
# an epsilon so small the column count would exceed the 2^32 cap must croak,
# not silently clamp to a worse-than-requested (and ~240 GB) sketch
ok !eval { Data::CountMinSketch::Shared->new(undef, 1e-10, 0.001); 1 }, 'too-small epsilon rejected';
like $@, qr/too small/, 'too-small epsilon croak mentions too small';
ok !eval { Data::CountMinSketch::Shared->new(undef, 0.001, 0); 1 }, 'delta 0 rejected';
like $@, qr/delta/, 'delta 0 croak mentions delta';
ok !eval { Data::CountMinSketch::Shared->new(undef, 0.001, 1); 1 }, 'delta 1 rejected';
like $@, qr/delta/, 'delta 1 croak mentions delta';

# new_memfd has the identical guards
ok !eval { Data::CountMinSketch::Shared->new_memfd('x', 0, 0.001); 1 }, 'new_memfd epsilon 0 rejected';
like $@, qr/epsilon/, 'new_memfd epsilon 0 croak mentions epsilon';
ok !eval { Data::CountMinSketch::Shared->new_memfd('x', 0.001, 1.5); 1 }, 'new_memfd delta 1.5 rejected';
like $@, qr/delta/, 'new_memfd delta 1.5 croak mentions delta';

# error path: add_many requires an array reference
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    ok !eval { $h->add_many("notaref"); 1 }, 'add_many croaks on a non-arrayref scalar';
    like $@, qr/array reference/, 'add_many non-arrayref croak mentions array reference';
    ok !eval { $h->add_many({}); 1 }, 'add_many croaks on a hashref';
    like $@, qr/array reference/, 'add_many hashref croak mentions array reference';

    # single add of a wide-char item croaks (codepoint > 255 -> SvPVbyte)
    ok !eval { $h->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char item';
    like $@, qr/[Ww]ide/, 'add wide-char croak mentions Wide character';
}

# error path: merge of mismatched geometry croaks
{
    my $a = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
    my $b = Data::CountMinSketch::Shared->new(undef, 0.01, 0.01);   # different w/d
    ok !eval { $a->merge($b); 1 }, 'merge of mismatched geometry croaks';
    like $@, qr/mismatch/, 'merge mismatch croak message';
}

# file-backed reopen: add, sync, reopen, estimate persists
my $path = "/tmp/cms-basic-$$.bin";
unlink $path;
{
    my $w = Data::CountMinSketch::Shared->new($path, 0.001, 0.001);
    is $w->path, $path, 'file-backed path';
    $w->add("p-$_") for 1 .. 3000;
    $w->add("hot") for 1 .. 42;
    $w->sync;
}
{
    my $r = Data::CountMinSketch::Shared->new($path, 0.5, 0.5);   # caller args ignored on reopen
    cmp_ok $r->estimate("hot"), '>=', 42, 'reopen: estimate persisted';
    is $r->total, 3000 + 42, 'reopen: total persisted';
    my $miss = 0;
    $r->estimate("p-$_") >= 1 or $miss++ for 1 .. 3000;
    is $miss, 0, 'reopen: every added key still estimates >= 1';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::CountMinSketch::Shared->new($path, 0.001, 0.001); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# new_from_fd error path: a valid fd over a non-CMS file is rejected
{
    my $jp = "/tmp/cms-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;   # real filehandle -> fileno is valid
    print $fh "not a count-min sketch table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::CountMinSketch::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-CMS file';
    like $@, qr/too small|invalid|sketch/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# memfd round-trip shares the matrix
{
    my $m  = Data::CountMinSketch::Shared->new_memfd('cms', 0.001, 0.001);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::CountMinSketch::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->width, $m->width, 'reopened memfd width matches';
    $m->add("shared-x") for 1 .. 3;
    cmp_ok $m2->estimate("shared-x"), '>=', 3, 'new_from_fd shares the counter matrix';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::CountMinSketch::Shared->new_memfd(undef, 0.01, 0.01);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# class-method unlink
my $cu = "/tmp/cms-cu-$$.bin";
unlink $cu;
{ my $w = Data::CountMinSketch::Shared->new($cu, 0.01, 0.01); $w->sync; }
ok -e $cu, 'backing file exists';
Data::CountMinSketch::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/cms-iu-$$.bin";
unlink $iu;
{
    my $w = Data::CountMinSketch::Shared->new($iu, 0.01, 0.01);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# lock-leak regression: a wide-char element makes add_many croak, and a
# follow-up estimate() under an alarm proves the write lock was not leaked.
{
    my $h = Data::CountMinSketch::Shared->new(undef);
    $h->add("ascii-seed");
    # codepoint > 255 (snowman) so SvPVbyte raises "Wide character"
    ok !eval { $h->add_many(["ok", "snow-\x{2603}"]); 1 }, 'add_many croaks on a wide-char element';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $e = $h->estimate("ascii-seed");
        alarm 0;
        1;
    };
    ok $survived, 'write lock not leaked: estimate works after the caught add_many croak';
}

# DESTROY nulls the handle: use-after-destroy croaks, double DESTROY is a no-op
{
    my $i = Data::CountMinSketch::Shared->new(undef);
    $i->add("x");
    $i->DESTROY;
    eval { $i->estimate("x") };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
