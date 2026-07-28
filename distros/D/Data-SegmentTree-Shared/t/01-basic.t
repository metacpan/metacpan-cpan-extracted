use strict;
use warnings;
use Test::More;
use Data::SegmentTree::Shared;

# constructor + introspection
{
    my $st = Data::SegmentTree::Shared->new(undef, 100);
    isa_ok $st, 'Data::SegmentTree::Shared';
    is $st->size, 100, 'size == n';
    is $st->get(0), 0, 'fresh: position 0 is 0';
    is $st->get(99), 0, 'fresh: last position is 0';
    is $st->sum(0, 99), 0, 'fresh: sum over all is 0';
    is $st->min(0, 99), 0, 'fresh: min is 0';
    is $st->max(0, 99), 0, 'fresh: max is 0';
}

# set / add / get
{
    my $st = Data::SegmentTree::Shared->new(undef, 10);
    $st->set(3, 42);
    is $st->get(3), 42, 'set then get';
    is $st->add(3, 5), 47, 'add returns the new value';
    is $st->get(3), 47, 'add persisted';
    $st->set(3, -100);
    is $st->get(3), -100, 'set to a negative value';
    is $st->add(3, 100), 0, 'add back to zero';
}

# range aggregates
{
    my $st = Data::SegmentTree::Shared->new(undef, 10);
    $st->set($_, $_ + 1) for 0 .. 9;    # 1,2,...,10
    is $st->sum(0, 9), 55, 'sum 1..10';
    is $st->min(0, 9), 1, 'min 1..10';
    is $st->max(0, 9), 10, 'max 1..10';
    is $st->sum(2, 4), 3 + 4 + 5, 'partial-range sum';
    is $st->min(2, 4), 3, 'partial-range min';
    is $st->max(2, 4), 5, 'partial-range max';
    is $st->sum(5, 5), 6, 'single-element sum';

    my $q = $st->query(0, 9);
    is ref($q), 'HASH', 'query returns a hashref';
    is $q->{sum}, 55, 'query sum';
    is $q->{min}, 1, 'query min';
    is $q->{max}, 10, 'query max';
    is $q->{count}, 10, 'query count';
}

# range_add (lazy propagation)
{
    my $st = Data::SegmentTree::Shared->new(undef, 100);
    $st->range_add(0, 99, 5);           # every position += 5
    is $st->get(0), 5, 'range_add reached position 0';
    is $st->get(50), 5, 'range_add reached the middle';
    is $st->get(99), 5, 'range_add reached the last';
    is $st->sum(0, 99), 500, 'range_add: sum is n*5';

    $st->range_add(10, 19, 100);        # a sub-range gets +100
    is $st->get(9), 5, 'position just below the sub-range unchanged';
    is $st->get(10), 105, 'sub-range start updated';
    is $st->get(19), 105, 'sub-range end updated';
    is $st->get(20), 5, 'position just above the sub-range unchanged';
    is $st->max(0, 99), 105, 'max reflects the sub-range bump';
    is $st->min(0, 99), 5, 'min unchanged outside the sub-range';
    is $st->sum(10, 19), (105) * 10, 'sub-range sum after the bump';

    # overlapping range_adds accumulate
    $st->range_add(15, 25, 1);
    is $st->get(15), 106, 'overlapping range_add accumulates (inside both)';
    is $st->get(20), 6, 'overlapping range_add (only the second range)';
}

# brute-force cross-check: random mix of ops vs a plain Perl array
{
    my $n = 89;
    my $st = Data::SegmentTree::Shared->new(undef, $n);
    my @ref = (0) x $n;
    srand(1234);
    my $mismatch = '';
    for my $iter (1 .. 8000) {
        my $op = int rand 5;
        if ($op == 0) {                                  # set
            my $i = int rand $n; my $v = int(rand 401) - 200;
            $st->set($i, $v); $ref[$i] = $v;
        } elsif ($op == 1) {                             # add
            my $i = int rand $n; my $d = int(rand 41) - 20;
            my $got = $st->add($i, $d); $ref[$i] += $d;
            $mismatch ||= "add($i) got $got want $ref[$i]" if $got != $ref[$i];
        } elsif ($op == 2) {                             # range_add
            my ($l, $r) = sort { $a <=> $b } (int rand $n, int rand $n);
            my $d = int(rand 41) - 20;
            $st->range_add($l, $r, $d); $ref[$_] += $d for $l .. $r;
        } else {                                         # query
            my ($l, $r) = sort { $a <=> $b } (int rand $n, int rand $n);
            my $q = $st->query($l, $r);
            my ($s, $mn, $mx) = (0, 9e18, -9e18);
            for ($l .. $r) { $s += $ref[$_]; $mn = $ref[$_] if $ref[$_] < $mn; $mx = $ref[$_] if $ref[$_] > $mx }
            $mismatch ||= "query[$l,$r] sum $q->{sum}/$s min $q->{min}/$mn max $q->{max}/$mx"
                if $q->{sum} != $s || $q->{min} != $mn || $q->{max} != $mx || $q->{count} != $r - $l + 1;
        }
        last if $mismatch;
    }
    is $mismatch, '', '8000-op random cross-check against a brute-force array'
        or diag $mismatch;
    my $getbad = 0;
    $getbad++ for grep { $st->get($_) != $ref[$_] } 0 .. $n - 1;
    is $getbad, 0, 'final per-position values match the reference';
}

# clear
{
    my $st = Data::SegmentTree::Shared->new(undef, 50);
    $st->range_add(0, 49, 7);
    $st->clear;
    is $st->sum(0, 49), 0, 'clear resets the sum';
    is $st->max(0, 49), 0, 'clear resets values';
    $st->set(5, 3);
    is $st->get(5), 3, 'usable after clear';
}

# stats
{
    my $st = Data::SegmentTree::Shared->new(undef, 1000);
    $st->set(0, 1);
    my $s = $st->stats;
    is ref($s), 'HASH', 'stats hashref';
    is $s->{n}, 1000, 'stats n';
    is $s->{size}, 1000, 'stats size';
    is $s->{tree_size}, 1024, 'stats tree_size (next pow2)';
    cmp_ok $s->{ops}, '>', 0, 'stats ops';
    ok exists $s->{mmap_size}, 'stats mmap_size';
}

# n = 1 edge
{
    my $one = Data::SegmentTree::Shared->new(undef, 1);
    $one->set(0, 99);
    is $one->get(0), 99, 'n=1 get';
    is $one->sum(0, 0), 99, 'n=1 sum';
    is $one->min(0, 0), 99, 'n=1 min';
    is $one->max(0, 0), 99, 'n=1 max';
    $one->range_add(0, 0, 1);
    is $one->get(0), 100, 'n=1 range_add';
}

# error paths
ok !eval { Data::SegmentTree::Shared->new(undef, 0); 1 }, 'n == 0 rejected';
like $@, qr/>= 1|between/, 'n 0 croak';
{
    my $st = Data::SegmentTree::Shared->new(undef, 10);
    ok !eval { $st->get(10); 1 }, 'get out of range croaks';
    like $@, qr/out of range/, 'oob croak message';
    ok !eval { $st->set(10, 1); 1 }, 'set out of range croaks';
    ok !eval { $st->sum(0, 10); 1 }, 'sum out of range croaks';
    ok !eval { $st->range_add(5, 2, 1); 1 }, 'range_add with l > r croaks';
    like $@, qr/l.*>.*r/, 'l>r croak';
    ok !eval { $st->query(3, 1); 1 }, 'query with l > r croaks';
}

# file-backed reopen: stored n wins, contents persist
my $path = "/tmp/st-basic-$$.bin";
unlink $path;
{
    my $w = Data::SegmentTree::Shared->new($path, 200);
    is $w->path, $path, 'file-backed path';
    $w->set($_, $_ * 2) for 0 .. 199;
    $w->range_add(0, 99, 10);
    $w->sync;
}
{
    my $r = Data::SegmentTree::Shared->new($path, 5);   # caller n ignored on reopen
    is $r->size, 200, 'reopen: stored n wins';
    is $r->get(0), 10, 'reopen: value persisted (0*2 + 10)';
    is $r->get(50), 110, 'reopen: value persisted (50*2 + 10)';
    is $r->get(100), 200, 'reopen: value outside the range_add persisted';
    is $r->sum(0, 199), 40800, 'reopen: queries work (2*sum(0..199) + 10*100)';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::SegmentTree::Shared->new($path, 200); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the array
{
    my $m  = Data::SegmentTree::Shared->new_memfd('st', 50);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::SegmentTree::Shared->new_from_fd($fd);
    is $m2->size, 50, 'reopened memfd size';
    $m->set(7, 123);
    is $m2->get(7), 123, 'new_from_fd shares the array';
    $m2->range_add(0, 49, 1);
    is $m->get(7), 124, 'updates via one handle visible via the other';
}

# class-method unlink
my $cu = "/tmp/st-cu-$$.bin";
unlink $cu;
{ my $w = Data::SegmentTree::Shared->new($cu, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::SegmentTree::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::SegmentTree::Shared->new(undef, 8);
    $i->set(0, 1);
    $i->DESTROY;
    eval { $i->get(0) };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
