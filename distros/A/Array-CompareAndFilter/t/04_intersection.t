#!/usr/bin/perl
################################################################################
#
# File:     04_intersection.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function intersection.
#
################################################################################
#
# Updates:
# 2012-09-01 H. Klausing
#       Tests added with multiple equal elements
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
use Test::More(tests => 19);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use lib '../lib';
use Array::CompareAndFilter qw(intersection);

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

    #*** intersection **********************************************************
    # Test - Compare error detection, parameter 1
    dies_ok {intersection('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    "intersection: Compare error detection, parameter 1, ('1',[1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, parameter 2
    dies_ok {intersection([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    "intersection: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],'2')";

    # Test - Compare error detection, without parameter 2
    dies_ok {intersection([1, 2, 3, 4, 5, 6, 7, 8])}
    "intersection: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {intersection()} "intersection: Compare error detection, without parameters, ()";

    # Test - get empty arrays [],[]
    @list = intersection([], []);
    eq_or_diff(\@list, [], 'intersection: get empty arrays ([],[](');

    # Test - get equal items of equal arrays (1,2)/(1,2)
    @list = intersection([1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'intersection: get equal items of equal arrays, ([1,2,3,4,5,6,7,8],[1,2,3,4,5,6,7,8])'
    );

    # Test - get equal items of arrays with same content, ([1,2,3,4,5,6,7,8], [2,1,3,4,5,6,7,8])
    @list = intersection([1, 2, 3, 4, 5, 6, 7, 8], [2, 1, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'intersection: get equal items of arrays with same content, ([1,2,3,4,5,6,7,8],[2,1,3,4,5,6,7,8])'
    );

    # Test - get equal items of different arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8])
    @list = intersection([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 3, 4, 5, 6, 7, 8],
        'intersection: get equal items of different arrays, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8])'
    );

    # Test - get equal items of different arrays with different size, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])
    @list = intersection([1, 2, 3, 4, 5, 6, 7, 8], [0, 1, 3, 4, 5, 6, 7, 8, 9]);
    eq_or_diff(
        \@list,
        [1, 3, 4, 5, 6, 7, 8],
        'intersection: get equal items of different arrays with different size, ([1,2,3,4,5,6,7,8], [0,1,3,4,5,6,7,8,9])'
    );

    # Test - get equal items of equal arrays with different size, ([1,1,1], [1,1,1,1,1])
    @list = intersection([1,1,1], [1,1,1,1,1]);
    eq_or_diff(\@list, [1,1,1], 'intersection: get equal items of different arrays with different size, ([1,1,1], [1,1,1,1,1])');

    # Test - get equal items of different arrays with different size, ([undef,undef,undef,undef,undef], [undef,undef,undef])
    @list = intersection([undef,undef,undef,undef,undef], [undef,undef,undef]);
    eq_or_diff(\@list, [undef,undef,undef], 'intersection: get equal items of different arrays with different size, ([undef,undef,undef,undef,undef], [undef,undef,undef])');

    # Test - zero equal item handling empty and equal arrays, ([1,1,1], [])
    @list = intersection([1,1,1], []);
    eq_or_diff(\@list, [], 'intersection: zero equal item handling empty and equal arrays, ([1,1,1], [])');

    # Test - get equal items of different arrays with different size, ([1,2,3], [1,2,3,4,4])
    @list = intersection([1,2,3], [1,2,3,4,4]);
    eq_or_diff(\@list, [1, 2, 3], 'intersection: get equal items of different arrays with different size, ([1,2,3], [1,2,3,4,4])');

    # Test - get equal items of different arrays with different size, ([1,2,3,4,4], [1,2,3])
    @list = intersection([1,2,3,4,4], [1,2,3]);
    eq_or_diff(\@list, [1, 2, 3], 'intersection: get equal items of different arrays with different size, ([1,2,3,4,4], [1,2,3])');

    # Test - check behaviour of empty arrays, ([], [])
    @list = intersection([], []);
    eq_or_diff(\@list, [], 'intersection: check behaviour of empty arrays, ([], [])');

    # Test - check behaviour of arrays with undef, ([undef], [undef])
    @list = intersection([undef], [undef]);
    eq_or_diff(\@list, [undef], 'intersection: check behaviour of arrays with undef, ([undef], [undef])');

    # Test - check behaviour of arrays with undef, ([undef,1], [2,undef])
    @list = intersection([undef, 1], [2, undef]);
    eq_or_diff(\@list, [undef], 'intersection: check behaviour of arrays with undef, ([undef,1], [2,undef])');

    # examples
    # intersection([1,2,5,4], [2,1,4,3])  ==> (1,2,4)
    @list = intersection([1, 2, 5, 4], [2, 1, 4, 3]);
    eq_or_diff(\@list, [1, 2, 4], 'example: intersection([1,2,5,4], [2,1,4,3])  ==> (1,2,4)');

    # intersection([1,2,4,3,4], [2,1,3])  ==> (1,2,3)
    @list = intersection([1,2,4,3,4], [2,1,3]);
    eq_or_diff(\@list, [1, 2, 3], 'example: intersection([1,2,4,3,4], [2,1,3])  ==> (1,2,3)');

    #
    #
    #
    return;
} ## end sub main
__END__
