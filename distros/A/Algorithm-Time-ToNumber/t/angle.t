#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_angle {
    my ($h, $m, $s) = @_;
    $s //= 0;
    return sin( 2 * pi * ($h * 3600 + $m * 60 + $s) / 86400 );
}

is( Algorithm::Time::ToNumber->angle('0:00'),
    expected_angle(0, 0), '0:00 -> sin(0) = 0' );

is( Algorithm::Time::ToNumber->angle('6:00'),
    expected_angle(6, 0), '6:00 -> sin(pi/2) = 1' );

is( Algorithm::Time::ToNumber->angle('12:00'),
    expected_angle(12, 0), '12:00 -> sin(pi) ~= 0' );

is( Algorithm::Time::ToNumber->angle('18:00'),
    expected_angle(18, 0), '18:00 -> sin(3*pi/2) = -1' );

is( Algorithm::Time::ToNumber->angle('23:30'),
    expected_angle(23, 30), '23:30' );

is( Algorithm::Time::ToNumber->angle('0:00:30'),
    expected_angle(0, 0, 30), '0:00:30 with seconds' );

is( Algorithm::Time::ToNumber->angle('12:15:45'),
    expected_angle(12, 15, 45), '12:15:45 with seconds' );

done_testing();
