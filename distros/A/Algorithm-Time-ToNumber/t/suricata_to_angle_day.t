#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);
use Time::Piece;

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_angle_day {
    my ($date) = @_;
    my $t = Time::Piece->strptime($date, '%Y-%m-%d');
    my $angle = 2 * pi * $t->day_of_week / 7;
    return sin($angle);
}

my $sin;

# 2026-07-03 is a Friday (dow 5)
$sin = Algorithm::Time::ToNumber->suricata_to_angle_day('2026-07-03T6:00:31.121465-0500');
is( $sin, expected_angle_day('2026-07-03'), 'Friday sin' );

# 2026-07-05 is a Sunday (dow 0)
$sin = Algorithm::Time::ToNumber->suricata_to_angle_day('2026-07-05T12:00:00.000000-0500');
is( $sin, expected_angle_day('2026-07-05'), 'Sunday sin' );

# 2026-07-06 is a Monday (dow 1)
$sin = Algorithm::Time::ToNumber->suricata_to_angle_day('2026-07-06T23:59:59.999999-0500');
is( $sin, expected_angle_day('2026-07-06'), 'Monday sin' );

done_testing();
