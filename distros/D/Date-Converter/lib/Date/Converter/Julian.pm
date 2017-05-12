package Date::Converter::Julian;

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
    
    return -1 if ymdf_check(\$y, \$m, \$d, \$f);
  
    my $y2 = Date::Converter::y_common_to_astronomical($y);

    my ($y_prime, $m_prime, $d_prime, $j1, $j2);
    {
        use integer;
        $y_prime = $y2 + 4716 - (14 - $m) / 12;
        $m_prime = ($m + 9) % 12;
        $d_prime = $d - 1;
    
        $j1 = (1461 * $y_prime) / 4;
        $j2 = (153 * $m_prime + 2) / 5;
    }
    
    my $jed = ($j1 + $j2 + $d_prime - 1401) - 0.5;
    $jed += $f;
    
    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;
 
    my $j = int ($jed + 0.5);
    my $f = ($jed + 0.5) - $j;
    
    my ($j_prime, $y_prime, $t_prime, $m_prime, $d_prime, $d, $m, $y);
    {
        use integer;
        $j_prime = $j + 1401;
        
        $y_prime = (4 * $j_prime + 3) / 1461;
        $t_prime = ((4 * $j_prime + 3) % 1461) / 4;
        $m_prime = (5 * $t_prime + 2) / 153;
        $d_prime = ((5 * $t_prime + 2) % 153) / 5;
        
        $d = $d_prime + 1;
        $m = (($m_prime + 2) % 12) + 1;
        $y = $y_prime - 4716 + (14 - $m) / 12;
    }
    
    $y = Date::Converter::y_astronomical_to_common($y);
    
    return ($y, $m, $d, $f);
}

sub ymdf_check {
    my ($y_ref, $m_ref, $d_ref, $f_ref) = @_;

    return 1 if ymd_check($y_ref, $m_ref, $d_ref);

    frac_borrow($y_ref, $m_ref, $d_ref, $f_ref);
    frac_carry($y_ref, $m_ref, $d_ref, $f_ref);

    return 0;
}

sub ymd_check {
    my ($y_ref, $m_ref, $d_ref) = @_;

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

    return $$y_ref == 0;
}

sub frac_borrow {
    my ($y_ref, $m_ref, $d_ref, $f_ref) = @_;

    while ($$f_ref < 0) {        
        $$f_ref++;
        $$d_ref--;
    }

    day_borrow($y_ref, $m_ref, $d_ref);
}

sub frac_carry {
    my ($y_ref, $m_ref, $d_ref, $f_ref) = @_;

    return if $$f_ref < 1;
    
    my $days = int ($$f_ref);
    
    $$f_ref -= $days;
    $$d_ref += $days;
    
    day_carry($y_ref, $m_ref, $d_ref);
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

sub month_borrow {
    my ($y_ref, $m_ref) = @_;

    while ($$m_ref <= 0) {
        my $months = year_length_months($$y_ref);

        $$m_ref += $months;
        $$y_ref--;
    
        $$y_ref = -1 unless $$y_ref;
    }
}
    
sub month_carry {
    my ($y_ref, $m_ref) = @_;

    my $months = year_length_months($$y_ref);

    return if $$m_ref <= $months;

    $$m_ref -= $months;
    $$y_ref++;
}

sub year_length_months {
#    my ($y) = @_;

    return 12;
}

sub month_length {
    my ($y, $m) = @_;

    return 0 if ym_check(\$y, \$m);

    my @mdays = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    my $ret = $mdays[$m - 1];

    $ret++ if $m == 2 && year_is_leap($y);

    return $ret;
}

sub year_is_leap {
    my ($y) = @_;
    
    return 0 unless $y;
  
    my $y2 = Date::Converter::y_common_to_astronomical($y);

    return Date::Converter::i_modp($y, 4) == 0;
}

1;
