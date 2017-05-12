package Date::Converter::Persian;

use strict;
use base 'Date::Converter';

use vars qw($VERSION);
$VERSION = 1.1;

# E G Richards,
# Algorithm E,
# Mapping Time, The Calendar and Its History,
# Oxford, 1999, pages 323-324.

sub ymdf_to_jed {
    my ($y, $m, $d, $f) = @_;
    
    my ($y_prime, $m_prime, $d_prime);
    {
        use integer;
        
        $y_prime = $y + 5348 - (22 - $m) / 13;
        $m_prime = ($m + 3) % 13;
        $d_prime = $d - 1;
    }

    my $jed = 365 * $y_prime + 30 * $m_prime + $d_prime - 77 - 0.5;
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
        
        $j_prime = $j + 77;
        
        $y_prime = $j_prime / 365;
        $t_prime = $j_prime %365;
        $m_prime = $t_prime / 30;
        $d_prime = $t_prime % 30;

        $d = $d_prime + 1;
        $m = (($m_prime + 9) % 13) + 1;
        $y = $y_prime - 5348 + (22 - $m) / 13;
    }
    
    return ($y, $m, $d, $f);
}

1;
