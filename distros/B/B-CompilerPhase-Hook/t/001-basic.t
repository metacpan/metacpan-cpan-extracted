#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook', qw[
       enqueue_BEGIN
       enqueue_CHECK
       enqueue_INIT
       enqueue_UNITCHECK
       enqueue_END
    ]);
}

=pod

This tests is based on the `begincheck` program as 
presented in the perlmod docs.

https://metacpan.org/pod/perlmod#BEGIN-UNITCHECK-CHECK-INIT-and-END

=cut

# NOTE: 
# we need to do this so that our 
# END tests work, comment it out 
# to see why ;)
# - SL
END { done_testing() }

our @DATA;

# Since (UNIT)CHECK/END in LIFO order, we need to specify these here ...
UNITCHECK { is_deeply( \@DATA, [ 1 .. 4  ], '... got the data in the expected order during UNITCHECK' ) }
CHECK     { is_deeply( \@DATA, [ 1 .. 6  ], '... got the data in the expected order during CHECK'     ) }
END       { is_deeply( \@DATA, [ 1 .. 16 ], '... got the data in the expected order during END'       ) }

# this is the body of the test
push @DATA => 10; 
BEGIN {
    enqueue_END       { push @DATA => 16 };
    enqueue_INIT      { push @DATA => 7  };
    enqueue_UNITCHECK { push @DATA => 4  };
    enqueue_CHECK     { push @DATA => 6  };
}
push @DATA => 11;
BEGIN {
    enqueue_BEGIN { push @DATA => 1  };
    enqueue_END   { push @DATA => 15 };
    enqueue_CHECK { push @DATA => 5  };
    enqueue_INIT  { push @DATA => 8  };
}
push @DATA => 12;
BEGIN {
    enqueue_END       { push @DATA => 14 };
    enqueue_BEGIN     { push @DATA => 2  };
    enqueue_UNITCHECK { push @DATA => 3  };
    enqueue_INIT      { push @DATA => 9  };
}
push @DATA => 13;

# since BEGIN/INIT/RUN is in FIFO we need to specify these here ...
BEGIN { is_deeply( \@DATA, [ 1, 2   ], '... got the data in the expected order during BEGIN' ) }
INIT  { is_deeply( \@DATA, [ 1 .. 9 ], '... got the data in the expected order during INIT'  ) }
is_deeply( \@DATA, [ 1 ... 13 ], '... got the data in the expected order during RUN' );

1;

