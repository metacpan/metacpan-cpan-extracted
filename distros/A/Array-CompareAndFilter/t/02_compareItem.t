#!/usr/bin/perl
################################################################################
#
# File:     02_compareItem.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function compareItem.
#
################################################################################
#
# Updates:
# 2012-09-01 H. Klausing
#       Version number removed.
# 2012-08-12 v 1.0.2   H. Klausing
#       version number incremented
# 2012-08-05 v 1.0.1   H. Klausing
#       required perl version removed.
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
use Test::More(tests => 20);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(compareItem);

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

    #*** compareItem ********************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {compareItem('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "compareItem: Compare error detection, parameter 1, ('1', [1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {compareItem([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "compareItem: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8], '2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {compareItem([1, 2, 3, 4, 5, 6, 7, 8])}
    "compareItem: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {compareItem()} "compareItem: Compare error detection, without parameters, ()";

    # Test - Compare empty arrays, ([], [])==1
    is(compareItem([], []), 1, 'compareItem: Compare empty arrays, ([], [])==1');

    # Test - Compare equal arrays, ([1,2,3,4,5,6,7,8], [1,2,3,4,5,6,7,8])==1
    is(compareItem([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]),
        1, 'compareItem: Compare equal arrays, ([1,2,3,4,5,6,7,8], [1,2,3,4,5,6,7,8])==1');

    # Test - Compare equal arrays, ([qw(foo buz dol igu)], [qw(foo buz dol igu)])==1
    is(compareItem([qw(foo buz dol igu)], [qw(foo buz dol igu)]),
        1, 'compareItem: Compare equal arrays, ([qw(foo buz dol igu)], [qw(foo buz dol igu)])==1');

    # Test - Compare equal arrays, ([qw(foo buz dol igu)], [qw(buz dol igu foo)])==1
    is(compareItem([qw(foo buz dol igu)], [qw(buz dol igu foo)]),
        1, 'compareItem: Compare equal arrays, ([qw(foo buz dol igu)], [qw(buz dol igu foo)])==1');

    # Test - Compare equal arrays with different order, ([1,2,3,4,5,6,7,8], [2,1,3,4,5,6,7,8])==1
    is(compareItem([1, 2, 3, 4, 5, 6, 7, 8], [2, 1, 3, 4, 5, 6, 7, 8]),
        1, 'compareItem: Compare equal arrays with different order, ([1,2,3,4,5,6,7,8], [2,1,3,4,5,6,7,8])==1');

    # Test - Compare different arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8])==0
    is(compareItem([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8]),
        0, 'compareItem: Compare different arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8])==0');

    # Test - Compare different arrays with different size, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])==0
    is(compareItem([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8, 9]),
        0, 'compareItem: Compare different arrays with different size, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])==0');

    # Test - Compare equal arrays with repeated items, ([1,2,1,2,1,2], [2,1,2,1,2,1])==1
    is(compareItem([1, 2, 1, 2, 1, 2], [2, 1, 2, 1, 2, 1]),
        1, 'compareItem: Compare equal arrays with repeated items, ([1,2,1,2,1,2], [2,1,2,1,2,1])==1');

    # Test - check behaviour of empty arrays, ([],[])==1
    is(compareItem([], []), 1, 'compareItem: check behaviour of empty arrays, ([],[])==1');

    # Test - check behaviour of undefined value arrays, ([undef],[undef])==1
    is(compareItem([undef], [undef]), 1, 'compareItem: check behaviour of undefined value arrays, ([undef],[undef])==1');

    # Test - check behaviour of undefined value arrays, ([undef],[undef,undef])==0
    is(compareItem([undef], [undef, undef]),
        0, 'compareItem: check behaviour of undefined value arrays, ([undef],[undef,undef])==0');

    # Test - check big equal arrays, ([1..100000], [1..100000])==1
    is(compareItem([1 .. 100000], [1 .. 100000]), 1, 'compareItem: check big equal arrays, ([1..100000], [1..100000])==1');

    # Test - check big unequal arrays, ([1..100000], [1000000..1])==0
    is(compareItem([1 .. 100000], [1000000 .. 1]), 0, 'compareItem: check big unequal arrays, ([1..100000], [1000000..1])==0');

    # Test - check big unequal arrays, ([1..100000], [0..100000])==0
    is(compareItem([1 .. 100000], [0 .. 100000]), 0, 'compareItem: check big unequal arrays, ([1..100000], [0..100000])==0');

    # examples
    # compareItem([1,2,3,5], [2,1,4,3])==0
    is(compareItem([1, 2, 3, 5], [2, 1, 4, 3]), 0, 'example: compareItem([1,2,3,5], [2,1,4,3])==0');

    # compareItem([1,2,3,4], [2,1,4,3])==1
    is(compareItem([1, 2, 3, 4], [2, 1, 4, 3]), 1, 'example: compareItem([1,2,3,4], [2,1,4,3])==1');

    #
    #
    #
    return;
} ## end sub main
__END__
