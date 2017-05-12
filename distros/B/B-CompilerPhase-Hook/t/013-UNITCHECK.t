#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook', qw[
       enqueue_UNITCHECK
       append_UNITCHECK
       prepend_UNITCHECK
    ]);
}

=pod

=cut

our @TEST;

UNITCHECK {
    is(scalar(@TEST), 0, '... got the undefined TEST');
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_UNITCHECK_array() }), 0, '... UNITCHECK is empty');
    enqueue_UNITCHECK { push @TEST => 2 };
    prepend_UNITCHECK { push @TEST => 1 };
    append_UNITCHECK  { push @TEST => 3 };
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_UNITCHECK_array() }), 3, '... UNITCHECK now has three');
    is(scalar(@TEST), 0, '... (still) got the undefined TEST');
}

# check at runtime ...
{
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_UNITCHECK_array() }), 0, '... UNITCHECK is empty again');
    is(scalar(@TEST), 3, '... got the expected true value of TEST');
    is_deeply(\@TEST, [1, 2, 3], '... got the right values as well');
}

done_testing();

