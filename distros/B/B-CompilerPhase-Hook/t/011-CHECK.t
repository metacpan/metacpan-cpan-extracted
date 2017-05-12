#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook', qw[
       enqueue_CHECK
       append_CHECK
       prepend_CHECK
    ]);
}

=pod

=cut

our @TEST;

CHECK {
    is(scalar(@TEST), 0, '... got the undefined TEST');
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_CHECK_array() }), 0, '... CHECK is empty');
    enqueue_CHECK { push @TEST => 2 };
    prepend_CHECK { push @TEST => 1 };
    append_CHECK  { push @TEST => 3 };
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_CHECK_array() }), 3, '... CHECK now has three');
    is(scalar(@TEST), 0, '... (still) got the undefined TEST');
}

# check at runtime ...
{
    is(scalar(@{ B::CompilerPhase::Hook::Debug::get_CHECK_array() }), 0, '... CHECK is empty again');
    is(scalar(@TEST), 3, '... got the expected true value of TEST');
    is_deeply(\@TEST, [1, 2, 3], '... got the right values as well');
}

done_testing();

