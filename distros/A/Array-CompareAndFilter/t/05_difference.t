#!/usr/bin/perl
################################################################################
#
# File:     05_difference.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function difference.
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
use Test::More(tests => 12);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(difference);

#
#
#
#--- function forward declarations ------
main();
exit 0;                         # script execution was successful

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

    #*** difference ************************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {difference('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "difference: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {difference([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "difference: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {difference([1, 2, 3, 4, 5, 6, 7, 8])}
    "difference: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {difference()} "difference: Compare error detection, without parameters, ()";

    # Test - get empty arrays [],[]
    @list = difference([], []);
    eq_or_diff(\@list, [], 'difference: get empty arrays ([],[](');

    # Test - Get different items of same arrays ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([])
    @list = difference([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [], 'difference: Get different items of same arrays ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([])');

    # Test - Get different items of same arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])==([0,2,9])
    @list = difference([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8, 9]);
    eq_or_diff(\@list, [0, 2, 9], 'Get different items of same arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])==([0,2,9])');

    # Test - Check the behaviour of empty arrays, ([],[])==([])
    @list = difference([], []);
    eq_or_diff(\@list, [], 'difference: Check the behaviour of empty arrays, ([],[])==([])');

    # Test - Check the behaviour of equal arrays with undef, ([undef],[undef])==([])
    @list = difference([undef], [undef]);
    eq_or_diff(\@list, [], 'difference: Check the behaviour of equal arrays with undef, ([undef],[undef])==([])');

    # Test - Check the behaviour of equal arrays with undef, ([1,undef],[1,undef])==([])
    @list = difference([1, undef], [1, undef]);
    eq_or_diff(\@list, [], 'difference: Check the behaviour of equal arrays with undef, ([1,undef],[1,undef])==([])');

    # Test - Check the behaviour of different with undef, ([1,undef],[1])==([undef])
    @list = difference([1, undef], [1]);
    eq_or_diff(\@list, [undef], 'difference: Check the behaviour of different with undef, ([1,undef],[1])==([undef])');

    # examples
    # difference([1,2,3,4], [1,3,4,5])  == [2,5]
    @list = difference([1, 2, 3, 4], [1, 3, 4, 5]);
    eq_or_diff(\@list, [2, 5], 'example: difference([1,2,3,4],[1,3,4,5])==[2,5]');

    #
    #
    #
    return;
} ## end sub main
__END__
