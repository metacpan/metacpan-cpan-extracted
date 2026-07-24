use strict;
use warnings;
use Test::More;
use Data::Fenwick::Shared;

# constructor + size
my $f = Data::Fenwick::Shared->new(undef, 16);
isa_ok $f, 'Data::Fenwick::Shared';
is $f->size, 16, 'size == n';
is $f->capacity, 16, 'capacity == n';
ok !defined($f->path), 'anonymous path is undef';

# fresh tree is all zeros
is $f->prefix(16), 0, 'prefix of empty tree is 0';
is $f->total, 0, 'total of empty tree is 0';
is $f->point(1), 0, 'point of empty tree is 0';
is $f->prefix(0), 0, 'prefix(0) is 0';

# update + prefix/point
$f->update(5, 3);
$f->update(9, 7);
is $f->point(5), 3, 'point(5) == 3';
is $f->point(9), 7, 'point(9) == 7';
is $f->point(6), 0, 'point(6) == 0';
is $f->prefix(4), 0, 'prefix(4) == 0';
is $f->prefix(5), 3, 'prefix(5) == 3';
is $f->prefix(8), 3, 'prefix(8) == 3';
is $f->prefix(9), 10, 'prefix(9) == 10';
is $f->prefix(16), 10, 'prefix(16) == 10';
is $f->total, 10, 'total == 10';

# range
is $f->range(5, 9), 10, 'range(5,9) == 10';
is $f->range(1, 4), 0, 'range(1,4) == 0';
is $f->range(6, 8), 0, 'range(6,8) == 0';
is $f->range(9, 9), 7, 'range(9,9) == point(9)';

# negative delta
$f->update(9, -2);
is $f->point(9), 5, 'negative delta: point(9) == 5';
is $f->total, 8, 'total after negative delta == 8';

# set returns old value and overwrites
{
    my $old = $f->set(5, 100);
    is $old, 3, 'set returns the previous value';
    is $f->point(5), 100, 'set overwrites the value';
    is $f->total, 105, 'total reflects the set (100 + 5)';
    $f->set(5, 0);
    is $f->point(5), 0, 'set to 0 works';
    is $f->total, 5, 'total back to 5';
}

# oracle: compare against a naive array over a churn of updates
{
    my $n = 200;
    my $h = Data::Fenwick::Shared->new(undef, $n);
    my @a = (0) x ($n + 1);   # 1-indexed naive array
    # deterministic pseudo-updates (fixed, no RNG)
    for my $step (1 .. 1000) {
        my $i = ($step * 37) % $n + 1;
        my $d = (($step * 13) % 21) - 10;   # -10..10
        $h->update($i, $d);
        $a[$i] += $d;
    }
    # verify every prefix matches the naive cumulative sum
    my ($mismatch, $cum) = (0, 0);
    for my $i (1 .. $n) {
        $cum += $a[$i];
        $mismatch++ if $h->prefix($i) != $cum;
    }
    is $mismatch, 0, "prefix sums match a naive array across 1000 updates";
    # random-ish range checks
    my $rmis = 0;
    for my $t (1 .. 100) {
        my $l = ($t * 7) % $n + 1;
        my $r = $l + ($t * 3) % ($n - $l + 1);
        my $want = 0; $want += $a[$_] for $l .. $r;
        $rmis++ if $h->range($l, $r) != $want;
    }
    is $rmis, 0, "range sums match the naive array";
}

# find: smallest position with prefix >= target (weights are non-negative here)
{
    my $w = Data::Fenwick::Shared->new(undef, 10);
    $w->update(2, 5);    # cumulative: pos2=5
    $w->update(5, 3);    # pos5 -> 8
    $w->update(8, 2);    # pos8 -> 10
    is $w->find(1), 2,  'find(1) -> first nonzero prefix at 2';
    is $w->find(5), 2,  'find(5) -> 2 (prefix(2)==5)';
    is $w->find(6), 5,  'find(6) -> 5 (prefix(5)==8)';
    is $w->find(8), 5,  'find(8) -> 5';
    is $w->find(9), 8,  'find(9) -> 8 (prefix(8)==10)';
    is $w->find(10), 8, 'find(10) -> 8';
    is $w->find(11), 11, 'find(target>total) -> n+1';
}

# clear
{
    my $c = Data::Fenwick::Shared->new(undef, 8);
    $c->update($_, $_) for 1 .. 8;
    cmp_ok $c->total, '>', 0, 'nonzero before clear';
    $c->clear;
    is $c->total, 0, 'clear -> total 0';
    is $c->prefix(8), 0, 'clear -> prefix 0';
}

# stats
{
    my $s = Data::Fenwick::Shared->new(undef, 100);
    $s->update(10, 4); $s->update(20, 6);
    my $st = $s->stats;
    is ref($st), 'HASH', 'stats is a hashref';
    is $st->{size}, 100, 'stats size';
    is $st->{total}, 10, 'stats total';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the updates';
    ok exists $st->{mmap_size}, 'stats has mmap_size';
}

# merge: element-wise add of two equal-size trees
{
    my $a = Data::Fenwick::Shared->new(undef, 10);
    my $b = Data::Fenwick::Shared->new(undef, 10);
    $a->update(3, 5); $a->update(7, 2);
    $b->update(3, 1); $b->update(9, 4);
    $a->merge($b);
    is $a->point(3), 6, 'merge adds position 3 (5+1)';
    is $a->point(7), 2, 'merge keeps a-only position 7';
    is $a->point(9), 4, 'merge brings in b-only position 9';
    is $a->total, 12, 'merge total (5+2 + 1+4)';
    # size mismatch croaks
    my $c = Data::Fenwick::Shared->new(undef, 20);
    ok !eval { $a->merge($c); 1 }, 'merge of mismatched size croaks';
    like $@, qr/size mismatch/, 'merge mismatch message';
}

# error paths
ok !eval { Data::Fenwick::Shared->new(undef, 0); 1 }, 'n == 0 rejected';
like $@, qr/must be >= 1/, 'n 0 croak message';
{
    my $e = Data::Fenwick::Shared->new(undef, 10);
    ok !eval { $e->update(0, 1); 1 },  'update position 0 croaks';
    like $@, qr/out of range/, 'update 0 croak message';
    ok !eval { $e->update(11, 1); 1 }, 'update position n+1 croaks';
    ok !eval { $e->point(0); 1 },      'point 0 croaks';
    ok !eval { $e->range(0, 5); 1 },   'range l<1 croaks';
    ok !eval { $e->range(5, 3); 1 },   'range l>r croaks';
    ok !eval { $e->range(1, 11); 1 },  'range r>n croaks';
    is $e->prefix(0), 0, 'prefix(0) is allowed and 0';
    ok !eval { $e->prefix(11); 1 },    'prefix > n croaks';
}

# file-backed reopen: updates persist, stored n wins
my $path = "/tmp/fen-basic-$$.bin";
unlink $path;
{
    my $w = Data::Fenwick::Shared->new($path, 50);
    is $w->path, $path, 'file-backed path';
    $w->update($_, $_ * 2) for 1 .. 50;
    $w->sync;
}
{
    my $r = Data::Fenwick::Shared->new($path, 1);   # caller n ignored on reopen
    is $r->size, 50, 'reopen: stored n wins';
    is $r->total, 2550, 'reopen: values persisted (2*(1+..+50))';
    is $r->prefix(10), 110, 'reopen: prefix persisted (2*(1+..+10))';
}
# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::Fenwick::Shared->new($path, 50); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the tree
{
    my $m  = Data::Fenwick::Shared->new_memfd('fen', 100);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::Fenwick::Shared->new_from_fd($fd);
    is $m2->size, 100, 'reopened memfd size';
    $m->update(42, 9);
    is $m2->point(42), 9, 'new_from_fd shares the tree';
    ok !defined($m2->path), 'new_from_fd path is undef';
}

# class-method + instance unlink
my $cu = "/tmp/fen-cu-$$.bin";
unlink $cu;
{ my $w = Data::Fenwick::Shared->new($cu, 10); $w->sync; }
ok -e $cu, 'backing file exists';
Data::Fenwick::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY nulls the handle
{
    my $i = Data::Fenwick::Shared->new(undef, 10);
    $i->update(1, 1);
    $i->DESTROY;
    eval { $i->total };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
