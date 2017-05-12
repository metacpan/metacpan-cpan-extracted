package Date::Converter::Zoroastrian;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;
    
    $f = 0 unless defined $f;

    my $jed_epoch = epoch_to_jed();

    my $jed = $jed_epoch + (($d - 1) + 30 * ($m - 1) + 365 * ($y - 1));
    $jed += $f;

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $jed_epoch = epoch_to_jed();

    my $j = int ($jed - $jed_epoch);
    my $f = ($jed - $jed_epoch) - $j;
        
    my ($y, $m, $d);
    {
        use integer;

        $d = 1 + $j;
        $m = 1;
        $y = 1;
        
        my $years = ($d - 1) / 365;
        $y += $years;
        $d -= $years * 365;
        
        my $months = ($d - 1) / 30;
        $m += $months;
        $d = $d - $months * 30;
    }
    
    return ($y, $m, $d, $f);
}

sub epoch_to_jed {
    return 1579768.5;
}

1;
