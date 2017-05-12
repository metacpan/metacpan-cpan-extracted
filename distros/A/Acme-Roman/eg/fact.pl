#!perl 

use strict;
use warnings;

use Acme::Roman;

# Compute factorials
sub fact {
    my $n = shift;
    return ( $n==I ) ? I : $n*fact( $n-1 );
}

for ( I, II, III, IV, V, VI ) { # I..VI does not work :(
    printf "%s! = %s\n", $_, fact($_);
}

