#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter qw(unique);

sub filter {
    my ($arr1_ref, $arr2_ref, @expectedResult) = @_;
    my @result = unique($arr1_ref, $arr2_ref);
    print("Result: (@$arr1_ref) op (@$arr2_ref) -> (@result)\n");

    if (@result != @expectedResult) {
        print("Error: unexpected result!\n");
        print("       expected: (@expectedResult)\n");
        exit(1);
    }
}
print("Examples for unique()\n");
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
filter(\@array1, \@array2, (1));

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 6 7 8 9 0
@array2 = (6, 7, 8, 9, 0);
filter(\@array1, \@array2, (1 .. 5));
exit(0);
