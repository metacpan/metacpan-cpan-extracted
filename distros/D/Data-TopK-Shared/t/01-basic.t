use strict;
use warnings;
use Test::More;
use Data::TopK::Shared;

# constructor + introspection
{
    my $tk = Data::TopK::Shared->new(undef, 50, 64);
    isa_ok $tk, 'Data::TopK::Shared';
    is $tk->capacity, 50, 'capacity';
    is $tk->key_size, 64, 'key_size';
    is $tk->tracked, 0, 'empty: tracked 0';
    is $tk->seen, 0, 'empty: seen 0';
    is_deeply [$tk->top], [], 'empty: top is empty';
    is $tk->estimate("x"), 0, 'empty: estimate 0';
}

# exact regime: capacity >= number of distinct keys -> counts exact, error 0
{
    my $tk = Data::TopK::Shared->new(undef, 100);
    my %true;
    for (1..50) { $tk->add("a"); $true{a}++ }
    for (1..30) { $tk->add("b"); $true{b}++ }
    for (1..20) { $tk->add("c"); $true{c}++ }
    for my $i (1..40) { $tk->add("s$i"); $true{"s$i"}++ }

    is $tk->seen, 140, 'seen == total observations';
    is $tk->tracked, 43, 'tracked == distinct keys (< capacity)';

    my @top = $tk->top(3);
    is scalar(@top), 3, 'top(3) returns 3';
    is_deeply [map { $_->{key} } @top], [qw(a b c)], 'top(3) in count-descending order';
    is_deeply [map { $_->{count} } @top], [50, 30, 20], 'top(3) counts exact';
    is +(grep { $_->{error} != 0 } @top), 0, 'exact regime: all errors 0';

    # add returns the running estimated count
    is $tk->add("a"), 51, 'add returns the new count';
    $true{a}++;

    # estimate: scalar and list context
    is $tk->estimate("b"), 30, 'estimate == count';
    is $tk->error("b"), 0, 'error == 0 in the exact regime';
    is $tk->estimate("never-seen"), 0, 'estimate of an untracked key is 0';
    is $tk->error("never-seen"), 0, 'error of an untracked key is 0';
    # estimate/error each return exactly one value even in list context
    is scalar(my @e = $tk->estimate("b")), 1, 'estimate returns a single value in list context';
}

# eviction regime: a genuine heavy hitter survives among a sea of noise
{
    my $tk = Data::TopK::Shared->new(undef, 4);
    for my $i (1 .. 1000) {
        $tk->add("HEAVY");            # 1000 times
        $tk->add("noise-a-$i");       # distinct singletons
        $tk->add("noise-b-$i");
    }
    is $tk->seen, 3000, 'seen counts every observation';
    is $tk->tracked, 4, 'tracked capped at capacity';

    my $c   = $tk->estimate("HEAVY");
    my $err = $tk->error("HEAVY");
    is $c, 1000, 'heavy hitter kept an exact count (never evicted)';
    is $err, 0, 'heavy hitter has zero error (never an eviction victim)';

    my @top = $tk->top(1);
    is $top[0]{key}, "HEAVY", 'heavy hitter is #1';

    # Space-Saving guarantee: true count is always within [count-error, count]
    ok $c - $err <= 1000 && 1000 <= $c, 'count bounds the true frequency';

    # a random noise singleton is either absent or over-counted (error > 0)
    my $nc = $tk->estimate("noise-a-1");
    my $ne = $tk->error("noise-a-1");
    ok $nc == 0 || $ne > 0, 'an evicted/absent key is untracked or carries error';
}

# top(k) argument handling
{
    my $tk = Data::TopK::Shared->new(undef, 10);
    $tk->add("k$_") for 1 .. 5;             # 5 distinct, each count 1
    is scalar(my @a = $tk->top),      5, 'top with no arg returns all tracked';
    is scalar(my @b = $tk->top(100)), 5, 'top(k > tracked) returns all tracked';
    is scalar(my @c = $tk->top(2)),   2, 'top(2) returns 2';
    is scalar(my @d = $tk->top(0)),   5, 'top(0) means all';
}

# key truncation to key_size: two keys sharing a key_size-byte prefix merge
{
    my $tk = Data::TopK::Shared->new(undef, 10, 4);
    $tk->add("aaaaXXXX");   # -> "aaaa"
    $tk->add("aaaaYYYY");   # -> "aaaa" (same truncated key)
    is $tk->tracked, 1, 'keys sharing a key_size-byte prefix are one key';
    is $tk->estimate("aaaaZZZZ"), 2, 'truncated key counted twice';
    my @top = $tk->top(1);
    is length($top[0]{key}), 4, 'stored key truncated to key_size';
    is $top[0]{key}, "aaaa", 'stored key is the prefix';
}

# add_many
{
    my $tk = Data::TopK::Shared->new(undef, 100);
    my $n = $tk->add_many([ ("hot") x 10, map { "cold$_" } 1 .. 20 ]);
    is $n, 30, 'add_many returns the batch size';
    is $tk->seen, 30, 'add_many fed every item';
    is $tk->estimate("hot"), 10, 'add_many counted a repeated key';
    is $tk->tracked, 21, 'add_many tracked all distinct keys';
}

# clear
{
    my $tk = Data::TopK::Shared->new(undef, 10);
    $tk->add("a") for 1 .. 5;
    $tk->add("b");
    $tk->clear;
    is $tk->seen, 0, 'clear resets seen';
    is $tk->tracked, 0, 'clear resets tracked';
    is_deeply [$tk->top], [], 'clear empties the summary';
    is $tk->estimate("a"), 0, 'clear forgot the keys';
    # usable again after clear
    $tk->add("c");
    is $tk->estimate("c"), 1, 'usable after clear';
}

# stats
{
    my $tk = Data::TopK::Shared->new(undef, 20, 32);
    $tk->add("x") for 1 .. 7;
    my $st = $tk->stats;
    is ref($st), 'HASH', 'stats hashref';
    is $st->{capacity}, 20, 'stats capacity';
    is $st->{key_size}, 32, 'stats key_size';
    is $st->{tracked}, 1, 'stats tracked';
    is $st->{seen}, 7, 'stats seen';
    cmp_ok $st->{ops}, '>', 0, 'stats ops';
    ok exists $st->{mmap_size}, 'stats mmap_size';
}

# error paths
ok !eval { Data::TopK::Shared->new(undef, 0); 1 }, 'capacity 0 rejected';
like $@, qr/>= 1|between/, 'capacity 0 croak';
ok !eval { Data::TopK::Shared->new(undef, 10, 0); 1 }, 'key_size 0 rejected';
ok !eval { Data::TopK::Shared->new(undef, 10, 999999); 1 }, 'key_size too large rejected';
{
    my $tk = Data::TopK::Shared->new(undef, 10);
    ok !eval { $tk->add("snow-\x{2603}"); 1 }, 'add croaks on a wide-char key';
    like $@, qr/[Ww]ide/, 'wide-char croak';
    ok !eval { $tk->add_many("notaref"); 1 }, 'add_many non-arrayref croaks';
    ok !eval { $tk->estimate("snow-\x{2603}"); 1 }, 'estimate croaks on a wide-char key';
}

# file-backed reopen: stored geometry wins, data persists
my $path = "/tmp/tk-basic-$$.bin";
unlink $path;
{
    my $w = Data::TopK::Shared->new($path, 50, 32);
    is $w->path, $path, 'file-backed path';
    $w->add("top") for 1 .. 100;
    $w->add("mid") for 1 .. 10;
    $w->sync;
}
{
    my $r = Data::TopK::Shared->new($path, 1, 1);   # caller args ignored on reopen
    is $r->capacity, 50, 'reopen: stored capacity wins';
    is $r->key_size, 32, 'reopen: stored key_size wins';
    is $r->seen, 110, 'reopen: seen persisted';
    is $r->estimate("top"), 100, 'reopen: counts persisted';
    is +($r->top(1))[0]{key}, "top", 'reopen: top persisted';
}
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::TopK::Shared->new($path, 50, 32); 1 }, 'corrupt file rejected';
unlink $path;

# memfd round-trip shares the summary
{
    my $m  = Data::TopK::Shared->new_memfd('tk', 20);
    my $fd = $m->memfd;
    cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
    my $m2 = Data::TopK::Shared->new_from_fd($fd);
    is $m2->capacity, 20, 'reopened memfd geometry';
    $m->add("shared") for 1 .. 3;
    is $m2->estimate("shared"), 3, 'new_from_fd shares the summary';
}

# class-method unlink
my $cu = "/tmp/tk-cu-$$.bin";
unlink $cu;
{ my $w = Data::TopK::Shared->new($cu, 8); $w->sync; }
ok -e $cu, 'backing file exists';
Data::TopK::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY
{
    my $i = Data::TopK::Shared->new(undef, 8);
    $i->add("x");
    $i->DESTROY;
    eval { $i->tracked };
    like $@, qr/destroyed/, 'use after DESTROY croaks';
    eval { $i->DESTROY };
    pass 'double DESTROY did not crash';
}

done_testing;
