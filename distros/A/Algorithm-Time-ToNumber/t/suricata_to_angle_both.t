#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Trig qw(pi);
use Time::Piece;

use_ok('Algorithm::Time::ToNumber') || print "Bail out!\n";

sub expected_angle_both {
    my ($timestamp) = @_;
    my ($date) = $timestamp =~ /^(\d{4}-\d{2}-\d{2})T/;
    my $t = Time::Piece->strptime($date, '%Y-%m-%d');
    my ($hms) = $timestamp =~ /T([\d:\.]+)/;
    my ($h, $m, $s) = split(/:/, $hms);
    $s //= 0;
    my $week_seconds = $t->day_of_week * 86400 + $h * 3600 + $m * 60 + $s;
    my $angle = 2 * pi * $week_seconds / 604800;
    return sin($angle);
}

my $sin;

# 2026-07-03 is a Friday (dow 5)
$sin = Algorithm::Time::ToNumber->suricata_to_angle_both('2026-07-03T0:00:00.000000-0500');
is( $sin, expected_angle_both('2026-07-03T0:00:00.000000-0500'), 'Friday midnight sin' );

$sin = Algorithm::Time::ToNumber->suricata_to_angle_both('2026-07-03T6:00:31.121465-0500');
is( $sin, expected_angle_both('2026-07-03T6:00:31.121465-0500'), 'Friday 6:00:31 sin' );

# 2026-07-05 is a Sunday (dow 0)
$sin = Algorithm::Time::ToNumber->suricata_to_angle_both('2026-07-05T12:00:00.000000-0500');
is( $sin, expected_angle_both('2026-07-05T12:00:00.000000-0500'), 'Sunday noon sin' );

# 2026-07-06 is a Monday (dow 1)
$sin = Algorithm::Time::ToNumber->suricata_to_angle_both('2026-07-06T23:59:59.999999-0500');
is( $sin, expected_angle_both('2026-07-06T23:59:59.999999-0500'), 'Monday end of day sin' );

done_testing();
