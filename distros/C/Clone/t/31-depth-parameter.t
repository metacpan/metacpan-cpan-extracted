#!/usr/bin/perl

# Test the depth parameter of clone($ref, $depth).
#
# Semantics:
#   depth = -1 (default): unlimited deep clone
#   depth =  0: no-op, returns SvREFCNT_inc (same SV)
#   depth =  N: clone N levels of containers; beyond that, share references
#
# Depth decrements happen in av_clone/hv_clone (once per container level).
# Reference (RV) traversal does NOT consume a depth unit.

use strict;
use warnings;
use Test::More tests => 43;
use Scalar::Util qw(refaddr weaken isweak blessed);
use Clone qw(clone);

# ---------------------------------------------------------------------------
# depth = 0: no cloning at all, returns the same SV
# ---------------------------------------------------------------------------

{
    my $scalar = "hello";
    my $c = clone($scalar, 0);
    is($c, "hello", "depth=0 scalar: value preserved");
}

{
    my $ref = [1, 2, 3];
    my $c = clone($ref, 0);
    is(refaddr($ref), refaddr($c),
       "depth=0 arrayref: same SV returned (no clone)");
}

{
    my $ref = {a => 1};
    my $c = clone($ref, 0);
    is(refaddr($ref), refaddr($c),
       "depth=0 hashref: same SV returned (no clone)");
}

# ---------------------------------------------------------------------------
# depth = 1: one level of container cloning
# ---------------------------------------------------------------------------

{
    my $inner = [10, 20, 30];
    my $outer = [$inner, "leaf"];
    my $c = clone($outer, 1);

    isnt(refaddr($outer), refaddr($c),
         "depth=1 array: outer array is a new SV");
    is(refaddr($inner), refaddr($c->[0]),
       "depth=1 array: inner arrayref is shared (not cloned)");
    is($c->[1], "leaf",
       "depth=1 array: scalar leaf copied correctly");
}

{
    my $inner = {x => 42};
    my $outer = {child => $inner, val => "ok"};
    my $c = clone($outer, 1);

    isnt(refaddr($outer), refaddr($c),
         "depth=1 hash: outer hash is a new SV");
    is(refaddr($inner), refaddr($c->{child}),
       "depth=1 hash: inner hashref is shared (not cloned)");
    is($c->{val}, "ok",
       "depth=1 hash: scalar value copied correctly");
}

# ---------------------------------------------------------------------------
# depth = 2: two levels of container cloning
# ---------------------------------------------------------------------------

{
    my $leaf = [100, 200];
    my $mid  = [$leaf];
    my $top  = [$mid];
    my $c = clone($top, 2);

    isnt(refaddr($top), refaddr($c),
         "depth=2: top array cloned");
    isnt(refaddr($mid), refaddr($c->[0]),
         "depth=2: mid array cloned (within 2 levels)");
    is(refaddr($leaf), refaddr($c->[0][0]),
       "depth=2: leaf array shared (beyond 2 levels)");
}

{
    my $leaf = {z => 99};
    my $mid  = {inner => $leaf};
    my $top  = {outer => $mid};
    my $c = clone($top, 2);

    isnt(refaddr($top), refaddr($c),
         "depth=2 hash: top cloned");
    isnt(refaddr($mid), refaddr($c->{outer}),
         "depth=2 hash: mid cloned");
    is(refaddr($leaf), refaddr($c->{outer}{inner}),
       "depth=2 hash: leaf shared beyond depth");
}

# ---------------------------------------------------------------------------
# depth = -1 (default): full deep clone
# ---------------------------------------------------------------------------

{
    my $leaf = [1];
    my $mid  = [$leaf];
    my $top  = [$mid];
    my $c = clone($top);  # default depth = -1

    isnt(refaddr($top), refaddr($c),
         "depth=-1: top cloned");
    isnt(refaddr($mid), refaddr($c->[0]),
         "depth=-1: mid cloned");
    isnt(refaddr($leaf), refaddr($c->[0][0]),
         "depth=-1: leaf cloned (full deep copy)");
}

# ---------------------------------------------------------------------------
# depth < -1: still unlimited (sv_clone only short-circuits on exactly 0).
# hv_clone decrements negative depths (-2, -3, ...) while av_clone clamps to
# -1, so exercise both container types in the same structure.
# ---------------------------------------------------------------------------

{
    my $leaf = {z => 1};
    my $mid  = [$leaf];
    my $top  = {list => $mid};
    my $c = clone($top, -2);

    isnt(refaddr($top), refaddr($c),
         "depth=-2: top hash cloned");
    isnt(refaddr($mid), refaddr($c->{list}),
         "depth=-2: mid array cloned");
    isnt(refaddr($leaf), refaddr($c->{list}[0]),
         "depth=-2: leaf hash cloned (negative depth stays unlimited)");
}

# ---------------------------------------------------------------------------
# depth greater than the actual nesting: indistinguishable from -1
# ---------------------------------------------------------------------------

{
    my $inner = {b => 1};
    my $top   = {a => $inner};
    my $c = clone($top, 10);

    isnt(refaddr($top), refaddr($c),
         "depth=10: top cloned");
    isnt(refaddr($inner), refaddr($c->{a}),
         "depth=10: inner cloned");
    isnt(refaddr(\$inner->{b}), refaddr(\$c->{a}{b}),
         "depth=10: leaf scalar cloned (depth exceeds nesting)");
    is($c->{a}{b}, 1,
       "depth=10: leaf value preserved");
}

# ---------------------------------------------------------------------------
# Mixed array/hash structures with depth
# ---------------------------------------------------------------------------

{
    my $deep = {list => [{name => "item"}]};
    my $c = clone($deep, 2);

    isnt(refaddr($deep), refaddr($c),
         "depth=2 mixed: top hash cloned");
    isnt(refaddr($deep->{list}), refaddr($c->{list}),
         "depth=2 mixed: inner array cloned");
    is(refaddr($deep->{list}[0]), refaddr($c->{list}[0]),
       "depth=2 mixed: nested hash shared beyond depth");
}

{
    my $deep = {list => [{name => "item"}]};
    my $c = clone($deep, 3);

    isnt(refaddr($deep->{list}[0]), refaddr($c->{list}[0]),
         "depth=3 mixed: nested hash cloned (within depth)");
    is(refaddr(\$deep->{list}[0]{name}), refaddr(\$c->{list}[0]{name}),
       "depth=3 mixed: leaf scalar shared beyond depth");
}

# ---------------------------------------------------------------------------
# Blessed objects respect depth
# ---------------------------------------------------------------------------

{
    my $inner = bless {val => 1}, 'Inner';
    my $outer = bless {child => $inner}, 'Outer';
    my $c = clone($outer, 1);

    is(blessed($c), 'Outer',
       "depth=1 blessed: outer blessing preserved");
    is(refaddr($inner), refaddr($c->{child}),
       "depth=1 blessed: inner object shared (beyond depth)");
    is(blessed($c->{child}), 'Inner',
       "depth=1 blessed: shared inner retains its class");
}

{
    my $inner = bless {val => 1}, 'Inner';
    my $outer = bless {child => $inner}, 'Outer';
    my $c = clone($outer, 2);

    isnt(refaddr($inner), refaddr($c->{child}),
         "depth=2 blessed: inner object cloned (within depth)");
    is(blessed($c->{child}), 'Inner',
       "depth=2 blessed: cloned inner has correct class");
}

# ---------------------------------------------------------------------------
# Circular references with depth
# ---------------------------------------------------------------------------

{
    my $a = {name => 'A'};
    my $b = {name => 'B', ref => $a};
    $a->{ref} = $b;

    # depth=1: only outer hash cloned, inner refs are shared
    my $c = clone($a, 1);
    isnt(refaddr($a), refaddr($c),
         "depth=1 circular: outer hash cloned");
    is(refaddr($b), refaddr($c->{ref}),
       "depth=1 circular: inner hash shared (depth exhausted)");
}

{
    my $a = {name => 'A'};
    my $b = {name => 'B', ref => $a};
    $a->{ref} = $b;

    # Full clone: circular structure preserved
    my $c = clone($a);
    isnt(refaddr($a), refaddr($c),
         "full clone circular: outer cloned");
    isnt(refaddr($b), refaddr($c->{ref}),
         "full clone circular: inner cloned");
    is(refaddr($c), refaddr($c->{ref}{ref}),
       "full clone circular: cycle preserved in clone");
}

# ---------------------------------------------------------------------------
# Scalar references with depth
# (RV traversal does NOT consume depth units, so a ref-to-scalar at depth=1
# should still clone the scalar)
# ---------------------------------------------------------------------------

{
    my $val = "deep";
    my $ref = \$val;
    my $c = clone($ref, 1);

    isnt(refaddr($ref), refaddr($c),
         "depth=1 scalar ref: RV wrapper cloned");
    is($$c, "deep",
       "depth=1 scalar ref: value preserved");
    $$c = "mutated";
    is($val, "deep",
       "depth=1 scalar ref: mutating clone does not affect original");
}
