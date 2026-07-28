use strict;
use warnings;
use Test::More;
use Data::Reservoir::Shared;

# constructor + introspection
my $r = Data::Reservoir::Shared->new(undef, 5, 64);
isa_ok $r, 'Data::Reservoir::Shared';
is $r->capacity, 5, 'capacity == k';
is $r->item_size, 64, 'item_size';
is $r->count, 0, 'empty reservoir count 0';
is $r->seen, 0, 'seen 0';
is_deeply [$r->sample], [], 'empty sample';
ok !defined($r->get(0)), 'get on empty is undef';

# filling phase: while seen <= k, every add is kept
{
    my $h = Data::Reservoir::Shared->new(undef, 5, 64);
    for my $i (1 .. 5) {
        is $h->add("item$i"), 1, "add item$i kept (filling)";
        is $h->count, $i, "count == $i during fill";
        is $h->seen, $i, "seen == $i";
    }
    my @s = sort $h->sample;
    is_deeply \@s, [sort map { "item$_" } 1..5], 'full reservoir holds exactly the 5 items';
}

# once full, count stays k, seen grows, sample only ever holds added items
{
    my $h = Data::Reservoir::Shared->new(undef, 10, 32);
    $h->seed(12345);   # reproducible
    my %added = map { ("k$_" => 1) } 1 .. 1000;
    $h->add($_) for keys %added;
    is $h->count, 10, 'count capped at k after overflow';
    is $h->seen, 1000, 'seen == 1000';
    my @s = $h->sample;
    is scalar(@s), 10, 'sample size == k';
    my $bad = grep { !$added{$_} } @s;
    is $bad, 0, 'every sampled item was one we added';
    # get() agrees with sample() membership
    my %bysample = map { $_ => 1 } @s;
    my $getbad = 0;
    for my $i (0 .. $h->count - 1) { $getbad++ unless $bysample{ $h->get($i) } }
    is $getbad, 0, 'get(i) returns sampled items';
}

# reproducibility: same seed + same stream -> same sample
{
    my @stream = map { "s$_" } 1 .. 500;
    my $a = Data::Reservoir::Shared->new(undef, 20, 16); $a->seed(999);
    my $b = Data::Reservoir::Shared->new(undef, 20, 16); $b->seed(999);
    $a->add($_) for @stream;
    $b->add($_) for @stream;
    is_deeply [sort $a->sample], [sort $b->sample], 'same seed + stream -> identical sample';
    # a different seed generally gives a different sample
    my $c = Data::Reservoir::Shared->new(undef, 20, 16); $c->seed(111);
    $c->add($_) for @stream;
    isnt join(',', sort $a->sample), join(',', sort $c->sample), 'different seed -> different sample';
}

# uniformity: over many trials each stream item is sampled about equally often
{
    my ($k, $n, $trials) = (5, 20, 3000);
    my %freq;
    for my $t (1 .. $trials) {
        my $h = Data::Reservoir::Shared->new(undef, $k, 16);
        $h->seed($t * 2654435761 & 0xffffffff || 1);   # distinct per-trial seed
        $h->add("v$_") for 1 .. $n;
        $freq{$_}++ for $h->sample;
    }
    my $expected = $trials * $k / $n;      # 3000*5/20 = 750
    my ($lo, $hi) = ($expected * 0.7, $expected * 1.3);
    my @outliers = grep { $freq{"v$_"} < $lo || $freq{"v$_"} > $hi } 1 .. $n;
    is scalar(@outliers), 0,
        sprintf("uniform sampling: all %d items within 30%% of expected %d (outliers: @outliers)", $n, $expected)
        or diag join ", ", map { "v$_=$freq{qq{v$_}}" } 1 .. $n;
}

# item truncation to item_size
{
    my $h = Data::Reservoir::Shared->new(undef, 2, 8);
    $h->add("x" x 100);   # 100 bytes -> truncated to 8
    my ($item) = $h->sample;
    is length($item), 8, 'over-long item truncated to item_size';
    is $item, "x" x 8, 'truncated content is the prefix';
}

# add_many
{
    my $h = Data::Reservoir::Shared->new(undef, 50, 16);
    my $kept = $h->add_many([ map { "m$_" } 1 .. 30 ]);
    is $kept, 30, 'add_many: all 30 kept (reservoir not full)';
    is $h->count, 30, 'count 30';
    $h->add_many([ map { "m$_" } 31 .. 200 ]);
    is $h->count, 50, 'count capped at 50 after more';
    is $h->seen, 200, 'seen 200';
}

# clear
{
    my $h = Data::Reservoir::Shared->new(undef, 5, 16);
    $h->add("a"); $h->add("b");
    $h->clear;
    is $h->count, 0, 'clear -> count 0';
    is $h->seen, 0, 'clear -> seen 0';
    is_deeply [$h->sample], [], 'clear -> empty sample';
}

# stats
{
    my $h = Data::Reservoir::Shared->new(undef, 10, 32);
    $h->add("x") for 1 .. 25;
    my $st = $h->stats;
    is ref($st), 'HASH', 'stats hashref';
    is $st->{size}, 10, 'stats size';
    is $st->{item_size}, 32, 'stats item_size';
    is $st->{count}, 10, 'stats count';
    is $st->{seen}, 25, 'stats seen';
    cmp_ok $st->{ops}, '>', 0, 'stats ops';
    ok exists $st->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::Reservoir::Shared->new(undef, 0); 1 }, 'k == 0 rejected';
like $@, qr/>= 1|must be/, 'k 0 croak';
ok !eval { Data::Reservoir::Shared->new(undef, 5, 0); 1 }, 'item_size 0 rejected';
{
    my $h = Data::Reservoir::Shared->new(undef, 5, 16);
    ok !eval { $h->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char item';
    like $@, qr/[Ww]ide/, 'wide-char croak';
    ok !eval { $h->add_many("notaref"); 1 }, 'add_many non-arrayref croaks';
}

# file-backed reopen: sample persists, stored geometry wins
my $path = "/tmp/rsv-basic-$$.bin";
unlink $path;
{
    my $w = Data::Reservoir::Shared->new($path, 8, 32);
    is $w->path, $path, 'file-backed path';
    $w->seed(7);
    $w->add("p$_") for 1 .. 100;
    $w->sync;
}
{
    my $rr = Data::Reservoir::Shared->new($path, 1, 1);   # caller args ignored on reopen
    is $rr->capacity, 8, 'reopen: stored k wins';
    is $rr->item_size, 32, 'reopen: stored item_size wins';
    is $rr->count, 8, 'reopen: sample persisted';
    is $rr->seen, 100, 'reopen: seen persisted';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::Reservoir::Shared->new($path, 8, 32); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the reservoir
{
    my $m  = Data::Reservoir::Shared->new_memfd('rsv', 5, 16);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::Reservoir::Shared->new_from_fd($fd);
    is $m2->capacity, 5, 'reopened memfd size';
    $m->add("shared");
    is $m2->count, 1, 'new_from_fd shares the reservoir';
    is +($m2->sample)[0], "shared", 'shared item visible via the other handle';
}

# class-method unlink
my $cu = "/tmp/rsv-cu-$$.bin";
unlink $cu;
{ my $w = Data::Reservoir::Shared->new($cu, 4, 16); $w->sync; }
ok -e $cu, 'backing file exists';
Data::Reservoir::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::Reservoir::Shared->new(undef, 4, 16);
    $i->add("x");
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
