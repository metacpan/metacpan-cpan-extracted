#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_circle_day {
    my ($day) = @_;
    my $angle = 2 * pi * $day / 7;
    return ( sin($angle), cos($angle) );
}

my ( $sin, $cos );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle_day(0);
my ( $esin, $ecos ) = expected_circle_day(0);
is( $sin, $esin, 'day 0 (Sunday) sin' );
is( $cos, $ecos, 'day 0 (Sunday) cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle_day(1);
( $esin, $ecos ) = expected_circle_day(1);
is( $sin, $esin, 'day 1 (Monday) sin' );
is( $cos, $ecos, 'day 1 (Monday) cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle_day(3);
( $esin, $ecos ) = expected_circle_day(3);
is( $sin, $esin, 'day 3 (Wednesday) sin' );
is( $cos, $ecos, 'day 3 (Wednesday) cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle_day(6);
( $esin, $ecos ) = expected_circle_day(6);
is( $sin, $esin, 'day 6 (Saturday) sin' );
is( $cos, $ecos, 'day 6 (Saturday) cos' );

done_testing();
