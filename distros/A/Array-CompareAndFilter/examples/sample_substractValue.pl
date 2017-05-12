#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter qw(substractValue);

sub filter {
    my ($arr1_ref, $arr2_ref, @expectedResult) = @_;
    my @result = substractValue($arr1_ref, $arr2_ref);
    print("Result: (@$arr1_ref) op (@$arr2_ref) -> (@result)\n");

    if (@result != @expectedResult) {
        print("Error: unexpected result!\n");
        print("       expected: (@expectedResult)\n");
        exit(1);
    }
}
print("Examples for substractValue()\n");
my @array1 = (1, 2, 3, 2, 3);
my @array2 = (3, 2);

# expected output:
#  @array1: 1 2 3 2 3
#  @array2: 3 2
filter(\@array1, \@array2, (1));

# expected output:
#  @array1: 1 2 3 2 3
#  @array2: 1 2 3
@array2 = (1, 2, 3);
filter(\@array1, \@array2);

# expected output:
#  @array1: 1 2 3 2 3
#  @array2: 6 7 8 9 0
@array2 = (6, 7, 8, 9, 0);
filter(\@array1, \@array2, (1 .. 3));
exit(0);
