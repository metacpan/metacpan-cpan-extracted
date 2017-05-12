#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# NOTE:
# This is a very strange test.

our $TEST;

# the test() call below will happen at BEGIN time,
# so even though this code technically comes before
# that test() call, it is actually executed after it
# this is the "lifting" aspect
is($TEST, 10, '... got the expected value (RUN) (before BEGIN::Lift::install)');
BEGIN {
	use_ok('BEGIN::Lift');

    # now we are back in BEGIN time, so the
    # variable has not even been set
    is($TEST, undef, '... got the expected undef value (BEGIN)');

    # now we set it initially ..
    $TEST = -1;
    # and install the lifted sub call
    BEGIN::Lift::install(
        ('main', 'test') => sub {
            # now, we know that this will
            # still be the initial value
            # because between this definition
            # point and the call to test()
            # there is no BEGIN time modification
            # even though there is a lot of
            # RUN time modification.
            is($TEST, -1, '... got the expected initial value (BEGIN) (inside BEGIN::Lift::install)');
            # now we assign TEST, which means
            # the RUN time code below will
            # see this assigned value
            $TEST = shift @_;
            return;
        }
    );
}

# now here we are in RUN time, and
# the value is the same as what we
# passed into the test() call below
is($TEST, 10, '... got the expected value (RUN) (before lifted sub is run)');

# now we change the value in RUN time
$TEST = 5;

BEGIN { ok( exists $main::{'test'}, '... we have a typeglob in BEGIN' ) }
ok( not(exists $main::{'test'}), '... we no longer have a typeglob in RUN' );

# now we call our lifted sub call,
# which time travels back into the
# handler assigned above to set the
# value of TEST
test( 10 );

# meanwhile back in RUN time, the
# current value of TEST is 5 ...
is($TEST, 5, '... got the expected value (RUN) (after BEGIN::Lift::install)');

BEGIN {
    # and in BEGIN time it is 10
    is($TEST, 10, '... got the expected value (BEGIN)');
}

# so, make sense now?

done_testing;

1;
