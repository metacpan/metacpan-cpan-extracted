#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

# straight decimal hours with no wrapping
is( Algorithm::Time::ToNumber->midnight_fail('0:00'),  0,    '0:00 -> 0' );
is( Algorithm::Time::ToNumber->midnight_fail('0:30'),  0.5,  '0:30 -> 0.5' );
is( Algorithm::Time::ToNumber->midnight_fail('6:00'),  6,    '6:00 -> 6' );
is( Algorithm::Time::ToNumber->midnight_fail('12:00'), 12,   '12:00 -> 12' );
is( Algorithm::Time::ToNumber->midnight_fail('12:30'), 12.5, '12:30 -> 12.5' );
is( Algorithm::Time::ToNumber->midnight_fail('18:00'), 18,   '18:00 -> 18' );
is( Algorithm::Time::ToNumber->midnight_fail('23:30'), 23.5, '23:30 -> 23.5' );

# with seconds
is( Algorithm::Time::ToNumber->midnight_fail('0:00:30'),
    30 / 3600, '0:00:30 -> 30/3600' );
is( Algorithm::Time::ToNumber->midnight_fail('23:59:30'),
    23 + 59 / 60 + 30 / 3600, '23:59:30 -> 23+59/60+30/3600' );

done_testing();
