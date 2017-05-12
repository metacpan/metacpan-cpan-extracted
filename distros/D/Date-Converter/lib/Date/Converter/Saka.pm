package Date::Converter::Saka;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;

    $f = 0 unless defined $f;
    
    my ($y_prime, $m_prime, $d_prime, $j1, $j2, $z, $g);
    {
        use integer;
        
        $y_prime = $y + 4794 - (13 - $m) / 12;
        $m_prime = ($m + 10) % 12;
        $d_prime = $d - 1;

        $j1 = (1461 * $y_prime) / 4;
        $z = $m_prime / 6;
        $j2 = (31 - $z) * $m_prime + 5 * $z;
        $g = 3 * (($y_prime + 184) / 100) / 4 - 36;
    }
    
    my $jed = $j1 + $j2 + $d_prime - 1348 - $g - 0.5;
    $jed += $f;

    return $jed;
}

sub jed_to_ymdf {
    my ($jed) = @_;

    my $j = int ($jed + 0.5);
    my $f = ($jed + 0.5) - $j;
    
    my ($g, $j_prime, $y_prime, $t_prime, $x, $z, $s, $m_prime, $d_prime, $y, $m, $d);
    {
        use integer;
        
        $g = 3 * ((4 * $j + 274073) / 146097) / 4 - 36;
        
        $j_prime = $j + 1348 + $g;
        $y_prime = (4 * $j_prime + 3) / 1461;
        $t_prime = ((4 * $j_prime + 3) % 1461 ) / 4;
        
        $x = $t_prime / 365;
        $z = $t_prime / 185 - $x;
        $s = 31 - $z;
        
        $m_prime = ($t_prime - 5 * $z ) / $s;
        $d_prime = 6 * $x + (($t_prime - 5 * $z) % $s);

        $d = $d_prime + 1;
        $m = (($m_prime + 1) % 12 ) + 1;
        $y = $y_prime - 4794 + (13 - $m) / 12;
    }
    
    return ($y, $m, $d, $f);
}

1;
