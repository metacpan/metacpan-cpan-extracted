#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($l);

# local together with sub scope.

$l = 'outer';
sub reads { $l }

sub both {
    $l = 'sub';
    {
        local $l = 'block';
        die 'inner' unless reads() eq 'block';
    }
    return $l;
}
is(both(), 'sub', 'a local inside a scoped sub unwinds to the sub\'s own assignment');
is($l, 'outer', 'and the sub\'s scope unwinds to the caller');

sub local_only { local $l = 'only'; reads() }
is(local_only(), 'only', 'a sub whose only write is a local');
is($l, 'outer', 'leaves the caller alone');

sub local_dies { local $l = 'x'; die "d\n" }
eval { local_dies() };
is($l, 'outer', 'a local in a sub left by die is undone');

sub local_then_assign { local $l = 'a'; $l = 'b'; reads() }
is(local_then_assign(), 'b', 'an assignment after a local in the same sub');
is($l, 'outer', 'is undone with both');

{
    local $l = 'top block';
    is(both(), 'sub', 'a scoped sub called inside a top-level local');
    is($l, 'top block', 'returns to the local value');
}
is($l, 'outer', 'which ends with its block');

is(Context::Vars::_locals(), 0, 'nothing is left displaced');
is(Context::Vars::_depth(), 0, 'no scope is left open');

done_testing;
