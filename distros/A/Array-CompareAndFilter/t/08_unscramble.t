#!/usr/bin/perl
################################################################################
#
# File:     08_unscramble.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function unscramble.
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
use Test::More(tests => 14);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(unscramble);

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

    #*** unscramble ************************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {unscramble('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "unscramble: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {unscramble([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "unscramble: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {unscramble([1, 2, 3, 4, 5, 6, 7, 8])}
    "unscramble: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {unscramble()} "unscramble: Compare error detection, without parameters, ()";

    # Test - get empty arrays [],[]
    @list = unscramble([], []);
    eq_or_diff(\@list, [], 'unscramble: get empty arrays ([],[](');

    # Test - Get equal items of same arrays, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])
    @list = unscramble([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'unscramble: Get equal items of same arrays, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])'
    );

# Test - Get equal items of arrays with same content and different order, ([1,2,3,4,5,6,7,8],[2,1,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])
    @list = unscramble([1, 2, 3, 4, 5, 6, 7, 8], [2, 1, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'unscramble: Get equal items of arrays with same content and different order, ([1,2,3,4,5,6,7,8],[2,1,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Get equal items of different arrays, ([1,2,3,4,5,6,7,8],[0,1,3,4,5,6,7,8])==([0,1,2,3,4,5,6,7,8])
    @list = unscramble([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [0, 1, 2, 3, 4, 5, 6, 7, 8],
        'unscramble: Get equal items of different arrays, ([1,2,3,4,5,6,7,8],[0,1,3,4,5,6,7,8])==([0,1,2,3,4,5,6,7,8])'
    );

# Test - Get equal items of different arrays with different size, ([1,2,3,4,5,6,7,8],[0,1,3,4,5,6,7,8,9])==([0,1,2,3,4,5,6,7,8,9])
    @list = unscramble([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8, 9]);
    eq_or_diff(
        \@list,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        'unscramble: Get equal items of different arrays with different size, ([1,2,3,4,5,6,7,8],[0,1,3,4,5,6,7,8,9])==([0,1,2,3,4,5,6,7,8,9])'
    );

    # Test - Get items of different arrays, ([4,3,2,1],[9,8,7,6])==([1,2,3,4,6,7,8,9])
    @list = unscramble([4, 3, 2, 1], [9, 8, 7, 6]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 6, 7, 8, 9],
        'unscramble: Get items of different arrays, ([4,3,2,1],[9,8,7,6])==([1,2,3,4,6,7,8,9])'
    );

    # Test - Get items of arrays with undef, ([undef],[undef])==([undef])
    @list = unscramble([undef], [undef]);
    eq_or_diff(\@list, [undef], 'unscramble: Get items of arrays with undef, ([undef],[undef])==([undef])');

    # Test - Get items of arrays with undef, ([undef,1],[undef,undef])==([1,undef])
    @list = unscramble([undef, 1], [undef, undef]);
    eq_or_diff(\@list, [1, undef], 'unscramble: Get items of arrays with undef, ([undef,1],[undef,undef])==([1,undef])');

    # Test - Check behaviour of empty array, ([],[])==([])
    @list = unscramble([], []);
    eq_or_diff(\@list, [], 'unscramble: Check behaviour of empty array, ([],[])==([])');

    # examples
    # union([1,2], [1,4,3])  == [1,2,3,4]
    @list = unscramble([1, 2], [1, 4, 3]);
    eq_or_diff(\@list, [1, 2, 3, 4], 'example: unscramble([1,2], [1,4,3])  == [1,2,3,4]');

    #
    #
    #
    return;
} ## end sub main
__END__
