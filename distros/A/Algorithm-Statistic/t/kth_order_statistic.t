#!perl

use strict;
use warnings;

use Test::More;

use_ok( 'Algorithm::Statistic', 'kth_order_statistic' );

sub compare {
    $_[0] <=> $_[1];
}


# Ordinary check
{
    my @elements = (4,5,3,6,7,8,9,2,1,0); 
    my @expected = (0,1,2,3,4,5,6,7,8,9);

    for (my $i=0; $i<scalar(@elements); ++$i) {
        my $statistic_with_comparator = kth_order_statistic(\@elements, $i, \&compare);
        my $statistic = kth_order_statistic(\@elements, $i);
        is($statistic, $expected[$i], 
            "$i-th statistic should be equal to $expected[$i] for @elements."); 
        is($statistic_with_comparator, $expected[$i], 
            "$i-th statistic with extended comparator should be equal to $expected[$i] for @elements."); 
    }
}


# Array with duplicates check
{
    my @elements = (16,18,10,16,12);
    my @expected = (10,12,16,16,18);

    for (my $i=0; $i<scalar(@elements); ++$i) {
        my $statistic = kth_order_statistic(\@elements, $i, \&compare);
        is($statistic, $expected[$i], "$i-th statistic should be equal to $expected[$i] for @elements."); 

        # And reverse comparator
        $statistic = kth_order_statistic(\@elements, $i, sub {$_[1] <=> $_[0]});
        my $index = scalar(@expected) - $i - 1;
        is($statistic, $expected[$index], 
            "$i-th statistic should be equal to $expected[$index] for @elements with reverse comparator."); 
    }
}


# Floating numbers
{
    my @elements = (4.1,5.2,3.3,6.4,7.5,8.6,9.7,2.8,1.9,0.0);
    my @expected = (0.0,1.9,2.8,3.3,4.1,5.2,6.4,7.5,8.6,9.7);

    for (my $i=0; $i<scalar(@elements); ++$i) {
        my $statistic = kth_order_statistic(\@elements, $i, \&compare);
        my $statistic_with_comparator = kth_order_statistic(\@elements, $i, \&compare);
        is($statistic, $expected[$i], 
            "$i-th statistic should be equal to $expected[$i] for @elements."); 
        is($statistic_with_comparator, $expected[$i], 
            "$i-th statistic with extended comparator should be equal to $expected[$i] for @elements."); 
    }
}


# Checking empty array
{
    no warnings;
    my $statistic = kth_order_statistic([], 2, \&compare);
    use warnings;
    
    is($statistic, undef, "Statistic should be undefined for empty array");
}


# Search the element that doesn't exist
{
    no warnings;
    my $statistic = kth_order_statistic([0,1,2], 10, \&compare);
    use warnings;
        
    is($statistic, undef, "Should be undef for out of range position."); 
}


done_testing();
