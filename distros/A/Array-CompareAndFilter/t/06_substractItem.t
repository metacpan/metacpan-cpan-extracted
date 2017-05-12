#!/usr/bin/perl
################################################################################
#
# File:     06_substractItem.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function substractItem.
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
use Test::More(tests => 11);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(substractItem);

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

    #*** substractItem *********************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {substractItem('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "substractItem: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {substractItem([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "substractItem: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {substractItem([1, 2, 3, 4, 5, 6, 7, 8])}
    "substractItem: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {substractItem()} "substractItem: Compare error detection, without parameters, ()";

    # Test - get empty arrays [],[]
    @list = substractItem([], []);
    eq_or_diff(\@list, [], 'substractItem: get empty arrays ([],[](');

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([])
    @list = substractItem([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [], 'substractItem: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([])');

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[2,3,4,5,6,7,8])==([1])
    @list = substractItem([1, 2, 3, 4, 5, 6, 7, 8], [2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [1], 'substractItem: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[2,3,4,5,6,7,8])==([1])');

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])
    @list = substractItem([1, 2, 3, 4, 5, 6, 7, 8], []);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'substractItem: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])
    @list = substractItem([1, 2, 3, 4, 5, 6, 7, 8], []);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'substractItem: Remove items ARY1 from ARY2, ([1,2,3,4,5,6,7,8],[])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Remove items ARY1 from ARY2, ([1,2,2,1],[1,2])==([2,1])
    @list = substractItem([1, 2, 2, 1], [1, 2]);
    eq_or_diff(\@list, [2, 1], 'substractItem: Remove items ARY1 from ARY2, ([1,2,2,1],[1,2])==([2,1])');

    # Test - Remove items ARY1 from ARY2, ([1,2,2,1],[1,2])==([2,1])
    @list = substractItem([undef], [undef]);
    eq_or_diff(\@list, [], 'substractItem: Remove items ARY1 from ARY2, ([1,2,2,1],[1,2])==([2,1])');

    #
    #
    #
    return;
} ## end sub main
__END__
