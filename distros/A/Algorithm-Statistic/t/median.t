#!perl

use strict;
use warnings;

use Test::More;

use_ok( 'Algorithm::Statistic', 'median' );

sub compare {
    $_[0] <=> $_[1];
}

{
    is(median([4,5,3,6,7,8,9,2,1,0]), 5);
    
    is(median([16,18,10,16,12]), 16);

    is(median([1]), 1);
    is(median([0, 1]), 1);
    
    is(median([4.1,5.2,3.3,6.4,7.5,8.6,9.7,2.8,1.9,0.0]), 5.2);
    
    is(median([1,2,3,4]), 3);
    
    # Mixed ints and floats
    is(median([1.2,2,3.1,4,5]), 3.1);

    # Checking with comparator
    is(median([4,5,3,6,7,8,9,2,1,0], \&compare), 5);
    
    is(median([16,18,10,16,12], \&compare), 16);

    is(median([1], \&compare), 1);
    is(median([0, 1], \&compare), 1);
    
    is(median([4.1,5.2,3.3,6.4,7.5,8.6,9.7,2.8,1.9,0.0], \&compare), 5.2);
    
    is(median([1,2,3,4], \&compare), 3);

    {
        no warnings 'all';
        is(median([], \&compare), undef);
        is(median({}, \&compare), undef);
    }

}

done_testing();
