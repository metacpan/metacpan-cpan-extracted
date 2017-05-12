use warnings;
use strict;
use Test::Requires{ 'Test::LeakTrace' => 0.13 };
use Test::More;

use_ok( 'Algorithm::Statistic', ':all' );

sub compare {
    $_[0] <=> $_[1];
}


no_leaks_ok {
    my $statistic_extended = kth_order_statistic([0,1], 1, \&compare); 
    my $statistic = kth_order_statistic([0,1], 1); 

    my $median = median([0, 1]);
    my $median_extended = median([0, 1], \&compare);
};

done_testing();
