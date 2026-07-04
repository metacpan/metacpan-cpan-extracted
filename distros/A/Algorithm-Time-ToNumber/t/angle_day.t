#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_angle_day {
    my ($day) = @_;
    my $angle = 2 * pi * $day / 7;
    return sin($angle);
}

my $sin;

$sin = Algorithm::Time::ToNumber->angle_day(0);
is( $sin, expected_angle_day(0), 'day 0 (Sunday) sin' );

$sin = Algorithm::Time::ToNumber->angle_day(1);
is( $sin, expected_angle_day(1), 'day 1 (Monday) sin' );

$sin = Algorithm::Time::ToNumber->angle_day(3);
is( $sin, expected_angle_day(3), 'day 3 (Wednesday) sin' );

$sin = Algorithm::Time::ToNumber->angle_day(6);
is( $sin, expected_angle_day(6), 'day 6 (Saturday) sin' );

done_testing();
