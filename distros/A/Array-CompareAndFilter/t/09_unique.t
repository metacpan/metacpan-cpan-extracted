#!/usr/bin/perl
################################################################################
#
# File:     03_unique.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function unique.
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
use Test::More(tests => 18);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(unique);

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

    #*** unique ****************************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {unique('1', [1, 2, 3, 4, 5, 6, 7, 8])} "unique: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {unique([1, 2, 3, 4, 5, 6, 7, 8], '2')} "unique: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {unique([1, 2, 3, 4, 5, 6, 7, 8])} "unique: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {unique()} "unique: Compare error detection, without parameters, ()";

    # Test - get empty arrays [],[]
    @list = unique([], []);
    eq_or_diff(\@list, [], 'unique: get empty arrays ([],[](');

    # Test - Get unique items of array1, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==[]
    @list = unique([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [], 'unique: Get unique items of array1, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])==[]');

    # Test - Get unique items of array1, ([2,1,3,4,5,6,7,8],[0,1,3,4,5,6,7,8])==[2]
    @list = unique([2, 1, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [2], 'unique: Get unique items of array1, ([2,1,3,4,5,6,7,8],[0,1,3,4,5,6,7,8])==[2]');

    # Test - Get unique items of array1, ([2,1,3,4,5,6,7,8],[0,1,3,4,5,6,7,8,9])==[2]
    @list = unique([2, 1, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8, 9]);
    eq_or_diff(\@list, [2], 'unique: Get unique items of array1, ([2,1,3,4,5,6,7,8],[0,1,3,4,5,6,7,8,9])==[2]');

    # Test - Get unique items of array1, ([1,2,1,2,1,2],[2,1,2,1,2,1])==[]
    @list = unique([1, 2, 1, 2, 1, 2], [2, 1, 2, 1, 2, 1]);
    eq_or_diff(\@list, [], 'unique: Get unique items of array1, ([1,2,1,2,1,2],[2,1,2,1,2,1])==[]');

    # Test - Get unique items of array1, ([1,2,3,4,5,6,7,8],['a','b','c','d',2,1])==([3,4,5,6,7,8])
    @list = unique([1, 2, 3, 4, 5, 6, 7, 8], ['a', 'b', 'c', 'd', 2, 1]);
    eq_or_diff(
        \@list,
        [3, 4, 5, 6, 7, 8],
        "unique: Get unique items of array1, ([1,2,3,4,5,6,7,8],['a','b','c','d',2,1])==([3,4,5,6,7,8])"
    );

    # Test - Get unique items of array1, (['a','b','c','d',2,1],[1,2,3,4,5,6,7,8])==(['a','b','c','d'])
    @list = unique([qw(a b c d 2 1)], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        ['a', 'b', 'c', 'd'],
        "unique: aaa Get unique items of array1, (['a','b','c','d',2,1],[1,2,3,4,5,6,7,8])==(['a','b','c','d'])"
    );

    # Test - Check behaviour of empty array, ([], [1,2,3,4,5,6,7,8])==([])
    @list = unique([], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [], 'unique: Check behaviour of empty array, ([], [1,2,3,4,5,6,7,8])==([])');

    # Test - Check behaviour of array1 with undef, ([undef],[1,2,3,4,5,6,7,8])==([undef])
    @list = unique([undef], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [undef], 'unique: Check behaviour of array1 with undef, ([undef],[1,2,3,4,5,6,7,8])==([undef])');

    # Test - Check behaviour of array1 with undef, ([undef],[undef])==([])
    @list = unique([undef], [undef]);
    eq_or_diff(\@list, [], 'unique: Check behaviour of array1 with undef, ([undef],[undef])==([])');

    # Test - Check behaviour of array1 with undef, ([undef,0],[undef,1,2,3,4,5,6,7,8])==([0])
    @list = unique([undef, 0], [undef, 1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(\@list, [0], 'unique: Check behaviour of array1 with undef, ([undef,0],[undef,1,2,3,4,5,6,7,8])==([0])');

    # examples
    # unique([1,2,3], [2,1,4,3])==[]
    @list = unique([1, 2, 3], [2, 1, 4, 3]);
    eq_or_diff(\@list, [], 'example: unique([1,2,3], [2,1,4,3])==[]');

    # unique([1,2,3,4], [1,2,3,5])==[4]
    @list = unique([1, 2, 3, 4], [1, 2, 3, 5]);
    eq_or_diff(\@list, [4], 'example: unique([1,2,3,4], [1,2,3,5])==[4]');

    # unique([1,2,3,5], [1,2,3,4])==[5]
    @list = unique([1, 2, 3, 5], [1, 2, 3, 4]);
    eq_or_diff(\@list, [5], 'example: unique([1,2,3,5], [1,2,3,4])==[5]');

    #
    #
    #
    return;
} ## end sub main
__END__
