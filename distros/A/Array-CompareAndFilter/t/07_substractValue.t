#!/usr/bin/perl
################################################################################
#
# File:     07_substractValue.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function substractValue.
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
use Test::More(tests => 15);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(substractValue);

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

    #*** substractValue ********************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {substractValue('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "substractValue: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {substractValue([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "substractValue: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {substractValue([1, 2, 3, 4, 5, 6, 7, 8])}
    "substractValue: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {substractValue()} "substractValue: Compare error detection, without parameters, ()";

    # Test - get empty arrays [],[]
    @list = substractValue([], []);
    eq_or_diff(\@list, [], 'substractValue: get empty arrays ([],[](');

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([])
    @list = substractValue([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [], 'substractValue: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([])');

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[2,3,4,5,6,7,8])==([1])
    @list = substractValue([1, 2, 3, 4, 5, 6, 7, 8], [2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [1], 'substractValue: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[2,3,4,5,6,7,8])==([1])');

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])
    @list = substractValue([1, 2, 3, 4, 5, 6, 7, 8], []);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'substractValue: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])
    @list = substractValue([1, 2, 3, 4, 5, 6, 7, 8], []);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'substractValue: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Remove items ARY1 from ARY2, ([1,2,2,1],[1,2])==([])
    @list = substractValue([1, 2, 2, 1], [1, 2]);
    eq_or_diff(\@list, [], 'substractValue: Remove items ARY1 from ARY2, ([1,2,2,1],[1,2])==([])');

    # Test - Get items ARY1 from ARY2, ([1,3,2,4,2,1],[1,2])==([3,4])
    @list = substractValue([1, 3, 2, 4, 2, 1], [1, 2]);
    eq_or_diff(\@list, [3, 4], 'substractValue: Get items ARY1 from ARY2, ([1,3,2,4,2,1],[1,2])==([3,4])');

    # Test - Get items ARY1 from ARY2, ([1,3,2,4,2,1],[2,1])==([3,4])
    @list = substractValue([1, 3, 2, 4, 2, 1], [2, 1]);
    eq_or_diff(\@list, [3, 4], 'substractValue: Get items ARY1 from ARY2, ([1,3,2,4,2,1],[2,1])==([3,4])');

    # Test - Get items ARY1 from ARY2, ([undef],[1])==([undef])
    @list = substractValue([undef], [1]);
    eq_or_diff(\@list, [undef], 'substractValue: Get items ARY1 from ARY2, ([undef],[1])==([undef])');

    # Test - Get items ARY1 from ARY2, ([2,undef],[1])==([2,undef])
    @list = substractValue([2, undef], [1]);
    eq_or_diff(\@list, [2, undef], 'substractValue: Get items ARY1 from ARY2, ([2,undef],[1])==([2,undef])');

    # Test - Get items ARY1 from ARY2, ([undef],[undef])==([])
    @list = substractValue([undef], [undef]);
    eq_or_diff(\@list, [], 'substractValue: Get items ARY1 from ARY2, ([undef],[undef])==([])');

    #
    #
    #
    return;
} ## end sub main
__END__
