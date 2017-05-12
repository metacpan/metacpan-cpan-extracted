#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter "compareOrder";

sub compare {
    my ($arr1_ref, $arr2_ref, $expectedResult) = @_;
    $expectedResult = defined($expectedResult) ? $expectedResult : 1;
    print("\@array1: @$arr1_ref\n");
    print("\@array2: @$arr2_ref\n");
    my $result = 0;

    if (compareOrder($arr1_ref, $arr2_ref)) {
        print("Result: \@array1 has equal items content and equal order like \@array2\n");
        $result = 1;
    }
    else {
        print("Result: \@array1 is different to \@array2\n");
    }

    if ($result != $expectedResult) {
        print("Error: unexpected result!\n");
        exit(1);
    }
}
print("Examples for compareOrder()\n");
my @array1 = (1, 2, 3, 4, 5);
my @array2 = (5, 4, 3, 2, 1);

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 4 3 2 1
#  Result: @array1 is different to @array2
compare(\@array1, \@array2, 0);

# expected output:
#  @array1: 1 2 3 4 5
#  @array2: 5 4 3 2 1 2
#  Result: @array1 is different to @array2
push(@array2, 2);
compare(\@array1, \@array2, 0);

# expected output:
#  @array1: 5 4 3 2 1 2
#  @array2: 5 4 3 2 1 2
#  Result: @array1 has equal items content and equal order like @array2
@array1 = @array2;
compare(\@array1, \@array2);
exit(0);
