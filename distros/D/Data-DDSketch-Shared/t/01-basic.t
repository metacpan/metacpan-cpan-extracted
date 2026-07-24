use strict;
use warnings;
use Test::More;
use Data::DDSketch::Shared;

# constructor + introspection
{
    my $dd = Data::DDSketch::Shared->new(undef, 0.01, 1024);
    isa_ok $dd, 'Data::DDSketch::Shared';
    cmp_ok abs($dd->alpha - 0.01), '<', 1e-9, 'alpha';
    is $dd->num_buckets, 1024, 'num_buckets';
    cmp_ok abs($dd->gamma - (1.01/0.99)), '<', 1e-12, 'gamma == (1+a)/(1-a)';
    is $dd->count, 0, 'empty: count 0';
    is $dd->zero_count, 0, 'empty: zero_count 0';
    ok !defined($dd->quantile(0.5)), 'empty: quantile undef';
    ok !defined($dd->min), 'empty: min undef';
    ok !defined($dd->max), 'empty: max undef';
    ok !defined($dd->mean), 'empty: mean undef';
    is $dd->sum, 0, 'empty: sum 0';
}

# quantile accuracy: relative error <= alpha on a uniform distribution
{
    my $alpha = 0.01;
    my $dd = Data::DDSketch::Shared->new(undef, $alpha);
    my $N = 10000;
    $dd->add($_) for 1 .. $N;

    is $dd->count, $N, 'count == number added';
    is $dd->min, 1, 'min exact';
    is $dd->max, $N, 'max exact';
    cmp_ok abs($dd->mean - ($N + 1) / 2), '<', 1e-6, 'mean exact';
    is $dd->sum, $N * ($N + 1) / 2, 'sum exact';

    my $worst = 0;
    for my $q (0.001, 0.01, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99, 0.999) {
        my $est  = $dd->quantile($q);
        my $true = int($q * ($N - 1)) + 1;     # nearest-rank true value
        my $rel  = abs($est - $true) / $true;
        $worst = $rel if $rel > $worst;
        ok $rel <= $alpha * 1.001, sprintf("q=%.3f: rel err %.4f <= alpha", $q, $rel)
            or diag "est=$est true=$true";
    }
    diag sprintf("worst relative error: %.5f (alpha=%.3f)", $worst, $alpha);

    # quantile endpoints
    cmp_ok abs($dd->quantile(0) - 1) / 1, '<=', $alpha * 1.001, 'q=0 ~ min';
    cmp_ok abs($dd->quantile(1) - $N) / $N, '<=', $alpha * 1.001, 'q=1 ~ max';
    # median convenience
    is $dd->median, $dd->quantile(0.5), 'median == quantile(0.5)';
}

# negatives and zeros
{
    my $dd = Data::DDSketch::Shared->new(undef, 0.01);
    $dd->add($_) for -1000 .. -1;
    $dd->add(0) for 1 .. 50;
    $dd->add($_) for 1 .. 1000;
    is $dd->count, 2050, 'count includes negatives and zeros';
    is $dd->zero_count, 50, 'zero_count';
    is $dd->min, -1000, 'min is the most negative';
    is $dd->max, 1000, 'max is the most positive';
    # symmetric distribution -> median is 0 (the zero bucket sits in the middle)
    is $dd->quantile(0.5), 0, 'median of a symmetric set with a zero mass is 0';
    cmp_ok $dd->quantile(0.1), '<', 0, 'low quantile is negative';
    cmp_ok $dd->quantile(0.9), '>', 0, 'high quantile is positive';
    # negatives keep the relative-error guarantee (mirror of positives)
    cmp_ok abs($dd->quantile(0.9) + $dd->quantile(0.1)), '<', 1, 'symmetric quantiles cancel';
}

# add returns the running count; add_many
{
    my $dd = Data::DDSketch::Shared->new(undef, 0.02);
    is $dd->add(5), 1, 'add returns 1 for the first value';
    is $dd->add(7), 2, 'add returns the running count';
    my $n = $dd->add_many([ 1 .. 100 ]);
    is $n, 100, 'add_many returns the batch size';
    is $dd->count, 102, 'count after add_many';
    # add_many matches a loop of add
    my $a = Data::DDSketch::Shared->new(undef, 0.02);
    my $b = Data::DDSketch::Shared->new(undef, 0.02);
    $a->add_many([ map { $_ * 1.5 } 1 .. 200 ]);
    $b->add($_ * 1.5) for 1 .. 200;
    is $a->quantile(0.5), $b->quantile(0.5), 'add_many == a loop of add (same quantile)';
}

# clear
{
    my $dd = Data::DDSketch::Shared->new(undef, 0.01);
    $dd->add($_) for 1 .. 100;
    $dd->clear;
    is $dd->count, 0, 'clear resets count';
    is $dd->zero_count, 0, 'clear resets zero_count';
    ok !defined($dd->quantile(0.5)), 'clear -> quantile undef';
    ok !defined($dd->min), 'clear -> min undef';
    # usable after clear
    $dd->add(42);
    cmp_ok abs($dd->quantile(0.5) - 42) / 42, '<=', 0.011, 'usable after clear';
}

# merge: same geometry combines the distributions
{
    my $a = Data::DDSketch::Shared->new(undef, 0.01, 2048);
    my $b = Data::DDSketch::Shared->new(undef, 0.01, 2048);
    $a->add($_) for 1 .. 5000;
    $b->add($_) for 5001 .. 10000;
    $a->merge($b);
    is $a->count, 10000, 'merge: counts add';
    is $a->min, 1, 'merge: min is the overall min';
    is $a->max, 10000, 'merge: max is the overall max';
    cmp_ok abs($a->quantile(0.5) - 5000) / 5000, '<=', 0.011, 'merge: median accurate on the union';

    # a single sketch over the whole range must agree
    my $whole = Data::DDSketch::Shared->new(undef, 0.01, 2048);
    $whole->add($_) for 1 .. 10000;
    is $a->quantile(0.9), $whole->quantile(0.9), 'merged == a single sketch of the union';

    # geometry mismatch croaks
    ok !eval { $a->merge(Data::DDSketch::Shared->new(undef, 0.02, 2048)); 1 }, 'merge croaks on alpha mismatch';
    like $@, qr/mismatch/, 'merge alpha-mismatch croak';
    ok !eval { $a->merge(Data::DDSketch::Shared->new(undef, 0.01, 1024)); 1 }, 'merge croaks on num_buckets mismatch';
}

# stats
{
    my $dd = Data::DDSketch::Shared->new(undef, 0.01, 512);
    $dd->add($_) for 1 .. 20;
    my $st = $dd->stats;
    is ref($st), 'HASH', 'stats hashref';
    cmp_ok abs($st->{alpha} - 0.01), '<', 1e-9, 'stats alpha';
    is $st->{num_buckets}, 512, 'stats num_buckets';
    is $st->{count}, 20, 'stats count';
    is $st->{min}, 1, 'stats min';
    is $st->{max}, 20, 'stats max';
    cmp_ok abs($st->{mean} - 10.5), '<', 1e-9, 'stats mean';
    cmp_ok $st->{ops}, '>', 0, 'stats ops';
    ok exists $st->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::DDSketch::Shared->new(undef, 0.6); 1 }, 'alpha too large rejected';
like $@, qr/alpha/, 'alpha croak';
ok !eval { Data::DDSketch::Shared->new(undef, 0); 1 }, 'alpha 0 rejected';
ok !eval { Data::DDSketch::Shared->new(undef, 0.01, 4); 1 }, 'num_buckets too small rejected';
{
    my $dd = Data::DDSketch::Shared->new(undef, 0.01);
    ok !eval { $dd->add(9**9**9); 1 }, 'add croaks on infinity';
    like $@, qr/finite/, 'infinity croak';
    ok !eval { $dd->add("NaN" + 0); 1 }, 'add croaks on NaN';
    ok !eval { $dd->quantile(1.5); 1 }, 'quantile croaks on q > 1';
    like $@, qr/between 0 and 1/, 'quantile range croak';
    ok !eval { $dd->quantile(-0.1); 1 }, 'quantile croaks on q < 0';
    ok !eval { $dd->add_many("notaref"); 1 }, 'add_many non-arrayref croaks';
    ok !eval { $dd->add_many([ 1, 2, 9**9**9 ]); 1 }, 'add_many croaks on a non-finite element';
}

# file-backed reopen: geometry wins, distribution persists
my $path = "/tmp/dd-basic-$$.bin";
unlink $path;
{
    my $w = Data::DDSketch::Shared->new($path, 0.01, 1024);
    is $w->path, $path, 'file-backed path';
    $w->add($_) for 1 .. 1000;
    $w->sync;
}
{
    my $r = Data::DDSketch::Shared->new($path, 0.2, 8);   # caller args ignored on reopen
    is $r->num_buckets, 1024, 'reopen: stored num_buckets wins';
    cmp_ok abs($r->alpha - 0.01), '<', 1e-12, 'reopen: stored alpha wins';
    is $r->count, 1000, 'reopen: count persisted';
    cmp_ok abs($r->quantile(0.5) - 500) / 500, '<=', 0.011, 'reopen: quantiles persisted';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::DDSketch::Shared->new($path, 0.01, 1024); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the sketch
{
    my $m  = Data::DDSketch::Shared->new_memfd('dd', 0.01, 512);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::DDSketch::Shared->new_from_fd($fd);
    is $m2->num_buckets, 512, 'reopened memfd geometry';
    $m->add(123);
    is $m2->count, 1, 'new_from_fd shares the sketch';
    cmp_ok abs($m2->quantile(0.5) - 123) / 123, '<=', 0.011, 'shared value visible via the other handle';
}

# class-method unlink
my $cu = "/tmp/dd-cu-$$.bin";
unlink $cu;
{ my $w = Data::DDSketch::Shared->new($cu, 0.01, 256); $w->sync; }
ok -e $cu, 'backing file exists';
Data::DDSketch::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::DDSketch::Shared->new(undef, 0.01);
    $i->add(1);
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
