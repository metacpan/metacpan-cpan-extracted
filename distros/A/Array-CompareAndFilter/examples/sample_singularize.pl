#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Array::CompareAndFilter qw(singularize);
my @expectedResult = ();

sub filter {
    my ($arr1_ref, $order) = @_;
    my @result = singularize($arr1_ref, $order);
    my $OrderName = '[sorted]';
    if (not defined($order)) {$order = ''}
    if    ($order eq 'b') {$OrderName = '[from begin to end]'}
    elsif ($order eq 'e') {$OrderName = '[from end to begin]'}
    elsif ($order ne '') {$OrderName = '[sorted, unknown]'}
    print("Result: (@$arr1_ref) -> (@result) $OrderName\n");

    if (@result != @expectedResult) {
        print("Error: unexpected result!\n");
        print("       expected: (@expectedResult)\n");
        exit(1);
    }
}
print("Examples for singularize()\n");
my @array1 = (2, 1, 4, 2, 1, 3);

# expected output:
#  @array1: 2 1 4 2 1 3
@expectedResult = (1 .. 4);
filter(\@array1);

# expected output:
#  @array1: 2 1 4 2 1 3
@expectedResult = (1 .. 4);
filter(\@array1, 's');

# expected output:
#  @array1: 2 1 4 2 1 3
@expectedResult = (2, 1, 4, 3);
filter(\@array1, 'b');

# expected output:
#  @array1: 2 1 4 2 1 3
@expectedResult = (4, 2, 1, 3);
filter(\@array1, 'e');
exit(0);
