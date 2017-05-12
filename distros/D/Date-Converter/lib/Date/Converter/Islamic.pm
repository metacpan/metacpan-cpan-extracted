package Date::Converter::Islamic;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

# E G Richards,
# Algorithm E,
# Mapping Time, The Calendar and Its History,
# Oxford, 1999, pages 323-325.

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    return -1 if ymd_check(\$y, \$m, \$d);

    my ($y_prime, $m_prime, $d_prime, $j1, $j2);
    {
        use integer;
        
        $y_prime = $y + 5519 - (12 - $m) / 12;
        $m_prime = ($m + 11) % 12;
        $d_prime = $d - 1;

        $j1 = (10631 * $y_prime + 14) / 30;
        $j2 = (2951 * $m_prime + 51) / 100;
    }

    my $jed = ($j1 + $j2 + $d_prime - 7665) - 0.5;
    $jed += $f;

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $j = int ($jed + 0.5);
    my $f = ($jed + 0.5) - $j;

    my ($j_prime, $y_prime, $t_prime, $m_prime, $d_prime, $y, $m, $d);
    {
        use integer;
        
        $j_prime = $j + 7665;
        
        $y_prime = (30 * $j_prime + 15) / 10631;
        $t_prime = ((30 * $j_prime + 15) % 10631) / 30;
        $m_prime = (100 * $t_prime + 10) / 2951;
        $d_prime = ((100 * $t_prime + 10) % 2951) / 100;

        $d = $d_prime + 1;
        $m = ($m_prime % 12) + 1;
        $y = $y_prime - 5519 + (12 - $m) / 12;
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

    while ($$d_ref > $days) {  
        $$d_ref -= $days;
        $$m_ref++;
        $days = month_length($$y_ref, $$m_ref);
        month_carry($y_ref, $m_ref);
    }
}

sub year_length_months {
#   my $y = shift;
    
    return 12;
}

sub month_length {
    my ($y, $m) = @_;

    my @mdays = (30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29);

    return 0 if ym_check(\$y, \$m);

    my $ret = $mdays[$m - 1];

    $ret++ if $m == 12 && year_is_leap($y);
    
    return $ret;
}

sub year_is_leap {
    my $y = shift;

    return Date::Convert::i_modp (11 * $y + 14, 30) < 11;
}

1;
