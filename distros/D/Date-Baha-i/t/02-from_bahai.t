#!/usr/bin/env perl -T
use Test::More;

use Date::Calc qw(Delta_Days Add_Delta_Days);

use_ok 'Date::Baha::i';

# Test Baha'i year.
my @start = (2003, 3, 21);
my @stop  = (2004, 3, 20);

# The Baha'i year starts at 160.
my ($year, $month, $day, $max) = (160, 1, 1, 19);

for (0 .. Delta_Days(@start, @stop)) {
    # Increment test date.
    my @x = Add_Delta_Days(@start, $_);
    my $x = sprintf '%4d/%02d/%02d', @x;

    my @y = from_bahai(
        year  => $year,
        month => $month,
        day   => $day,
    );
    my $y = sprintf '%4d/%02d/%02d', @y;
    is $x, $y, "$x is $y";

    # Increment test control date.
    $day++;
    if ($day > $max) {
        $day = 1;
        $month++;
        $month = 1 if $month > $max;
    }
    # Hardcode for 5 days of Ayyam-i-Ha.
    if ($month == 19 && $day == 1) {
        $month = -1;
    }
    if ($month == -1 && $day == 6) {
        $month = 19;
        $day = 1;
    }
}

done_testing();
