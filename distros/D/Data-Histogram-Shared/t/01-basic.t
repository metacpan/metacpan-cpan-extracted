use strict;
use warnings;
use Test::More;
use Data::Histogram::Shared;

# constructors: defaults, and explicit lowest/highest/sig
my $h = Data::Histogram::Shared->new(undef);
isa_ok $h, 'Data::Histogram::Shared';
ok !defined($h->path), 'anonymous path is undef';
is $h->sig_figs, 3, 'default sig_figs is 3';
is $h->lowest, 1, 'default lowest is 1';

my $h2 = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
is $h2->lowest, 1, 'explicit lowest';
is $h2->highest, 1_000_000, 'explicit highest';
is $h2->sig_figs, 3, 'explicit sig_figs';
cmp_ok $h2->counts_len, '>', 0, 'counts_len > 0';

# more sig figs -> more counts (finer resolution)
{
    my $a = Data::Histogram::Shared->new(undef, 1, 1_000_000, 2);
    my $b = Data::Histogram::Shared->new(undef, 1, 1_000_000, 4);
    cmp_ok $b->counts_len, '>', $a->counts_len, 'higher sig_figs uses more counts';
}

# record then count_at_value >= 1
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my $t = $g->record(1234);
    is $t, 1, 'record returns the new total_count (1 after one record)';
    cmp_ok $g->count_at_value(1234), '>=', 1, 'count_at_value of a recorded value is >= 1';
}

# record a known multiset: min/max exact, count == sum
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my @vals = (5, 5, 5, 17, 17, 42, 1000, 999999);
    $g->record($_) for @vals;
    is $g->total_count, scalar(@vals), 'total_count == number of recorded values';
    is $g->min, 5, 'min is exact (5)';
    is $g->max, 999999, 'max is exact (999999)';
}

# equivalence contract: record V, value_at_percentile(100) is in [V, highest_equiv(V)]
{
    for my $v (1, 100, 999, 12345, 999999) {
        my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
        $g->record($v);
        my $p100 = $g->value_at_percentile(100);
        cmp_ok $p100, '>=', $v, "value_at_percentile(100) >= recorded value ($v)";
        # within 1/10^3 = 0.1% relative error (HdrHistogram precision contract)
        my $rel = abs($p100 - $v) / $v;
        cmp_ok $rel, '<=', 0.001, "value_at_percentile(100) within 0.1% of $v (rel $rel)";
    }
}

# percentiles are monotonic; mean in [min,max]
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record($_) for 1 .. 10000;
    my ($p10, $p50, $p90, $p99, $p100) =
        map { $g->value_at_percentile($_) } (10, 50, 90, 99, 100);
    cmp_ok $p10, '<=', $p50, 'p10 <= p50';
    cmp_ok $p50, '<=', $p90, 'p50 <= p90';
    cmp_ok $p90, '<=', $p99, 'p90 <= p99';
    cmp_ok $p99, '<=', $p100, 'p99 <= p100';
    my $m = $g->mean;
    cmp_ok $m, '>=', $g->min, 'mean >= min';
    cmp_ok $m, '<=', $g->max, 'mean <= max';
}

# record with a count n
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my $t = $g->record(700, 5);
    is $t, 5, 'record with count returns total_count 5';
    is $g->count_at_value(700), 5, 'count_at_value reflects the n recorded';
    my $t2 = $g->record(700, 3);
    is $t2, 8, 'second record accumulates total_count to 8';
    is $g->count_at_value(700), 8, 'count_at_value now 8';
}

# percentile alias
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record($_) for 1 .. 1000;
    is $g->percentile(50), $g->value_at_percentile(50), 'percentile is an alias for value_at_percentile';
    is $g->count, $g->total_count, 'count is an alias for total_count';
}

# reset -> count 0, min/max reset
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record(500) for 1 .. 4;
    cmp_ok $g->count_at_value(500), '>=', 4, 'present before reset';
    $g->reset;
    is $g->total_count, 0, 'reset -> total_count 0';
    is $g->min, 0, 'reset -> min 0';
    is $g->max, 0, 'reset -> max 0';
    is $g->value_at_percentile(50), 0, 'reset -> empty percentile is 0';
}

# record_many adds one per element, returns count, accumulates total
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my $added = $g->record_many([ map { $_ * 10 } 1 .. 1000 ]);
    is $added, 1000, 'record_many reports 1000 elements recorded';
    is $g->total_count, 1000, 'record_many recorded 1000';
    is $g->record_many([]), 0, 'empty record_many records nothing';
    is $g->total_count, 1000, 'empty record_many leaves total unchanged';
}

# stats keys
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record_many([ map { $_ } 1 .. 500 ]);
    my $st = $g->stats;
    is ref($st), 'HASH', 'stats returns a hashref';
    ok exists $st->{$_}, "stats has $_"
        for qw(lowest highest sig_figs count min max mean counts_len bucket_count sub_bucket_count ops mmap_size);
    is $st->{lowest}, $g->lowest, 'stats lowest matches accessor';
    is $st->{highest}, $g->highest, 'stats highest matches accessor';
    is $st->{sig_figs}, $g->sig_figs, 'stats sig_figs matches accessor';
    is $st->{counts_len}, $g->counts_len, 'stats counts_len matches accessor';
    is $st->{count}, 500, 'stats count tracks the records';
    is $st->{min}, 1, 'stats min';
    is $st->{max}, 500, 'stats max';
    cmp_ok $st->{mean}, '>', 0, 'stats mean > 0';
    cmp_ok $st->{bucket_count}, '>', 0, 'stats bucket_count > 0';
    cmp_ok $st->{sub_bucket_count}, '>', 0, 'stats sub_bucket_count > 0';
    cmp_ok $st->{ops}, '>', 0, 'stats ops counted the record_many write';
    {
        my $b4 = $g->stats->{ops};
        $g->record_many([]);
        is $g->stats->{ops}, $b4 + 1, 'an empty record_many still counts as one write op';
    }
}

# merge (same geometry) combines distributions
{
    my $a = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my $b = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $a->record(100) for 1 .. 7;
    $b->record(100) for 1 .. 4;
    $b->record(900) for 1 .. 2;
    $a->merge($b);
    is $a->total_count, 13, 'merge: total_count is the sum of the two';
    cmp_ok $a->count_at_value(100), '>=', 11, 'merge: count at 100 combined (7+4)';
    cmp_ok $a->count_at_value(900), '>=', 2, 'merge: count at 900 picked up from b';
    is $a->max, 900, 'merge: max spans both';
    is $a->min, 100, 'merge: min spans both';
}

# self-merge must not deadlock (snapshot releases read lock before write lock)
{
    my $s = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $s->record($_ * 7) for 1 .. 50;
    my $before = $s->total_count;
    my $ok = eval { local $SIG{ALRM} = sub { die "deadlock\n" }; alarm 5; $s->merge($s); alarm 0; 1 };
    ok $ok, 'self-merge does not deadlock';
    is $s->total_count, 2 * $before, 'self-merge doubles every count (total doubles)';
}

# error paths: constructor argument validation
ok !eval { Data::Histogram::Shared->new(undef, 0, 1000, 3); 1 }, 'lowest 0 rejected';
like $@, qr/lowest/, 'lowest 0 croak mentions lowest';
ok !eval { Data::Histogram::Shared->new(undef, 1000, 1999, 3); 1 }, 'highest < 2*lowest rejected';
like $@, qr/highest/, 'highest < 2*lowest croak mentions highest';
ok !eval { Data::Histogram::Shared->new(undef, 1, 1000, 0); 1 }, 'sig_figs 0 rejected';
like $@, qr/sig_figs/, 'sig_figs 0 croak mentions sig_figs';
ok !eval { Data::Histogram::Shared->new(undef, 1, 1000, 6); 1 }, 'sig_figs 6 rejected';
like $@, qr/sig_figs/, 'sig_figs 6 croak mentions sig_figs';

# new_memfd has the identical guards
ok !eval { Data::Histogram::Shared->new_memfd('x', 0, 1000, 3); 1 }, 'new_memfd lowest 0 rejected';
like $@, qr/lowest/, 'new_memfd lowest 0 croak mentions lowest';
ok !eval { Data::Histogram::Shared->new_memfd('x', 1, 1000, 6); 1 }, 'new_memfd sig_figs 6 rejected';
like $@, qr/sig_figs/, 'new_memfd sig_figs 6 croak mentions sig_figs';

# error paths: record value out of range
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    ok !eval { $g->record(-1); 1 }, 'record negative value croaks';
    like $@, qr/negative/, 'record negative croak mentions negative';
    ok !eval { $g->record(2_000_000); 1 }, 'record value > highest croaks';
    like $@, qr/exceeds|highest/, 'record over-range croak mentions highest';
    ok !eval { $g->record_many("notaref"); 1 }, 'record_many croaks on a non-arrayref scalar';
    like $@, qr/array reference/, 'record_many non-arrayref croak mentions array reference';
    ok !eval { $g->record_many({}); 1 }, 'record_many croaks on a hashref';
    like $@, qr/array reference/, 'record_many hashref croak mentions array reference';
    ok !eval { $g->record_many([10, 20, 9_000_000]); 1 }, 'record_many croaks on an out-of-range element';
    like $@, qr/exceeds|highest/, 'record_many over-range croak mentions highest';
}

# error path: merge of mismatched geometry croaks
{
    my $a = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my $b = Data::Histogram::Shared->new(undef, 1, 1_000_000, 2);   # different sig -> different geometry
    ok !eval { $a->merge($b); 1 }, 'merge of mismatched geometry croaks';
    like $@, qr/mismatch/, 'merge mismatch croak message';
    my $c = Data::Histogram::Shared->new(undef, 1, 2_000_000, 3);   # different highest
    ok !eval { $a->merge($c); 1 }, 'merge of mismatched highest croaks';
    like $@, qr/mismatch/, 'merge mismatch (highest) croak message';
}

# file-backed reopen: record, sync, reopen, query persists
my $path = "/tmp/hist-basic-$$.bin";
unlink $path;
{
    my $w = Data::Histogram::Shared->new($path, 1, 1_000_000, 3);
    is $w->path, $path, 'file-backed path';
    $w->record($_) for 1 .. 10000;
    $w->record(424242) for 1 .. 5;
    $w->sync;
}
{
    my $r = Data::Histogram::Shared->new($path, 1, 1_000_000, 3);   # matching geometry
    is $r->total_count, 10005, 'reopen: total_count persisted';
    is $r->max, 424242, 'reopen: max persisted';
    cmp_ok $r->count_at_value(424242), '>=', 5, 'reopen: count persisted';
}
{
    # reopen with DIFFERENT geometry: the stored geometry wins and the caller's
    # args are ignored (no croak, no re-shaping) -- documents the POD contract
    my $r = Data::Histogram::Shared->new($path, 1, 9_000_000, 5);
    is $r->highest,  1_000_000, 'reopen mismatch: stored highest wins (caller arg ignored)';
    is $r->sig_figs, 3,         'reopen mismatch: stored sig_figs wins (caller arg ignored)';
    is $r->total_count, 10005,  'reopen mismatch: data intact';
}

# corrupt file rejected
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::Histogram::Shared->new($path, 1, 1_000_000, 3); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# new_from_fd error path: a valid fd over a non-histogram file is rejected
{
    my $jp = "/tmp/hist-junkfd-$$.bin";
    unlink $jp;
    open my $fh, '+>', $jp or die $!;   # real filehandle -> fileno is valid
    print $fh "not a histogram table";
    $fh->flush if $fh->can('flush');
    ok !eval { Data::Histogram::Shared->new_from_fd(fileno($fh)); 1 },
        'new_from_fd rejects a non-histogram file';
    like $@, qr/too small|invalid|histogram/, 'new_from_fd junk-file croak message';
    close $fh;
    unlink $jp;
}

# memfd round-trip shares the counts array
{
    my $m  = Data::Histogram::Shared->new_memfd('hist', 1, 1_000_000, 3);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::Histogram::Shared->new_from_fd($fd);
    cmp_ok $m2->memfd, '>=', 0, 'new_from_fd exposes its (dup) backing fd';
    is $m2->counts_len, $m->counts_len, 'reopened memfd counts_len matches';
    $m->record(333) for 1 .. 3;
    cmp_ok $m2->count_at_value(333), '>=', 3, 'new_from_fd shares the counts array';
    ok !defined($m2->path), 'new_from_fd path is undef';
    my $mu = Data::Histogram::Shared->new_memfd(undef, 1, 1000, 2);
    cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
}

# class-method unlink
my $cu = "/tmp/hist-cu-$$.bin";
unlink $cu;
{ my $w = Data::Histogram::Shared->new($cu, 1, 1000, 2); $w->sync; }
ok -e $cu, 'backing file exists';
Data::Histogram::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/hist-iu-$$.bin";
unlink $iu;
{
    my $w = Data::Histogram::Shared->new($iu, 1, 1000, 2);
    ok -e $iu, 'instance backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# lock-leak regression: an out-of-range element makes record_many croak BEFORE
# locking, and a follow-up record() under an alarm proves the write lock was
# not leaked (the croak must have happened before the lock was taken).
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record(1);
    ok !eval { $g->record_many([10, 20, 9_000_000]); 1 }, 'record_many croaks on an out-of-range element';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        $g->record(42);
        my $n = $g->total_count;
        alarm 0;
        $n;
    };
    is $survived, 2, 'write lock not leaked: record works after the caught record_many croak';
}

# DESTROY nulls the handle: use-after-destroy croaks, double DESTROY is a no-op
{
    my $i = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $i->record(1);
    $i->DESTROY;
    eval { $i->record(2) };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

# geometry guard: an oversized 'lowest' (unit_magnitude too large for sig_figs)
# must croak rather than overflow the derived geometry; a large-but-valid
# geometry still constructs.
{
    eval { Data::Histogram::Shared->new(undef, 2**52, 2**53, 3) };
    like $@, qr/too large|unit_magnitude/, 'oversized lowest croaks';
    my $ok = eval { Data::Histogram::Shared->new(undef, 2**40, 2**50, 3) };
    isa_ok $ok, 'Data::Histogram::Shared', 'large-but-valid geometry (2**40/2**50) constructs OK';
}

# record_many with a negative element: must croak BEFORE locking, record
# nothing (no partial application), and leave no lock leaked.
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record(7);
    my $before = $g->total_count;
    ok !eval { $g->record_many([5, -1, 10]); 1 }, 'record_many croaks on a negative element';
    like $@, qr/negative/, 'record_many negative croak mentions negative';
    is $g->total_count, $before, 'no partial record on the caught record_many croak';
    my $survived = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        $g->record(99);
        my $n = $g->total_count;
        alarm 0;
        $n;
    };
    is $survived, $before + 1, 'write lock not leaked after the negative record_many croak';
}

# count_at_value error paths: negative and over-highest both croak.
{
    my $g = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $g->record(123);
    ok !eval { $g->count_at_value(-1); 1 }, 'count_at_value negative croaks';
    like $@, qr/negative/, 'count_at_value negative croak mentions negative';
    ok !eval { $g->count_at_value($g->highest * 2); 1 }, 'count_at_value over-highest croaks';
    like $@, qr/exceeds|range|highest/, 'count_at_value over-range croak mentions highest';
}

# merge into an empty histogram: the empty target must adopt the source's
# min/max/total exactly (exercises the INT64_MAX min-sentinel adoption: an
# untouched min_value is INT64_MAX, so other_min < min_value must replace it).
{
    my $e = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    my $f = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
    $f->record(250) for 1 .. 6;
    $f->record(7777) for 1 .. 3;
    $e->merge($f);
    is $e->total_count, $f->total_count, 'merge into empty: total_count adopted';
    is $e->min, $f->min, 'merge into empty: min adopted (INT64_MAX sentinel replaced)';
    is $e->max, $f->max, 'merge into empty: max adopted';
}

done_testing;
