package Date::Converter::Republican;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    return -1 if ymd_check(\$y, \$m, \$d);

    my ($y_prime, $m_prime, $d_prime, $j1, $j2, $g);
    {
        use integer;

        $y_prime = $y + 6504 - (13 - $m) / 13;
        $m_prime = ($m + 12) % 13;
        $d_prime = $d - 1;

        $j1 = (1461 * $y_prime) / 4;        
        $j2 = 30 * $m_prime;
        
        $g = 3 * (($y_prime + 396) / 100) / 4 - 51;
    }
    
    my $jed = $j1 + $j2 + $d_prime - 111 - $g - 0.5;
    $jed += $f;

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $j = int ($jed + 0.5);
    my $f = ($jed + 0.5) - $j;
    
    my ($g, $j_prime, $y_prime, $t_prime, $m_prime, $d_prime, $y, $m, $d);
    {
        use integer;
        
        $g = 3 * ((4 * $j + 578797) / 146097) / 4 - 51;
        $j_prime = $j + 111 + $g;
        
        $y_prime =  (4 * $j_prime + 3) / 1461;
        $t_prime = ((4 * $j_prime + 3) % 1461) / 4;
        $m_prime = $t_prime / 30;
        $d_prime = $t_prime % 30;

        $d = $d_prime + 1;
        $m = ($m_prime % 13) + 1;
        $y = $y_prime - 6504 + (13 - $m) / 13;    
    }
    
    return ($y, $m, $d, $f);
}

sub ymd_check {
    my ($y_ref, $m_ref, $d_ref) = @_;

    return 1 if $$y_ref <= 0;

    return 1 if ym_check($y_ref, $m_ref);

    day_borrow($y_ref, $m_ref, $d_ref);
    day_carry($y_ref, $m_ref, $d_ref);

    return 0;
}

sub ym_check {
    my ($y_ref, $m_ref) = @_;

    return 1 if y_check($y_ref);

    month_borrow($y_ref, $m_ref);
    month_carry($y_ref, $m_ref);
    
    return 0;
}

sub y_check {
    my ($y_ref) = @_;

    return !($$y_ref > 0);
}

sub month_borrow {
    my ($y_ref, $m_ref) = @_;

    while ($$m_ref <= 0) {
        $$m_ref += year_length_months($$y_ref);
        $$y_ref--;
    }
}

sub month_carry {
    my ($y_ref, $m_ref) = @_;

    my $months = year_length_months($$y_ref);

    return if $$m_ref <= $months;

    $$m_ref -= $months;
    $$y_ref++;
}

sub day_borrow {
    my ($y_ref, $m_ref, $d_ref) = @_;

    while ($$d_ref <= 0) {        
        $$m_ref--;

        month_borrow($y_ref, $m_ref);
        $$d_ref += month_length($$y_ref, $$m_ref);
    }
}

sub day_carry {
    my ($y_ref, $m_ref, $d_ref) = @_;

    my $days = month_length($$y_ref, $$m_ref);
    my $months = year_length_months($$y_ref);
    
    while ($$d_ref > $days) {        
        $$d_ref -= $days;
        $$m_ref++;
        
        $days = month_length($$y_ref, $$m_ref);
        month_carry($$y_ref, $$m_ref);
    }
}

sub year_length_months {
#    my $y = shift;

    return 13;
}

sub month_length {
    my ($y, $m) = @_;

    return 0 if ym_check(\$y, \$m);
    
    if (1 <= $m && $m <= 12) {
        return 30;
    }
    elsif ($m == 13) {
        if (year_is_leap($y)) {
            return 6;
        }
        else {
            return 5;
        }
    }
}

sub year_is_leap {
    my $y = shift;

    return 0 if y_check($y);

    my $ret = 0;

    if (($y + 1) % 4 == 0) {
        $ret = 1;
        if (($y + 1) % 100 == 0) {
            $ret = 0;
            if (($y + 1) % 400 == 0) {
                $ret = 1;
                if (($y + 1) % 4000 == 0) {
                   $ret = 0;
                }
            }
        }
    }

    return $ret;
}

1;
