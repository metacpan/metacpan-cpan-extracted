#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_circle {
    my ($h, $m, $s) = @_;
    $s //= 0;
    my $angle = 2 * pi * ($h * 3600 + $m * 60 + $s) / 86400;
    return ( sin($angle), cos($angle) );
}

my ( $sin, $cos );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('0:00');
my ( $esin, $ecos ) = expected_circle(0, 0);
is( $sin, $esin, '0:00 sin' );
is( $cos, $ecos, '0:00 cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('6:00');
( $esin, $ecos ) = expected_circle(6, 0);
is( $sin, $esin, '6:00 sin -> ~1' );
is( $cos, $ecos, '6:00 cos -> ~0' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('12:00');
( $esin, $ecos ) = expected_circle(12, 0);
is( $sin, $esin, '12:00 sin -> ~0' );
is( $cos, $ecos, '12:00 cos -> -1' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('18:00');
( $esin, $ecos ) = expected_circle(18, 0);
is( $sin, $esin, '18:00 sin -> ~-1' );
is( $cos, $ecos, '18:00 cos -> ~0' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('23:30');
( $esin, $ecos ) = expected_circle(23, 30);
is( $sin, $esin, '23:30 sin' );
is( $cos, $ecos, '23:30 cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('0:00:30');
( $esin, $ecos ) = expected_circle(0, 0, 30);
is( $sin, $esin, '0:00:30 sin with seconds' );
is( $cos, $ecos, '0:00:30 cos with seconds' );

( $sin, $cos ) = Algorithm::Time::ToNumber->circle('12:15:45');
( $esin, $ecos ) = expected_circle(12, 15, 45);
is( $sin, $esin, '12:15:45 sin with seconds' );
is( $cos, $ecos, '12:15:45 cos with seconds' );

done_testing();
