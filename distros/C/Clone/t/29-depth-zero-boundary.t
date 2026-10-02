#!/usr/bin/perl
# depth == 0 ("share, don't clone") must win over the rdepth > MAX_DEPTH
# iterative fallback when both trigger on the same sv_clone() call.
#
# rdepth advances one per sv_clone() call, i.e. two per nesting level
# (the RV, then its referent), while depth drops one per level.  So a
# chain nested MAX_DEPTH/2 levels deep, cloned with an explicit depth of
# MAX_DEPTH/2, reaches depth == 0 exactly on the first call whose rdepth
# exceeds MAX_DEPTH.  With the depth check placed after the fallback,
# that call went iterative and deep-copied a leaf the caller asked to
# share.

use strict;
use warnings;
use Test::More;
use Clone 'clone';

# MAX_DEPTH in Clone.xs: 2000 on Windows/Cygwin, 4000 elsewhere.
my $max_depth = ($^O eq 'MSWin32' || $^O =~ /cygwin/i) ? 2000 : 4000;
my $boundary  = $max_depth / 2;

# The exact boundary is what regressed; the two levels below it share the
# same contract and guard against an off-by-one in either direction.
for my $levels ($boundary - 2 .. $boundary) {
    my $leaf = ['shared'];
    my $deep = $leaf;
    $deep = [$deep] for 1 .. $levels;

    my $clone = clone($deep, $levels);

    my $p = $clone;
    $p = $p->[0] for 1 .. $levels;

    is($p, $leaf, "depth reaches 0 at nesting level $levels: leaf is shared");
}

# The outer levels are still real copies — sharing the leaf must not turn
# the whole clone into a no-op.
{
    my $leaf = ['shared'];
    my $deep = $leaf;
    $deep = [$deep] for 1 .. $boundary;

    my $clone = clone($deep, $boundary);
    isnt($clone, $deep, 'outer level is copied, not shared');
    isnt($clone->[0], $deep->[0], 'second level is copied, not shared');
}

# A non-clonable leaf (coderef) at the same boundary is shared without the
# "depth limit exceeded" warning: depth == 0 is an explicit request to
# share, not a depth-limit bail-out.
{
    my $code = sub { 42 };
    my $deep = $code;
    $deep = [$deep] for 1 .. $boundary;

    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ };

    my $clone = clone($deep, $boundary);

    my $p = $clone;
    $p = $p->[0] for 1 .. $boundary;

    is($warned, 0, 'no depth-limit warning when depth == 0 asks for sharing');
    is($p, $code, 'coderef leaf is shared at the boundary');
}

done_testing;
