#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter qw(intersection);

sub filter {
    my ($arr1_ref, $arr2_ref, @expectedResult) = @_;
    my @result = intersection($arr1_ref, $arr2_ref);
    print("Result: (@$arr1_ref) op (@$arr2_ref) -> (@result)\n");

    if (@result != @expectedResult) {
        print("Error: unexpected result!\n");
        print("       expected: (@expectedResult)\n");
        exit(1);
    }
}
print("Examples for intersection()\n");
my @array1 = (1, 2, 3, 4, 5);
my @array2 = (5, 4, 3, 2, 1);

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 4 3 2 1
filter(\@array1, \@array2, (1 .. 5));

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 4 3 2 6
@array2 = (5, 4, 3, 2, 6);
filter(\@array1, \@array2, (2 .. 5));

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 6 7 8 9 0
@array2 = (6, 7, 8, 9, 0);
filter(\@array1, \@array2);

@array1=(1,2,3);
@array2=(1,2,3,4,4);
filter(\@array1, \@array2, (1,2,3));

@array1=(4,1,2,4,3);
@array2=(1,2,3);
filter(\@array1, \@array2, (1,2,3));

exit(0);
