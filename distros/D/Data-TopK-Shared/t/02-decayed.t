use strict;
use warnings;
use Test::More;
use Data::TopK::Shared;

# ----------------------------------------------------------------------------
# Time-decayed (forward-decay) TopK: recent observations outweigh old ones.
# With <= capacity distinct keys nothing is evicted, so the decayed estimate is
# EXACT and we can cross-check it against a brute-force forward-decay reference.
# ----------------------------------------------------------------------------

my $LN2 = log(2);

# introspection + error handling
{
    my $t = Data::TopK::Shared->new_decayed(undef, 8, 32, 100);
    ok $t->is_decayed, 'is_decayed true';
    cmp_ok abs($t->half_life - 100), '<', 1e-9, 'half_life reported';
    is $t->stats->{decayed}, 1, 'stats decayed';
    cmp_ok abs($t->stats->{half_life} - 100), '<', 1e-9, 'stats half_life';

    my $p = Data::TopK::Shared->new(undef, 8, 32);
    ok !$p->is_decayed, 'plain tree is_decayed false';
    is $p->stats->{decayed}, 0, 'plain stats decayed 0';

    eval { Data::TopK::Shared->new_decayed(undef, 8, 32, 0) };
    like $@, qr/half_life must be/, 'half_life 0 croaks';
    eval { Data::TopK::Shared->new_decayed(undef, 8, 32, -5) };
    like $@, qr/half_life must be/, 'negative half_life croaks';
}

# ---- oracle: with <= k distinct keys, estimate == brute-force decayed count ----
{
    my ($k, $H) = (8, 50);
    my $alpha = $LN2 / $H;
    my $t = Data::TopK::Shared->new_decayed(undef, $k, 16, $H);

    my @keys = map { "key$_" } 1 .. 6;   # 6 <= k -> no eviction, exact
    my %adds;                            # key => [timestamps]
    srand(999);
    my $now = 0;
    for my $step (1 .. 600) {
        $now += 1 + int(rand 5);          # strictly increasing timestamps
        my $key = $keys[int rand @keys];
        $t->add($key, $now);
        push @{ $adds{$key} }, $now;
    }

    my $bad = 0;
    for my $key (@keys) {
        my $want = 0;
        $want += exp(-$alpha * ($now - $_)) for @{ $adds{$key} };   # forward-decay reference
        my $got = $t->estimate($key);
        $bad++ unless abs($got - $want) <= 1e-6 * ($want + 1e-9);
    }
    is $bad, 0, 'decayed estimate matches the brute-force forward-decay reference';

    # top() is ordered by the (decayed) count, descending
    my @top = $t->top;
    my $ordered = 1;
    for my $i (1 .. $#top) { $ordered = 0 if $top[$i-1]{count} < $top[$i]{count}; }
    ok $ordered, 'top() is sorted by decayed count descending';
    is scalar(@top), scalar(@keys), 'top() returns every monitored key';
}

# ---- recency: a recently-added key outranks an old key with MORE total adds ----
{
    my $t = Data::TopK::Shared->new_decayed(undef, 8, 32, 20);
    $t->add("old", $_) for 1 .. 100;       # 100 adds, long ago
    $t->add("new", $_) for 480 .. 500;     # 21 adds, recent
    cmp_ok $t->estimate("new"), '>', $t->estimate("old"),
        'recent key (fewer adds) outranks an old key (more adds)';
    is +($t->top(1))[0]{key}, "new", 'top-1 is the recent key';
}

# ---- timestamps are monotonic: an out-of-order (past) timestamp does not rewind ----
{
    my $t = Data::TopK::Shared->new_decayed(undef, 4, 16, 10);
    $t->add("a", 1000);
    my $e1 = $t->estimate("a");
    $t->add("a", 5);                        # far in the past -> now stays at 1000
    my $e2 = $t->estimate("a");
    cmp_ok $e2, '>', $e1, 'a past-timestamp add still increases the (current) estimate';
    cmp_ok $e2, '<', 2.001, 'and does not blow up (now did not rewind)';
}

# ---- rescale keeps weights bounded over a long horizon ----
{
    my $H = 5;
    my $t = Data::TopK::Shared->new_decayed(undef, 4, 16, $H);
    $t->add("z", $_ * 10) for 1 .. 3000;    # times to 30000, many landmark rescales
    my $e = $t->estimate("z");
    ok $e == $e && $e < 1e12, 'estimate stays finite and bounded after many rescales';
    # steady state for a fixed-interval repeated key: 1/(1 - exp(-alpha*dt))
    my $expect = 1 / (1 - exp(-($LN2/$H) * 10));
    cmp_ok abs($e - $expect), '<', 1e-6 * $expect, 'converges to the analytic steady state';
}

# ---- no-timestamp mode: time advances one tick per add ----
{
    my $t = Data::TopK::Shared->new_decayed(undef, 4, 16, 4);
    $t->add("x") for 1 .. 20;               # older
    $t->add("y") for 1 .. 5;                # newer
    cmp_ok $t->estimate("y"), '>', 0, 'newer key has a positive estimate';
    cmp_ok $t->estimate("x"), '>', 0, 'older key still tracked';
    # y's 5 recent adds vs x's 20 decayed-away adds
    ok defined +($t->top(1))[0]{key}, 'top works in no-timestamp decayed mode';
}

# ---- persistence: a reopened decayed tree keeps its mode + decayed values ----
{
    my $path = "/tmp/topk-decayed-$$-" . int(rand 1e6) . ".shm";
    unlink $path;
    {
        my $w = Data::TopK::Shared->new_decayed($path, 8, 16, 50);
        $w->add("p", $_) for 1 .. 40;
        $w->sync;
    }
    {
        my $r = Data::TopK::Shared->new_decayed($path, 1, 1, 1);   # args ignored on reopen
        ok $r->is_decayed, 'reopened tree is still decayed';
        cmp_ok abs($r->half_life - 50), '<', 1e-9, 'reopen: half_life persisted';
        cmp_ok $r->estimate("p"), '>', 0, 'reopen: decayed value persisted';
    }
    unlink $path;
}

# ---- regression: a non-finite timestamp must not brick the summary ----
{
    my $t = Data::TopK::Shared->new_decayed(undef, 8, 16, 10);
    my $inf = "Inf" + 0; my $nan = "NaN" + 0;   # NOT 9e999 (finite on -Duselongdouble)
    $t->add("a", 5);
    $t->add("a", $inf);          # Inf timestamp -> ignored (per-add tick), not a poison
    $t->add("a", $nan);          # NaN timestamp -> ignored
    my $e = $t->estimate("a");
    ok $e == $e && $e < 1e9, 'Inf/NaN timestamp does not NaN-brick the estimate';
    $t->add("b", 10);
    ok $t->estimate("b") == $t->estimate("b"), 'summary still usable after a non-finite timestamp';
}

# ---- regression: a huge time gap fully decays old weight (no g=Inf stale weights) ----
{
    my $t = Data::TopK::Shared->new_decayed(undef, 8, 16, 10);   # half-life 10
    $t->add("old", $_) for 100, 101, 102;
    $t->add("new", 200000);      # gap far past the exp-overflow point -> old must decay to ~0
    cmp_ok $t->estimate("old"), '<', 1e-6, 'old weight fully decays across a huge gap';
    cmp_ok $t->estimate("new"), '>', $t->estimate("old"), 'new dominates after the gap';
    is +($t->top(1))[0]{key}, "new", 'top-1 is the recent key after a huge gap';

    my $u = Data::TopK::Shared->new_decayed(undef, 4, 16, 1e-4);  # alpha huge: each tick overflows g
    $u->add("z") for 1 .. 10;
    my $ez = $u->estimate("z");
    ok $ez == $ez && abs($ez - 1) < 0.5, 'tiny half-life: estimate stays ~1 (no stale accumulation)';
}

done_testing;
