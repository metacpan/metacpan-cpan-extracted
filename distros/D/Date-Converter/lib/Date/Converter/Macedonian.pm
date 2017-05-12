package Date::Converter::Macedonian;

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
    
    my ($y_prime, $m_prime, $d_prime, $j1, $j2);
    {
        use integer;
        
        $y_prime = $y + 4405 - (18 - $m) / 12;
        $m_prime = ($m + 5) % 12;
        $d_prime = $d - 1;

        $j1 = (1461 * $y_prime) / 4;
        $j2 = (153 * $m_prime + 2) / 5;
    }
    
    my $jed = $j1 + $j2 + $d_prime - 1401 - 0.5;
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

        $j_prime = $j + 1401;
        
        $y_prime = (4 * $j_prime + 3) / 1461;
        $t_prime = ((4 * $j_prime + 3) % 1461) / 4;
        $m_prime = (5 * $t_prime + 2) / 153;
        $d_prime = ((5 * $t_prime + 2) % 153) / 5;
        
        $d = $d_prime + 1;
        $m = (($m_prime + 6) % 12 ) + 1;
        $y = $y_prime - 4405 + (18 - $m) / 12;
    }
        
    return ($y, $m, $d, $f);
}

1;
