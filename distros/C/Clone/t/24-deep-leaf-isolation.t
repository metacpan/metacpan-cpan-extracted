#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Clone qw(clone);
use Scalar::Util qw(refaddr);

# Test that leaf scalar values inside deeply nested structures (past
# MAX_DEPTH) are properly deep-copied, not aliased to the originals.
#
# Before the fix (GH #109), hv_clone_iterative / av_clone_iterative
# called sv_clone for each value, which at rdepth > MAX_DEPTH returned
# SvREFCNT_inc(ref) — the original SV.  This meant the clone and
# original shared the same leaf SVs.  Mutations through a reference
# to the clone's leaf value would corrupt the original.

# Platform-adaptive depth: MAX_DEPTH is 2000 on Windows/Cygwin, 4000 elsewhere.
# Each hash nesting level costs ~2 rdepth (RV + HV), so we need > MAX_DEPTH/2
# levels to trigger the iterative path.
my $is_limited = ($^O eq 'MSWin32' || $^O eq 'cygwin');
my $depth      = $is_limited ? 1200 : 2200;

# --- Deep hash: leaf string isolation ---
{
    my $deep = { val => "original" };
    for (1..$depth) {
        $deep = { inner => $deep };
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep);
    };
    ok(!$@ && defined $cloned, "clone deep hash with leaf strings")
        or diag("Error: " . ($@ || "undef"));

    SKIP: {
        skip "clone failed", 3 unless defined $cloned;

        # Navigate to the leaf hash in both original and clone
        my $orig_leaf  = $deep;
        my $clone_leaf = $cloned;
        for (1..$depth) {
            $orig_leaf  = $orig_leaf->{inner};
            $clone_leaf = $clone_leaf->{inner};
        }

        # The leaf hash should be a distinct clone
        isnt(refaddr($clone_leaf), refaddr($orig_leaf),
             "leaf hash is a distinct clone, not aliased");

        # Key test: leaf scalar VALUES should be independent.
        # Modify the clone's leaf value through a reference — if the SVs
        # are aliased (SvREFCNT_inc), this changes the original too.
        my $clone_val_ref = \($clone_leaf->{val});
        $$clone_val_ref = "mutated";

        is($orig_leaf->{val}, "original",
           "modifying clone leaf string through ref does not affect original");
        is($clone_leaf->{val}, "mutated",
           "clone leaf string was actually modified");
    }
}

# --- Deep hash: leaf integer isolation ---
{
    my $deep = { num => 42 };
    for (1..$depth) {
        $deep = { inner => $deep };
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep);
    };
    ok(!$@ && defined $cloned, "clone deep hash with leaf integers")
        or diag("Error: " . ($@ || "undef"));

    SKIP: {
        skip "clone failed", 1 unless defined $cloned;

        my $orig_leaf  = $deep;
        my $clone_leaf = $cloned;
        for (1..$depth) {
            $orig_leaf  = $orig_leaf->{inner};
            $clone_leaf = $clone_leaf->{inner};
        }

        my $ref = \($clone_leaf->{num});
        $$ref = 999;

        is($orig_leaf->{num}, 42,
           "modifying clone leaf integer through ref does not affect original");
    }
}

# --- Deep array: leaf scalar isolation ---
{
    my $deep = ["leaf_a", "leaf_b"];
    for (1..$depth) {
        $deep = [$deep];
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep);
    };
    ok(!$@ && defined $cloned, "clone deep array with leaf strings")
        or diag("Error: " . ($@ || "undef"));

    SKIP: {
        skip "clone failed", 1 unless defined $cloned;

        my $orig_leaf  = $deep;
        my $clone_leaf = $cloned;
        for (1..$depth) {
            $orig_leaf  = $orig_leaf->[0];
            $clone_leaf = $clone_leaf->[0];
        }

        my $ref = \($clone_leaf->[0]);
        $$ref = "mutated";

        is($orig_leaf->[0], "leaf_a",
           "modifying clone leaf string in deep array does not affect original");
    }
}

# --- Deep hash: multiple leaf values all independent ---
{
    my $deep = { a => "alpha", b => "beta", c => "gamma" };
    for (1..$depth) {
        $deep = { inner => $deep };
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep);
    };
    ok(!$@ && defined $cloned, "clone deep hash with multiple leaf values")
        or diag("Error: " . ($@ || "undef"));

    SKIP: {
        skip "clone failed", 3 unless defined $cloned;

        my $orig_leaf  = $deep;
        my $clone_leaf = $cloned;
        for (1..$depth) {
            $orig_leaf  = $orig_leaf->{inner};
            $clone_leaf = $clone_leaf->{inner};
        }

        for my $key (qw(a b c)) {
            my $ref = \($clone_leaf->{$key});
            $$ref = "changed_$key";
        }

        is($orig_leaf->{a}, "alpha", "multi-value leaf 'a' independent");
        is($orig_leaf->{b}, "beta",  "multi-value leaf 'b' independent");
        is($orig_leaf->{c}, "gamma", "multi-value leaf 'c' independent");
    }
}

# --- No spurious warnings for leaf scalars at depth ---
{
    my $deep = { val => "test" };
    for (1..$depth) {
        $deep = { inner => $deep };
    }

    my @warnings;
    my $cloned = eval {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        clone($deep);
    };

    is(scalar @warnings, 0,
       "no warnings emitted for leaf scalars at depth > MAX_DEPTH");
}

done_testing;
