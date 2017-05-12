#!/usr/bin/perl
################################################################################
#
# File:     03_compareOrder.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function compareOrder.
#
################################################################################
#
# Updates:
# 2012-09-01 H. Klausing
#       Version number removed.
# 2012-08-12 v 1.0.2   H. Klausing
#       version number incremented
# 2012-08-05 v 1.0.1   H. Klausing
#       version number incremented
# 2012-07-27 v 1.0.0   H. Klausing
#       Initial script version
#
################################################################################
#
#-------------------------------------------------------------------------------
# TODO -
#-------------------------------------------------------------------------------
#
#
#
#--- process requirements ---------------
use warnings;
use strict;

#
#
#
#--- global variables -------------------
#
#
#
#--- used modules -----------------------
use Test::More(tests => 17);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(compareOrder);

#
#
#
#--- function forward declarations ------
sub main;

#
#
#
#--- start script -----------------------
main();
exit 0;    # script execution was successful

#
#
#
################################################################################
#   script functions
################################################################################
#
#
#
#-------------------------------------------------------------------------------
# Main entry function for this script.
#-------------------------------------------------------------------------------
sub main {
    my @list;

    #*** compareOrder **********************************************************
    # Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])
    dies_ok {compareOrder('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "compareOrder: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Compare error detection, parameter 2, parameter 2, ([1,2,3,4,5,6,7,8],'2')
    dies_ok {compareOrder([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "compareOrder: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {compareOrder([1, 2, 3, 4, 5, 6, 7, 8])}
    "compareOrder: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {compareOrder()} "compareOrder: Compare error detection, without parameters, ()";

    # Compare empty arrays, ([], [])==1
    is(compareOrder([], []), 1, 'compareOrder: Compare empty arrays, ([], [])==1');

    # Compare order of equal arrays, ([1,2,3,4,5,6,7,8], [1,2,3,4,5,6,7,8])==1
    is(compareOrder([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]),
        1, 'compareOrder: Compare order of equal arrays, ([1,2,3,4,5,6,7,8], [1,2,3,4,5,6,7,8])==1');

    # Compare order of equal arrays with different order, ([1,2,3,4,5,6,7,8], [2,1,3,4,5,6,7,8])==0
    is(compareOrder([1, 2, 3, 4, 5, 6, 7, 8], [2, 1, 3, 4, 5, 6, 7, 8]),
        0, 'compareOrder: Compare order of equal arrays with different order, ([1,2,3,4,5,6,7,8], [2,1,3,4,5,6,7,8])==0');

    # Compare order of different arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8])==0
    is(compareOrder([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8]),
        0, 'compareOrder: Compare order of different arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8])==0');

    # Compare order of different arrays with different size([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])==0
    is(compareOrder([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8, 9]),
        0, 'compareOrder: Compare order of different arrays with different size([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])==0');

    # Compare equal arrays with repeated items, ([1,2,1,2,1,2], [1,2,1,2,1,2])==1
    is(compareOrder([1, 2, 1, 2, 1, 2], [1, 2, 1, 2, 1, 2]),
        1, 'compareOrder: Compare equal arrays with repeated items, ([1,2,1,2,1,2], [1,2,1,2,1,2])==1');

    # Check behaviour of empty arrays, ([], [])==1
    is(compareOrder([], []), 1, 'compareOrder: Check behaviour of empty arrays, ([], [])==1');

    # Check behaviour of empty array and scalar, ([], 1)==0
    dies_ok {compareOrder([], 1)} 'compareOrder: Check behaviour of empty array and scalar, ([], 1)==0';

    # Check behaviour of arrays with undef, ([undef], [undef])==1
    is(compareOrder([undef], [undef]), 1, 'compareOrder: Check behaviour of arrays with undef, ([undef], [undef])==1');

    # Check behaviour of different size arrays with undef, ([undef],[undef, 1])==0
    is(compareOrder([undef], [undef, 1]),
        0, 'compareOrder: Check behaviour of different size arrays with undef, ([undef],[undef,1])==0');

    # Check behaviour of arrays with undef, ([undef,1], [undef,1])==1
    is(compareOrder([undef, 1], [undef, 1]), 1,
        'compareOrder: Check behaviour of arrays with undef, ([undef,1], [undef,1])==1');

    # examples
    # compareOrder([1,2,3,4], [2,1,4,3])  == 0
    is(compareOrder([1, 2, 3, 4], [2, 1, 4, 3]), 0, 'example: compareOrder([1,2,3,4],[2,1,4,3])==0');

    # compareOrder([1,2,3,4], [1,2,3,4])  == 1
    is(compareOrder([1, 2, 3, 4], [1, 2, 3, 4]), 1, 'example: compareOrder([1,2,3,4],[1,2,3,4])==1');

    #
    #
    #
    return;
} ## end sub main
__END__
