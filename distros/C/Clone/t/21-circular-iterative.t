#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Clone qw(clone);
use Config;

# Issue #106: av_clone_iterative() had no hseen guard inside its chain-walking
# loop. A circular AV placed at the bottom of a 2001+ level deep wrapper chain
# triggered an infinite loop and OOM when clone() switched to iterative mode.

my $is_limited_stack = ($^O eq 'MSWin32' || $^O eq 'cygwin');
my $max_depth_val    = $is_limited_stack ? 2000 : 4000;

# Build a wrapper chain deep enough to trigger the iterative path, with a
# circular AV at the leaf (i.e. $leaf = [$leaf]).
sub make_deep_circular {
    my ($depth) = @_;
    my $leaf = [];
    $leaf->[0] = $leaf;    # circular: $leaf points to itself

    my $curr = $leaf;
    for (1 .. $depth) {
        my $wrapper = [];
        $wrapper->[0] = $curr;
        $curr = $wrapper;
    }
    return $curr;           # outermost wrapper
}

# Test 1: circular AV at depth > MAX_DEPTH must not hang or OOM
{
    my $depth = $max_depth_val + 10;   # force iterative path
    my $deep_circ = make_deep_circular($depth);

    my $clone = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(10);
        my $r = clone($deep_circ);
        alarm(0);
        $r;
    };
    alarm(0);   # cancel in case eval died before alarm(0)

    ok(!$@, "cloning deep circular array should not die or hang")
        or diag("Error: $@");
    ok(defined $clone, "clone result is defined");
}

# Test 2: the cloned chain must itself be circular (circular ref preserved)
{
    my $depth = $max_depth_val + 10;
    my $deep_circ = make_deep_circular($depth);
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm(10);
    my $clone = eval { clone($deep_circ) };
    alarm(0);

    SKIP: {
        skip "Clone failed, can't verify structure", 1 unless defined $clone;

        # Walk to the leaf (the circular node is at the bottom)
        my $walk = $clone;
        my $steps = 0;
        while (ref($walk) eq 'ARRAY' && @$walk == 1
               && ref($walk->[0]) eq 'ARRAY'
               && "$walk->[0]" ne "$walk") {
            $walk = $walk->[0];
            last if ++$steps > $depth + 5;   # safety against unexpected loop
        }

        # At the leaf, the element should refer back to itself
        is("$walk", "$walk->[0]",
           "circular reference at leaf is preserved in clone");
    }
}

# Test 3: the clone is independent from the original wrapper chain
{
    my $depth = $max_depth_val + 10;
    my $deep_circ = make_deep_circular($depth);
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm(10);
    my $clone = eval { clone($deep_circ) };
    alarm(0);

    SKIP: {
        skip "Clone failed, can't verify independence", 1 unless defined $clone;

        ok("$clone" ne "$deep_circ",
           "clone is a different object from the original");
    }
}

# Test 4: shallow circular at depth just above MAX_DEPTH (edge of iterative path)
{
    my $depth = $max_depth_val + 1;
    my $deep_circ = make_deep_circular($depth);

    my $clone = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(10);
        my $r = clone($deep_circ);
        alarm(0);
        $r;
    };
    alarm(0);

    ok(!$@, "circular array at MAX_DEPTH+1 should not hang")
        or diag("Error: $@");
}
