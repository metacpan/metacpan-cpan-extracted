#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter qw(difference);
sub filter {
    my ($arr1_ref, $arr2_ref, @expectedResult) = @_;
    my @result = difference($arr1_ref, $arr2_ref);
    print("Result: (@$arr1_ref) op (@$arr2_ref) -> (@result)\n");

    if (@result != @expectedResult) {
        print("Error: unexpected result!\n");
        print("       expected: (@expectedResult)\n");
        exit(1);
    }
}
print("Examples for difference()\n");
my @array1 = (1, 2, 3, 4, 5);
my @array2 = (5, 4, 3, 2, 1);

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 4 3 2 1
filter(\@array1, \@array2);

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 4 3 2 6
@array2 = (5, 4, 3, 2, 6);
filter(\@array1, \@array2, (2, 6));

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 6 7 8 9 0
@array2 = (6, 7, 8, 9, 0);
filter(\@array1, \@array2, (0 .. 9));
exit(0);
