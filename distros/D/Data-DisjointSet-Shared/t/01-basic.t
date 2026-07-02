use strict;
use warnings;
use Test::More;
use Data::DisjointSet::Shared;

# constructor + initial state: all singletons
my $N = 16;
my $d = Data::DisjointSet::Shared->new(undef, $N);
isa_ok $d, 'Data::DisjointSet::Shared';
ok !defined($d->path), 'anonymous path is undef';
is $d->capacity, $N, "capacity == $N";
is $d->num_sets, $N, "num_sets starts == capacity ($N)";
is $d->sets, $N, 'sets is an alias for num_sets';

{
    my $bad = 0;
    for my $i (0 .. $N - 1) {
        $bad++ unless $d->find($i) == $i;        # each element is its own root
        $bad++ unless $d->set_size($i) == 1;     # each set has size 1
    }
    is $bad, 0, 'initially every find(i) == i and set_size(i) == 1';

    my $connected_offdiag = 0;
    for my $i (0 .. 3) {
        for my $j (0 .. 3) {
            next if $i == $j;
            $connected_offdiag++ if $d->connected($i, $j);
        }
    }
    is $connected_offdiag, 0, 'initially connected(i,j) is false for i != j';
}

# union(0,1): returns 1 (newly merged), then they are connected
{
    my $m = $d->union(0, 1);
    is $m, 1, 'union(0,1) returns 1 (newly merged)';
    ok $d->connected(0, 1), 'connected(0,1) true after union';
    is $d->num_sets, $N - 1, 'num_sets decreased by one';
    is $d->set_size(0), 2, 'set_size(0) == 2 after union(0,1)';
    is $d->find(0), $d->find(1), 'find(0) == find(1) after union';

    my $m2 = $d->union(0, 1);
    is $m2, 0, 'union(0,1) again returns 0 (already together)';
    is $d->num_sets, $N - 1, 'num_sets unchanged after a redundant union';
}

# union by size: the larger set keeps the root
{
    my $u = Data::DisjointSet::Shared->new(undef, 10);
    # build a set {0,1,2} of size 3 rooted at find(0)
    $u->union(0, 1);
    $u->union(0, 2);
    my $big_root = $u->find(0);
    is $u->set_size(0), 3, 'big set has size 3';
    # singleton {5} of size 1; union(5, 0) must keep the size-3 root
    $u->union(5, 0);
    is $u->find(5), $big_root, 'union by size: smaller set adopts the larger set root';
    is $u->set_size(5), 4, 'merged set size is 4';
}

# a chain 0-1-2-3 connects all four
{
    my $c = Data::DisjointSet::Shared->new(undef, $N);
    $c->union(0, 1);
    $c->union(1, 2);
    $c->union(2, 3);
    ok $c->connected(0, 3), 'chain 0-1-2-3: 0 and 3 connected';
    ok $c->connected(1, 3), 'chain: 1 and 3 connected';
    is $c->num_sets, $N - 3, 'three unions reduced num_sets by 3';
    is $c->set_size(0), 4, 'chained set has size 4';
    is $c->find(0), $c->find(3), 'all four share a root';
}

# union_many merges a flat list of pairs
{
    my $c = Data::DisjointSet::Shared->new(undef, $N);
    my $merged = $c->union_many([ 0,1, 2,3, 0,2 ]);   # {0,1}+{2,3}+join -> 3 merges
    is $merged, 3, 'union_many returns the number of merges performed';
    ok $c->connected(0, 3), 'union_many: 0 and 3 connected';
    ok $c->connected(1, 2), 'union_many: 1 and 2 connected';
    is $c->set_size(0), 4, 'union_many produced a set of size 4';
    is $c->num_sets, $N - 3, 'union_many reduced num_sets by 3';

    # a redundant pair in the batch does not over-count merges
    my $c2 = Data::DisjointSet::Shared->new(undef, $N);
    my $m2 = $c2->union_many([ 0,1, 0,1, 1,2 ]);      # second 0,1 is redundant
    is $m2, 2, 'union_many counts only pairs that actually merged';

    is $c2->union_many([]), 0, 'empty union_many performs zero merges';
}

# reset -> all singletons again
{
    my $r = Data::DisjointSet::Shared->new(undef, $N);
    $r->union_many([ 0,1, 1,2, 3,4 ]);
    cmp_ok $r->num_sets, '<', $N, 'num_sets reduced before reset';
    $r->reset;
    is $r->num_sets, $N, 'reset -> num_sets == capacity';
    my $bad = 0;
    for my $i (0 .. $N - 1) {
        $bad++ unless $r->find($i) == $i && $r->set_size($i) == 1;
    }
    is $bad, 0, 'reset -> every element is a singleton again';
    # clear is an alias for reset
    $r->union(0, 1);
    $r->clear;
    is $r->num_sets, $N, 'clear is an alias for reset';
}

# stats keys
{
    my $s = Data::DisjointSet::Shared->new(undef, $N);
    $s->union_many([ 0,1, 2,3 ]);
    my $st = $s->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_" for qw(capacity sets ops mmap_size);
    is $st->{capacity}, $N, 'stats capacity matches';
    is $st->{sets}, $s->num_sets, 'stats sets matches num_sets';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the writes';
    cmp_ok $st->{mmap_size}, '>', 0, 'stats mmap_size > 0';
}

# ---- error paths ----

# constructor: n == 0 rejected
ok !eval { Data::DisjointSet::Shared->new(undef, 0); 1 }, 'new(0) croaks';
like $@, qr/n must be/, 'new(0) croak mentions n';
ok !eval { Data::DisjointSet::Shared->new_memfd('x', 0); 1 }, 'new_memfd(0) croaks';
like $@, qr/n must be/, 'new_memfd(0) croak mentions n';

# out-of-range indices croak (n is a valid index just past the end)
{
    my $g = Data::DisjointSet::Shared->new(undef, $N);
    ok !eval { $g->find($N); 1 }, 'find(n) out of range croaks';
    like $@, qr/out of range/, 'find over-range croak message';
    ok !eval { $g->union($N, 0); 1 }, 'union(n,0) out of range croaks';
    like $@, qr/out of range/, 'union over-range croak message';
    ok !eval { $g->union(0, $N); 1 }, 'union(0,n) out of range croaks';
    ok !eval { $g->connected(0, $N); 1 }, 'connected(0,n) out of range croaks';
    ok !eval { $g->connected($N, 0); 1 }, 'connected(n,0) first-arg out of range croaks';
    like $@, qr/out of range/, 'connected over-range croak message';
    ok !eval { $g->set_size($N); 1 }, 'set_size(n) out of range croaks';
    like $@, qr/out of range/, 'set_size over-range croak message';
}

# union_many: odd length croaks
{
    my $g = Data::DisjointSet::Shared->new(undef, $N);
    ok !eval { $g->union_many([0, 1, 2]); 1 }, 'union_many odd-length croaks';
    like $@, qr/even number/, 'union_many odd-length croak message';
    ok !eval { $g->union_many("notaref"); 1 }, 'union_many non-arrayref croaks';
    like $@, qr/array reference/, 'union_many non-arrayref croak message';
}

# union_many: an out-of-range index croaks BEFORE any union (atomic batch)
{
    my $g = Data::DisjointSet::Shared->new(undef, $N);
    my $before = $g->num_sets;
    ok !eval { $g->union_many([0,1, 2,$N, 3,4]); 1 },
        'union_many with an out-of-range index croaks';
    like $@, qr/out of range/, 'union_many over-range croak message';
    is $g->num_sets, $before, 'union_many is atomic: no partial unions applied';
    ok !$g->connected(0, 1), 'the leading valid pair was NOT unioned (batch rejected whole)';
}

# reopen persists the partition
my $path = "/tmp/dsu-basic-$$.bin";
unlink $path;
{
    my $w = Data::DisjointSet::Shared->new($path, $N);
    is $w->path, $path, 'file-backed path';
    $w->union_many([ 0,1, 1,2, 5,6 ]);
    is $w->num_sets, $N - 3, 'writer reduced num_sets by 3';
    $w->sync;
}
{
    my $r = Data::DisjointSet::Shared->new($path, $N);
    is $r->capacity, $N, 'reopen: capacity persisted';
    is $r->num_sets, $N - 3, 'reopen: num_sets persisted';
    ok $r->connected(0, 2), 'reopen: 0-1-2 partition persisted';
    ok $r->connected(5, 6), 'reopen: 5-6 partition persisted';
    ok !$r->connected(0, 5), 'reopen: disjoint sets stay disjoint';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::DisjointSet::Shared->new($path, $N); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# class-method unlink
my $cu = "/tmp/dsu-cu-$$.bin";
unlink $cu;
{ my $w = Data::DisjointSet::Shared->new($cu, 8); $w->sync; }
ok -e $cu, 'backing file exists';
Data::DisjointSet::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/dsu-iu-$$.bin";
unlink $iu;
{
    my $w = Data::DisjointSet::Shared->new($iu, 8);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# memfd round-trip shares the partition
{
    my $m  = Data::DisjointSet::Shared->new_memfd('dsu', $N);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::DisjointSet::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->capacity, $m->capacity, 'reopened memfd capacity matches';
    $m->union(3, 4);
    ok $m2->connected(3, 4), 'new_from_fd shares the partition';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::DisjointSet::Shared->new_memfd(undef, 8);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# new_from_fd rejects a non-DSU file
{
    my $jp = "/tmp/dsu-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;
    print $fh "not a disjoint-set table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::DisjointSet::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-DSU file';
    like $@, qr/too small|invalid|disjoint/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# lock-leak regression: a union_many with an out-of-range element croaks BEFORE
# locking, and a follow-up find() under an alarm proves the write lock was not
# leaked (the croak must have happened before the lock was taken).
{
    my $g = Data::DisjointSet::Shared->new(undef, $N);
    $g->union(0, 1);
    ok !eval { $g->union_many([2,3, 4,$N, 5,6]); 1 },
        'union_many croaks on an out-of-range element';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        my $root = $g->find(2);     # takes the write lock -- would hang if leaked
        alarm 0;
        $root;
    };
    is $survived, 2, 'write lock not leaked: find works after the caught union_many croak';
}

# DESTROY nulls the handle: use-after-destroy croaks, double DESTROY is a no-op
{
    my $i = Data::DisjointSet::Shared->new(undef, $N);
    $i->union(0, 1);
    $i->DESTROY;
    eval { $i->find(0) };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
