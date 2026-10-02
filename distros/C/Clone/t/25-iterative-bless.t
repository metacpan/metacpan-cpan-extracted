#!/usr/bin/perl

# Test that blessed arrayrefs retain their class when cloned via the
# iterative path (av_clone_iterative chain-walking optimization).
#
# Bug: av_clone_iterative unrolls [[[...]]] chains iteratively to avoid
# stack overflow past MAX_DEPTH, but newAV() in the loop did not preserve
# blessings from the original AV.  Intermediate blessed arrayrefs lost
# their class, breaking ref($clone) checks.

use strict;
use warnings;
use Test::More;
use Clone qw(clone);
use Scalar::Util qw(refaddr blessed reftype);

# Platform-adaptive depth (mirrors t/10-deep_recursion.t).
# Must exceed MAX_DEPTH/2 to exercise the iterative path.
my $is_limited_stack = ($^O eq 'MSWin32' || $^O eq 'cygwin');
my $deep_target = $is_limited_stack ? 2500 : 5000;

plan tests => 13;

# Test 1-3: deeply nested blessed arrayrefs preserve class
{
    my $bottom = bless ['leaf'], 'Bottom';
    my $curr = $bottom;
    for (1 .. $deep_target) {
        $curr = bless [$curr], 'Deep::Node';
    }
    my $top = $curr;

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($top);
    };

    ok(!$@, "clone of $deep_target-deep blessed chain does not die")
        or diag("Error: $@");

    SKIP: {
        skip 'clone failed', 2 unless defined $cloned;

        is(blessed($cloned), 'Deep::Node',
           'top-level clone preserves blessing');

        # Walk halfway down and check an intermediate node
        my $orig_walk = $top;
        my $clone_walk = $cloned;
        my $mid = int($deep_target / 2);
        for (1 .. $mid) {
            $orig_walk  = $orig_walk->[0];
            $clone_walk = $clone_walk->[0];
        }

        is(blessed($clone_walk), blessed($orig_walk),
           "intermediate node at depth $mid preserves blessing");
    }
}

# Test 4-5: mixed blessed/unblessed chain
{
    # Build: unblessed -> blessed -> unblessed -> ... (alternating)
    my $curr = ['leaf'];
    for my $i (1 .. $deep_target) {
        if ($i % 2 == 0) {
            $curr = bless [$curr], 'Even::Node';
        } else {
            $curr = [$curr];
        }
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($curr);
    };

    ok(!$@, 'clone of mixed blessed/unblessed chain does not die')
        or diag("Error: $@");

    SKIP: {
        skip 'clone failed', 1 unless defined $cloned;

        # Walk down to the first blessed node and check
        my $orig_walk  = $curr;
        my $clone_walk = $cloned;
        my $found = 0;
        for (1 .. 100) {
            $orig_walk  = $orig_walk->[0];
            $clone_walk = $clone_walk->[0];
            last unless ref($orig_walk) eq 'ARRAY' || blessed($orig_walk);

            if (blessed($orig_walk)) {
                $found = 1;
                is(blessed($clone_walk), blessed($orig_walk),
                   'first blessed node in mixed chain preserves class');
                last;
            }
        }
        ok($found, 'found blessed node in chain') unless $found;
    }
}

# Test 6-7: blessed multi-element AV at the bottom of a single-element chain.
# The chain-walk loop only processes single-element AVs and hands the
# terminator to a separate fallback. That fallback wrapped the cloned AV
# in newRV_noinc() without re-applying the blessing, so a blessed
# multi-element terminator lost its class.
{
    my $multi = bless [10, 20, 30], 'Multi::Class';
    my $r = $multi;
    for (1 .. $deep_target) {
        $r = [$r];
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($r);
    };

    SKIP: {
        skip 'clone failed', 2 unless defined $cloned;

        my $w = $cloned;
        $w = $w->[0] while ref($w) eq 'ARRAY' && @$w == 1;

        is(blessed($w), 'Multi::Class',
           'multi-element AV terminator preserves blessing through chain walk');
        is(scalar(@$w), 3,
           'multi-element AV terminator preserves element count');
    }
}

# Test 8-9: clone isolation — modifying cloned blessed node does not affect original
{
    my $bottom = bless ['sentinel'], 'Leaf';
    my $curr = $bottom;
    for (1 .. $deep_target) {
        $curr = bless [$curr], 'Chain::Link';
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($curr);
    };

    ok(!$@, 'clone for isolation test does not die')
        or diag("Error: $@");

    SKIP: {
        skip 'clone failed', 1 unless defined $cloned;

        # Walk to the bottom of the clone
        my $clone_walk = $cloned;
        $clone_walk = $clone_walk->[0] while ref($clone_walk->[0]);

        isnt(refaddr($clone_walk), refaddr($bottom),
             'bottom node is a different SV (not aliased)');
    }
}

# Test 10-13: blessed *hash* chain at iterative depth.
# Same contract as the blessed AV cases above, but each level is a blessed
# hashref holding an RV to the next one, so the rebuild goes through
# hv_clone_iterative.  t/28-limited-stack.t covers this far deeper, but only
# on a threaded perl; this keeps the coverage unconditional.
{
    my $deep = bless { next => undef }, 'DeepHash';
    my $curr = $deep;
    for (2 .. $deep_target) {
        my $next = bless { next => undef }, 'DeepHash';
        $curr->{next} = $next;
        $curr = $next;
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep);
    };

    ok(!$@ && defined($cloned),
       "clone of $deep_target-deep blessed hash chain does not die")
        or diag("Error: " . ($@ || "undefined result"));

    SKIP: {
        skip 'clone failed', 3 unless defined $cloned;

        is(blessed($cloned), 'DeepHash',
           'top-level blessed hash preserves blessing');

        # Walk the clone and the original in lockstep.  The loop must not
        # short-circuit on blessedness: a chain that lost its class (or was
        # truncated) part-way down would otherwise stop on the last still-good
        # node and assert vacuously.  Count the levels actually traversed and
        # require the full $mid.
        my $mid  = int($deep_target / 2);
        my $walk = $cloned;
        my $reached = 0;
        for (1 .. $mid) {
            last unless ref($walk)
                && reftype($walk) eq 'HASH'
                && defined $walk->{next};
            $walk = $walk->{next};
            $reached++;
        }
        is($reached, $mid,
           "cloned blessed hash chain is walkable $mid levels deep");
        is(blessed($walk), 'DeepHash',
           "intermediate blessed hash at depth $mid preserves blessing");
    }
}
