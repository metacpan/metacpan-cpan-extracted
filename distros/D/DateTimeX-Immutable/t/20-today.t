use strict;
use warnings;
use Test::More;
use Test::MockTime qw(:all);
use DateTimeX::Immutable;

# Make DateTime think today is Tue Jul 15 12:15:00 2014 America/New_York
our $time = 1405440900;
set_absolute_time($time);

# Today needs special treatment
is( DateTimeX::Immutable->today->st, '2014-07-15T00:00:00UTC', 'today' );

done_testing;
