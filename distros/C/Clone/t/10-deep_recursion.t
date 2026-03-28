#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use Clone qw(clone);
use Config;

# Platform-adaptive depth targets.
# Windows has a 1 MB default thread stack; Cygwin typically 2 MB;
# Linux/macOS default to 8 MB but some smokers have less.
# The depths must be safe for both Clone XS recursion AND Perl's
# own recursive SvREFCNT_dec when freeing deeply nested structures.
#
# Clone.xs uses MAX_DEPTH (in rdepth units) to switch from recursive
# to iterative cloning: 2000 on Windows/Cygwin, 4000 elsewhere.
# rdepth increments twice per nesting level (once for AV, once for RV),
# so the switch happens at roughly MAX_DEPTH/2 nesting levels.
# The deep target must exceed MAX_DEPTH/2 to exercise both paths.
my $is_limited_stack = ($^O eq 'MSWin32' || $^O eq 'cygwin');

my $deep_target     = $is_limited_stack ? 2500 : 5000;

# Moderate depth used for basic tests (safe everywhere).
my $moderate_target  = 1000;

# Test 1-2: Basic deep recursion
{
    my $deep = [];
    my $curr = $deep;
    for (1..$moderate_target) {
        my $next = [];
        $curr->[0] = $next;
        $curr = $next;
    }

    my $cloned = eval { clone($deep) };
    ok(!$@, "Cloning deeply nested structure ($moderate_target levels) should not die")
        or diag("Error: $@");
    is(ref($cloned), 'ARRAY', "Cloned structure should be an array reference");
}

# Test 3-5: Very deep recursion (platform-adaptive depth)
{
    my $very_deep = [];
    my $curr = $very_deep;
    for (1..$deep_target) {
        my $next = [];
        $curr->[0] = $next;
        $curr = $next;
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($very_deep);
    };

    ok(!$@ && defined($cloned),
       "Should be able to clone $deep_target-deep structure without stack overflow")
        or diag("Error during clone: " . ($@ || "undefined result"));

    SKIP: {
        skip "Clone failed, can't verify structure", 2 if !defined $cloned;

        # Measure cloned depth
        my $measured = 0;
        my $walk = $cloned;
        while (ref($walk) eq 'ARRAY' && @$walk == 1) {
            $walk = $walk->[0];
            $measured++;
        }

        is($measured, $deep_target,
           "Cloned structure should maintain full depth ($deep_target levels)");

        # Verify clone independence: mutating the clone must not affect original
        $cloned->[0] = "mutated";
        is(ref($very_deep->[0]), 'ARRAY',
           "Mutating clone should not affect original (clone independence)");
    }
}

# Test 6-7: Deep recursion with multi-element arrays at leaves
{
    my $deep = [];
    my $curr = $deep;
    for (1..$moderate_target) {
        my $next = [];
        $curr->[0] = $next;
        $curr = $next;
    }
    # Put multi-element array at the leaf
    $curr->[0] = "leaf_a";
    $curr->[1] = "leaf_b";

    my $cloned = eval { clone($deep) };
    ok(!$@, "Cloning deep structure with multi-element leaf should not die")
        or diag("Error: $@");

    SKIP: {
        skip "Clone failed", 1 if !defined $cloned;

        # Walk to the leaf
        my $walk = $cloned;
        while (ref($walk) eq 'ARRAY' && @$walk == 1) {
            $walk = $walk->[0];
        }
        is_deeply($walk, ["leaf_a", "leaf_b"],
                  "Leaf multi-element array should be cloned correctly");
    }
}

# Test 8-10: Deep recursion with hashes (GH #93)
# At depth > MAX_DEPTH/2, the guard previously returned SvREFCNT_inc(ref)
# for hash types, silently aliasing inner nodes instead of deep-copying them.
{
    my $deep_hash = {x => undef};
    my $curr = $deep_hash;
    for (1..$deep_target) {
        my $next = {x => undef};
        $curr->{x} = $next;
        $curr = $next;
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep_hash);
    };

    ok(!$@ && defined($cloned),
       "Should be able to clone $deep_target-deep hash structure without stack overflow")
        or diag("Error during clone: " . ($@ || "undefined result"));

    SKIP: {
        skip "Clone failed, can't verify structure", 2 if !defined $cloned;

        # Measure cloned depth
        my $measured = 0;
        my $walk = $cloned;
        while (ref($walk) eq 'HASH' && exists $walk->{x} && ref($walk->{x}) eq 'HASH') {
            $walk = $walk->{x};
            $measured++;
        }

        is($measured, $deep_target,
           "Cloned hash structure should maintain full depth ($deep_target levels)");

        # Verify clone independence at deep nodes: navigate to a node past
        # MAX_DEPTH/2 in both original and clone, then mutate the clone and
        # verify the original is unaffected (proves deep copy, not aliasing).
        my $depth_target = $is_limited_stack ? 1500 : 2500;
        my $walk_orig = $deep_hash;
        my $walk_clone = $cloned;
        for (1..$depth_target) {
            $walk_orig  = $walk_orig->{x};
            $walk_clone = $walk_clone->{x};
        }
        $walk_clone->{_sentinel} = "mutation";
        ok(!exists $walk_orig->{_sentinel},
           "Mutating clone at depth $depth_target should not affect original (no aliasing)");
    }
}

# Test 11-13: Mixed deep structure (arrays containing hashes) past MAX_DEPTH
{
    my $deep_mixed = [];
    my $curr = $deep_mixed;
    for (1..$deep_target) {
        my $next = [];
        push @$curr, {val => $next};
        $curr = $next;
    }

    my $cloned = eval {
        local $SIG{__WARN__} = sub {};
        clone($deep_mixed);
    };

    ok(!$@ && defined($cloned),
       "Should clone $deep_target-deep mixed array/hash structure without stack overflow")
        or diag("Error during clone: " . ($@ || "undefined result"));

    SKIP: {
        skip "Clone failed, can't verify", 2 if !defined $cloned;

        # Measure depth
        my $measured = 0;
        my $walk = $cloned;
        while (ref($walk) eq 'ARRAY' && @$walk == 1 && ref($walk->[0]) eq 'HASH') {
            $walk = $walk->[0]{val};
            $measured++;
        }
        is($measured, $deep_target,
           "Mixed deep structure should maintain full depth ($deep_target levels)");

        # Clone independence: mutate a deep hash node in clone
        my $depth_target = $is_limited_stack ? 1500 : 2500;
        my $walk_orig  = $deep_mixed;
        my $walk_clone = $cloned;
        for (1..$depth_target) {
            $walk_orig  = $walk_orig->[0]{val};
            $walk_clone = $walk_clone->[0]{val};
        }
        $walk_clone->[0]{_sentinel} = "mutation";
        ok(!exists $walk_orig->[0]{_sentinel},
           "Mutating clone hash at depth $depth_target should not affect original");
    }
}
