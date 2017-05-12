#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter qw(substractItem);

sub filter {
    my ($arr1_ref, $arr2_ref, @expectedResult) = @_;
    my @result = substractItem($arr1_ref, $arr2_ref);
    print("Result: (@$arr1_ref) op (@$arr2_ref) -> (@result)\n");

    if (@result != @expectedResult) {
        print("Error: unexpected result!\n");
        print("       expected: (@expectedResult)\n");
        exit(1);
    }
}
print("Examples for substractItem()\n");
my @array1 = (1, 2, 3, 2, 5);
my @array2 = (5, 3, 2, 1);

# expected output:
#  @array1: 1 2 3 2 5
#  @array2: 5 3 2 1
filter(\@array1, \@array2, (2));

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 2
@array2 = (5, 2);
filter(\@array1, \@array2, (1, 3, 4));

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 6 7 8 9 0
@array2 = (6, 7, 8, 9, 0);
filter(\@array1, \@array2, (1 .. 5));
exit(0);
