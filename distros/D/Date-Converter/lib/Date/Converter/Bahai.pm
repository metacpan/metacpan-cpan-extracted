package Date::Converter::Bahai;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    my ($y_prime, $m_prime, $d_prime, $j1, $j2, $g);
    {
        use integer;
        
        $y_prime = $y + 6560 - (39 - $m) / 20;
        $m_prime = $m % 20;
        $d_prime = $d - 1;

        $j1 = (1461 * $y_prime) / 4;        
        $j2 = 19 * $m_prime;
        
        $g = 3 * (($y_prime + 184) / 100) / 4 - 50;
    }
    
    my $jed = $j1 + $j2 + $d_prime - 1412 - $g - 0.5;
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

        $g = 3 * ((4 * $j + 274273) / 146097) / 4 - 50;
        $j_prime = $j + 1412 + $g;
        
        $y_prime = (4 * $j_prime + 3) / 1461;
        $t_prime = ((4 * $j_prime + 3) % 1461 ) / 4;
        $m_prime = $t_prime / 19;
        $d_prime = $t_prime % 19;

        $d = $d_prime + 1;
        $m = (($m_prime + 19) % 20) + 1;
        $y = $y_prime - 6560 + (39 - $m) / 20;
    }

    return ($y, $m, $d, $f);
}

1;
