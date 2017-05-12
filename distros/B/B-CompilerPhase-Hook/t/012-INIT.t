#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook', qw[
       enqueue_INIT
       append_INIT
       prepend_INIT
    ]);
}

=pod

=cut

our @TEST;

INIT {
    is(scalar(@TEST), 0, '... got the undefined TEST');
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_INIT_array() }), 0, '... INIT is empty');
    enqueue_INIT { push @TEST => 2 };
    prepend_INIT { push @TEST => 1 };
    append_INIT  { push @TEST => 3 };
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_INIT_array() }), 3, '... INIT now has three');
    is(scalar(@TEST), 0, '... (still) got the undefined TEST');
}

# check at runtime ...
{
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_INIT_array() }), 0, '... INIT is empty again');
    is(scalar(@TEST), 3, '... got the expected true value of TEST');
    is_deeply(\@TEST, [1, 2, 3], '... got the right values as well');
}

done_testing();

