#!/usr/bin/perl

# GH #121, GH #146: t/10-deep_recursion.t crashed on Windows (1 MB
# default thread stack) from Clone 0.50 on.  Past MAX_DEPTH the array
# path unrolled single-element chains iteratively, but hash and mixed
# array/hash paths still consumed one C stack frame per nesting level
# through the hv_clone_iterative <-> sv_clone mutual recursion, so deep hash
# structures blew the stack where equally deep array structures did not.
#
# Reproduce platform-independently by cloning inside a thread with an
# explicitly small stack.  Clone's *bounded* recursive phase (it stops at
# MAX_DEPTH) needs well under 1 MB, so 4 MB leaves room for fatter frames
# on a -DDEBUGGING or unoptimised build while staying far below what one
# frame per level at these depths would need.  A regression here aborts
# the whole file with a stack overflow, which is exactly the symptom
# reported in the issue.

use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl not built with ithreads'
        unless $Config{useithreads};
    # Perl's own SV teardown only became iterative in 5.14; before that,
    # *freeing* the deep structures below would blow the small stack by
    # itself, which is indistinguishable from the regression under test.
    plan skip_all => 'perl < 5.14 frees deep structures recursively'
        if $] < 5.014;
    eval { require threads; 1 }
        or plan skip_all => 'threads not loadable';
}

plan tests => 9;

use Clone qw(clone);

my $STACK = 4 * 1024 * 1024;
my $DEPTH = 30_000;

# Run $code in a thread with a deliberately small stack and hand back
# its result.  Values are serialised as plain strings so nothing deep
# has to cross the thread boundary.
sub in_thread {
    my ($code) = @_;
    my $thr = threads->create({ stack_size => $STACK }, $code);
    return undef unless $thr;   # creation failed; callers report a failure
    return $thr->join;
}

# --- Deep pure-hash chain: {x => {x => ...}} -------------------------
{
    my $got = in_thread(sub {
        my $root = { x => undef };
        my $curr = $root;
        for (1 .. $DEPTH) {
            my $next = { x => undef };
            $curr->{x} = $next;
            $curr = $next;
        }

        my $cloned = clone($root);

        my $measured = 0;
        my $walk     = $cloned;
        while (ref($walk) eq 'HASH' && ref($walk->{x}) eq 'HASH') {
            $walk = $walk->{x};
            $measured++;
        }

        # Independence: mutating the deepest cloned node must not be
        # visible through the original.
        $walk->{sentinel} = 1;
        my $orig = $root;
        $orig = $orig->{x} while ref($orig->{x}) eq 'HASH';

        return join ':', $measured, (exists $orig->{sentinel} ? 1 : 0);
    });

    my ($measured, $leaked) = split /:/, ($got || '');
    is($measured, $DEPTH,
       "$DEPTH-deep hash chain clones to full depth on a small stack");
    is($leaked, 0, 'deep hash chain clone is independent of the original');
}

# --- Deep mixed array/hash chain: [ {val => [ {val => ...} ]} ] ------
{
    my $got = in_thread(sub {
        my $root = [];
        my $curr = $root;
        for (1 .. $DEPTH) {
            my $next = [];
            push @$curr, { val => $next };
            $curr = $next;
        }

        my $cloned = clone($root);

        my $measured = 0;
        my $walk     = $cloned;
        while (ref($walk) eq 'ARRAY' && ref($walk->[0]) eq 'HASH') {
            $walk = $walk->[0]{val};
            $measured++;
        }

        $walk->[0] = 'sentinel';
        my $orig = $root;
        $orig = $orig->[0]{val} while ref($orig->[0]) eq 'HASH';

        return join ':', $measured,
                         (defined $orig->[0] ? 1 : 0);
    });

    my ($measured, $leaked) = split /:/, ($got || '');
    is($measured, $DEPTH,
       "$DEPTH-deep mixed array/hash chain clones to full depth");
    is($leaked, 0, 'deep mixed chain clone is independent of the original');
}

# --- Deep pure-array chain (regression guard) -----------------------
{
    my $got = in_thread(sub {
        my $root = [];
        my $curr = $root;
        for (1 .. $DEPTH) {
            my $next = [];
            $curr->[0] = $next;
            $curr = $next;
        }

        my $cloned = clone($root);

        my $measured = 0;
        my $walk     = $cloned;
        while (ref($walk) eq 'ARRAY' && @$walk == 1) {
            $walk = $walk->[0];
            $measured++;
        }
        return $measured;
    });

    is($got, $DEPTH, "$DEPTH-deep array chain still clones to full depth");
}

# --- Deep multi-key hash chain (no single-element fast path) --------
# Each level carries a scalar sibling alongside the nested hash, so any
# "single key" shortcut cannot apply.
{
    my $got = in_thread(sub {
        my $root = { tag => 0, next => undef };
        my $curr = $root;
        for my $i (1 .. $DEPTH) {
            my $next = { tag => $i, next => undef };
            $curr->{next} = $next;
            $curr = $next;
        }

        my $cloned = clone($root);

        my $measured  = 0;
        my $tags_ok   = 1;
        my $walk      = $cloned;
        while (ref($walk) eq 'HASH' && ref($walk->{next}) eq 'HASH') {
            $walk = $walk->{next};
            $measured++;
            $tags_ok = 0 if $walk->{tag} != $measured;
        }
        return join ':', $measured, $tags_ok;
    });

    my ($measured, $tags_ok) = split /:/, ($got || '');
    is($measured, $DEPTH,
       "$DEPTH-deep multi-key hash chain clones to full depth");
    is($tags_ok, 1, 'sibling scalar values survive the deep hash clone');
}

# --- Deep chain of blessed hashes -----------------------------------
# Blessings must survive the iterative path at depth.
{
    my $got = in_thread(sub {
        my $root = bless { x => undef }, 'Deep::Node';
        my $curr = $root;
        for (1 .. $DEPTH) {
            my $next = bless { x => undef }, 'Deep::Node';
            $curr->{x} = $next;
            $curr = $next;
        }

        my $cloned = clone($root);

        my $measured  = 0;
        my $blessed_ok = ref($cloned) eq 'Deep::Node' ? 1 : 0;
        my $walk       = $cloned;
        while (ref($walk) && ref($walk->{x})) {
            $walk = $walk->{x};
            $measured++;
            $blessed_ok = 0 if ref($walk) ne 'Deep::Node';
        }
        return join ':', $measured, $blessed_ok;
    });

    my ($measured, $blessed_ok) = split /:/, ($got || '');
    is($measured, $DEPTH,
       "$DEPTH-deep blessed hash chain clones to full depth");
    is($blessed_ok, 1, 'blessings survive the deep hash clone');
}
