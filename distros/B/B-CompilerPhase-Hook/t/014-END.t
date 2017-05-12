#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook', qw[
       enqueue_END
       append_END
       prepend_END
    ]);
}

=pod

=cut

END { done_testing() }

our @TEST;

END {
    is(scalar(@TEST), 2, '... got the expected true value of TEST');
    is_deeply(\@TEST, [1, 2], '... got the right values as well');
}

END {
    is(scalar(@TEST), 0, '... got the undefined TEST');
    enqueue_END { push @TEST => 2 };
    prepend_END { push @TEST => 1 };
    is(scalar(@TEST), 0, '... (still) got the undefined TEST');
}

