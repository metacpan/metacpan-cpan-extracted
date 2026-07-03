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

( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle('2026-07-03T0:00:00.000000-0500');
my ( $esin, $ecos ) = expected_circle(0, 0, 0);
is( $sin, $esin, 'midnight sin' );
is( $cos, $ecos, 'midnight cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle('2026-07-03T6:00:31.121465-0500');
( $esin, $ecos ) = expected_circle(6, 0, 31.121465);
is( $sin, $esin, '6:00:31.121465 sin' );
is( $cos, $ecos, '6:00:31.121465 cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle('2026-07-03T12:00:00.000000-0500');
( $esin, $ecos ) = expected_circle(12, 0, 0);
is( $sin, $esin, 'noon sin' );
is( $cos, $ecos, 'noon cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle('2026-07-03T18:30:15.999999-0500');
( $esin, $ecos ) = expected_circle(18, 30, 15.999999);
is( $sin, $esin, '18:30:15.999999 sin' );
is( $cos, $ecos, '18:30:15.999999 cos' );

( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle('2026-07-03T23:59:59.999999-0500');
( $esin, $ecos ) = expected_circle(23, 59, 59.999999);
is( $sin, $esin, 'end of day sin' );
is( $cos, $ecos, 'end of day cos' );

done_testing();
