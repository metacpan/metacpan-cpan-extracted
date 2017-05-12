package Date::Converter::Hebrew;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless $f;

    my $months = year_months($y);
    my $jed = epoch() + delay_1($y) + delay_2($y) + $d + 1;

    if ($m < 7) {
        for (my $mon = 7; $mon <= $months; $mon++) {
            $jed += month_days($y, $mon);
        }
        for (my $mon = 1; $mon < $m; $mon++) {
            $jed += month_days($y, $mon);
        }
    } else {
        for (my $mon = 7; $mon < $m; $mon++) {
            $jed += month_days($y, $mon);
        }
    }

    $jed += $f;
    
    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;
    
    my ($y, $m, $d);

    $jed = int($jed) + 0.5;
    my $count = int((($jed - epoch()) * 98496.0) / 35975351.0);
    $y = $count - 1;
    for (my $i = $count; $jed >= ymdf_to_jed($i, 7, 1); $i++) {
        $y++;
    }
    my $first = ($jed < ymdf_to_jed($y, 1, 1)) ? 7 : 1;
    $m = $first;
    for (my $i = $first; $jed > ymdf_to_jed($y, $i, month_days($y, $i)); $i++) {
        $m++;
    }
    $d = ($jed - ymdf_to_jed($y, $m, 1)) + 1;
    
    return ($y, $m, $d, 0);
}

sub epoch {
    return 347995.5;
}

sub leap {
    my ($y) = @_;

    return ((($y * 7) + 1) % 19) < 7;
}

sub year_months {
    my ($y) = @_;

    return leap($y) ? 13 : 12;
}

sub delay_1 {
    my ($y) = @_;  

    my $months = int(((235 * $y) - 234) / 19);
    my $parts = 12084 + (13753 * $months);
    my $days = ($months * 29) + int($parts / 25920);

    if (((3 * ($days + 1)) % 7) < 3) {
        $days++;
    }
    
    return $days;
}

sub delay_2 {
    my ($y) = @_;

    my $last = delay_1($y - 1);
    my $present = delay_1($y);
    my $next = delay_1($y + 1);

    return (($next - $present) == 356) ? 2 : ((($present - $last) == 382) ? 1 : 0);
}

sub year_days {
    my ($y) = @_;

    return ymdf_to_jed($y + 1, 7, 1) - ymdf_to_jed($y, 7, 1);
}

sub month_days {
    my ($y, $m) = @_;

    if ($m == 2 || $m == 4 || $m == 6 ||
        $m == 10 || $m == 13) {
        return 29;
    }

    if ($m == 12 && !leap($y)) {
        return 29;
    }

    if ($m == 8 && !((year_days($y) % 10) == 5)) {
        return 29;
    }
    
    if ($m == 9 && ((year_days($y) % 10) == 3)) {
        return 29;
    }

    return 30;
}

1;
