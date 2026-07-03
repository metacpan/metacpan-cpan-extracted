#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

# times before noon: result is straight decimal hours
is( Algorithm::Time::ToNumber->noon_fail('0:00'),  0,    '0:00 -> 0' );
is( Algorithm::Time::ToNumber->noon_fail('0:30'),  0.5,  '0:30 -> 0.5' );
is( Algorithm::Time::ToNumber->noon_fail('6:00'),  6,    '6:00 -> 6' );
is( Algorithm::Time::ToNumber->noon_fail('11:30'), 11.5, '11:30 -> 11.5' );

# noon and after: result wraps (hours - 24)
is( Algorithm::Time::ToNumber->noon_fail('12:00'), -12,   '12:00 -> -12' );
is( Algorithm::Time::ToNumber->noon_fail('12:30'), -11.5, '12:30 -> -11.5' );
is( Algorithm::Time::ToNumber->noon_fail('18:00'), -6,    '18:00 -> -6' );
is( Algorithm::Time::ToNumber->noon_fail('23:30'), -0.5,  '23:30 -> -0.5' );

# with seconds
is( Algorithm::Time::ToNumber->noon_fail('0:00:30'),
    30 / 3600, '0:00:30 -> 30/3600' );
is( Algorithm::Time::ToNumber->noon_fail('12:00:00'), -12, '12:00:00 -> -12' );

done_testing();
