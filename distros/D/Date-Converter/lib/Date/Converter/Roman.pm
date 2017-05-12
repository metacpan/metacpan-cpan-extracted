package Date::Converter::Roman;

use strict;
use base 'Date::Converter';
use Date::Converter::Julian;

use vars qw($VERSION);
$VERSION = 1.1;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    return -1 if ymd_check(\$y, \$m, \$d);

    my $y2 = y_roman_to_julian($y);
    my $jed = Date::Converter::Julian::ymdf_to_jed($y2, $m, $d, $f);

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my ($yj, $m, $d, $f) = Date::Converter::Julian::jed_to_ymdf($jed);
    my $y = y_julian_to_roman($yj);

    return ($y, $m, $d, $f);
}

sub y_roman_to_julian {
    my ($y) = @_;

    my $y2 = $y - 753;
    $y2-- if $y2 <= 0;
    
    return $y2;
}

sub y_julian_to_roman {
    my ($y) = @_;

    return -1 if Date::Converter::Julian::y_check(\$y);

    $y++ if $y < 0;
  
    my $y2 = $y + 753;
    
    return $y2;
}

sub ymd_check {
    my ($y_ref, $m_ref, $d_ref) = @_;

    return 1 if $$y_ref <= 0;

    month_borrow($y_ref, $m_ref);
    month_carry($y_ref, $m_ref);
    
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

    return 12;
}

sub month_length {
    my ($y, $m) = @_;

    my @mdays = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    return 0 if ym_check(\$y, \$m);

    my $ret = $mdays[$m - 1];

    $ret++ if $m == 2 && year_is_leap($y);
    
    return $ret;
}

sub year_is_leap {
    my ($y) = @_;

    return 0 if y_check($y);

    my $y2 = y_roman_to_julian($y);
    
    return Date::Converter::Julian::year_is_leap($y2);
}

1;
