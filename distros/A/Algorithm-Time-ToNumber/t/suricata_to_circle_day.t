#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);
use Time::Piece;

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_circle_day {
    my ($date) = @_;
    my $t = Time::Piece->strptime($date, '%Y-%m-%d');
    my $angle = 2 * pi * $t->day_of_week / 7;
    return ( sin($angle), cos($angle) );
}

my ( $sin, $cos );

# 2026-07-03 is a Friday (dow 5)
( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle_day('2026-07-03T6:00:31.121465-0500');
my ( $esin, $ecos ) = expected_circle_day('2026-07-03');
is( $sin, $esin, 'Friday sin' );
is( $cos, $ecos, 'Friday cos' );

# 2026-07-05 is a Sunday (dow 0)
( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle_day('2026-07-05T12:00:00.000000-0500');
( $esin, $ecos ) = expected_circle_day('2026-07-05');
is( $sin, $esin, 'Sunday sin' );
is( $cos, $ecos, 'Sunday cos' );

# 2026-07-06 is a Monday (dow 1)
( $sin, $cos ) = Algorithm::Time::ToNumber->suricata_to_circle_day('2026-07-06T23:59:59.999999-0500');
( $esin, $ecos ) = expected_circle_day('2026-07-06');
is( $sin, $esin, 'Monday sin' );
is( $cos, $ecos, 'Monday cos' );

done_testing();
