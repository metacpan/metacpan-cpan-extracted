package Date::Converter::Tamil;
# Also known as Hundu Solar

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

# E Reingold, N Dershowitz, S Clamen,
# Calendrical Calculations, II: Three Historical Calendars,
# Software - Practice and Experience,
# Volume 23, Number 4, pages 383-404, April 1993.

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    my $jed_epoch = epoch_to_jed();

    my $jed =
        $jed_epoch +
        ($d - 1) +
        ($m - 1) * month_length() +
        $y * year_length();

    $jed += $f;

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $jed_epoch = epoch_to_jed();

    my $j = int ($jed - $jed_epoch);
    my $f = ($jed - $jed_epoch) - $j;
        
    my $y = int ($j / year_length());
    $j -= int ($y * year_length());
    my $m = 1 + int ($j / month_length());
    $j -= int (($m - 1) * month_length());
        
    my $d = 1 + $j;
    
    return ($y, $m, $d, $f);
}

sub epoch_to_jed {
#    my ($jed) = @_;

    return 588466.75;
}

sub month_length {
    return year_length() / 12.0;
}

sub year_length {
    return 1577917828.0 / 4320000.0;
}

1;
