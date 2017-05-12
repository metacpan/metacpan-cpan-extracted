#!/usr/bin/perl
################################################################################
#
# File:     10_singularize.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function singularize.
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
#       parameter 2 type test added
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
use Test::More(tests => 32);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(singularize);

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

    #*** singularize ***********************************************************
    # Test - Compare error detection, parameter 1, (1)
    dies_ok {singularize('1')} 'singularize: Compare error detection, parameter 1, (1)';

    # Test - Get singular items of array, ([1,2,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])
    @list = singularize([1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'singularize: Get singular items of array, ([1,2,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Compare error detection, without parameter 1
    dies_ok {singularize()} "singularize: Compare error detection, without parameter 1, ()";

    # Test - Get singular items of array, with order check, ([2,1,3,4,5,6,7,8])==[1,2,3,4,5,6,7,8]
    @list = singularize([2, 1, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'singularize: Get singular items of array, with order check, ([2,1,3,4,5,6,7,8])==[1,2,3,4,5,6,7,8]'
    );

    # Test - Get singular items with empty array for default, ([])==([])
    @list = singularize([]);
    eq_or_diff(\@list, [], 'singularize: Get singular items with empty array for default, ([])==([])');

    # Test - Compare error detection, if parameter 2 is an array
    dies_ok {singularize([],[])} "singularize: Compare error detection, if parameter 2 is an array";

    # Test - Get singular items with empty array for sort, ([],'s')==([])
    @list = singularize([], 's');
    eq_or_diff(\@list, [], "singularize: Get singular items with empty array for sort, ([],'s')==([])");

    # Test - Get singular items with empty array for begin, ([],'b')==([])
    @list = singularize([], 'b');
    eq_or_diff(\@list, [], "singularize: Get singular items with empty array for begin, ([],'b')==([])");

    # Test - Get singular items with empty array for end, ([],'e')==([])
    @list = singularize([], 'e');
    eq_or_diff(\@list, [], "singularize: Get singular items with empty array for end, ([],'e')==([])");

    # Test - Get singular items of array with repeated items, ([1,2,1,2,1,2])==([1,2])
    @list = singularize([1, 2, 1, 2, 1, 2]);
    eq_or_diff(\@list, [1, 2], 'singularize: Get singular items of array with repeated items, ([1,2,1,2,1,2])==([1,2])');

    # Test - Get singular items of array with repeated items, with order check, ([2,1,2,1,2,1])==[1,2]
    @list = singularize([2, 1, 2, 1, 2, 1]);
    eq_or_diff(\@list, [1, 2],
        'singularize: Get singular items of array with repeated items, with order check, ([2,1,2,1,2,1])==[1,2]');

    # Test - Get singular items of array with repeated items, ([1,2,1,2,1,2],'bad')==([1,2])
    @list = singularize([1, 2, 1, 2, 1, 2], 'bad');
    eq_or_diff(\@list, [1, 2], "singularize: Get singular items of array with repeated items, ([1,2,1,2,1,2],'bad')==([1,2])");

    # Test - Get singular items of array with repeated items, with order check, ([2,1,2,1,2,1],'bad')==[1,2]
    @list = singularize([2, 1, 2, 1, 2, 1], 'bad');
    eq_or_diff(\@list, [1, 2],
        "singularize: Get singular items of array with repeated items, with order check, ([2,1,2,1,2,1],'bad')==[1,2]");

    # Test - Get singular items of array with undef, with order check, ([undef])==[undef]
    @list = singularize([undef]);
    eq_or_diff(\@list, [undef], 'singularize: Get singular items of array with undef, with order check, ([undef])==[undef]');

    # Test - Get singular items of array with undef, with order check, ([undef,undef])==[undef]
    @list = singularize([undef, undef]);
    eq_or_diff(\@list, [undef],
        'singularize: Get singular items of array with undef, with order check, ([undef,undef])==[undef]');

    # Test - Get singular items of array with undef, with order check, ([undef,undef,1])==[undef,1]
    @list = singularize([undef, undef, 1]);
    eq_or_diff(
        \@list,
        [1, undef],
        'singularize: Get singular items of array with undef, with order check, ([undef,undef,1])==[1,undef]'
    );

    # Test - Get singular items of array with repeated items, begin, ([1,2,1,2,1,2])==([1,2])
    @list = singularize([1, 2, 1, 2, 1, 2], 'b');
    eq_or_diff(\@list, [1, 2],
        "singularize: Get singular items of array with repeated items, begin, ([1,2,1,2,1,2],'b')==([1,2])");

    # Test - Get singular items of array with repeated items, with order check, begin, ([2,1,2,1,2,1],'b')==[2,1]
    @list = singularize([2, 1, 2, 1, 2, 1], 'b');
    eq_or_diff(\@list, [2, 1],
        "singularize: Get singular items of array with repeated items, with order check, begin, ([2,1,2,1,2,1],'b')==[2,1]");

    # Test - Get singular items of array with undef, with order check, begin ([undef])==[undef]
    @list = singularize([undef], 'b');
    eq_or_diff(\@list, [undef],
        "singularize: Get singular items of array with undef, with order check, begin, ([undef],'b')==[undef]");

    # Test - Get singular items of array with undef, with order check, begin, ([undef,undef])==[undef]
    @list = singularize([undef, undef], 'b');
    eq_or_diff(\@list, [undef],
        "singularize: Get singular items of array with undef, with order check, begin, ([undef,undef],'b')==[undef]");

    # Test - Get singular items of array with undef, with order check, begin, ([undef,undef,1])==[undef,1]
    @list = singularize([undef, undef, 1], 'b');
    eq_or_diff(
        \@list,
        [undef, 1],
        "singularize: Get singular items of array with undef, with order check, begin, ([undef,undef,1],'b')==[undef,1]"
    );

    # Test - Get singular items of array with repeated items, end, ([1,2,1,2,1,2])==([1,2])
    @list = singularize([1, 2, 1, 2, 1, 2], 'e');
    eq_or_diff(\@list, [1, 2], "singularize: Get singular items of array with repeated items, end, ([1,2,1,2,1,2])==([1,2])");

    # Test - Get singular items of array with repeated items, with order check, end, ([2,1,2,1,2,1])==[2,1]
    @list = singularize([2, 1, 2, 1, 2, 1], 'e');
    eq_or_diff(\@list, [2, 1],
        "singularize: Get singular items of array with repeated items, with order check, end, ([2,1,2,1,2,1])==[2,1]");

    # Test - Get singular items of array with undef, with order check, end ([undef])==[undef]
    @list = singularize([undef], 'e');
    eq_or_diff(\@list, [undef],
        "singularize: Get singular items of array with undef, with order check, end, ([undef],'b')==[undef]");

    # Test - Get singular items of array with undef, with order check, end, ([undef,undef])==[undef]
    @list = singularize([undef, undef], 'e');
    eq_or_diff(\@list, [undef],
        "singularize: Get singular items of array with undef, with order check, end, ([undef,undef],'e')==[undef]");

    # Test - Get singular items of array with undef, with order check, end, ([undef,undef,1])==[undef,1]
    @list = singularize([undef, undef, 1], 'e');
    eq_or_diff(
        \@list,
        [undef, 1],
        "singularize: Get singular items of array with undef, with order check, end, ([undef,undef,1],'e')==[undef,1]"
    );

    # Test - Check behaviour of empty array, ([])==([])
    @list = singularize([]);
    eq_or_diff(\@list, [], 'singularize: Check behaviour of empty array, ([])==([])');

    # example
    # singularize([1,2,3,4,5])==[1,2,3,4,5]
    @list = singularize([1, 2, 3, 4, 5]);
    eq_or_diff(\@list, [1, 2, 3, 4, 5], 'example: singularize([1,2,3,4,5])==[1,2,3,4,5]');

    # singularize([1,1,1,1,2])==[1,2]
    @list = singularize([1, 1, 1, 1, 2]);
    eq_or_diff(\@list, [1, 2], 'example: singularize([1,1,1,1,2])==[1,2]');

    # singularize([2,2,3,1,2],'s')==[1,2,3]
    @list = singularize([2, 2, 3, 1, 2], 's');
    eq_or_diff(\@list, [1, 2, 3], "example: singularize([2,2,3,1,2],'s')==[1,2,3]");

    # singularize([2,2,3,1,2],'b')==[2,3,1]
    @list = singularize([2, 2, 3, 1, 2], 'b');
    eq_or_diff(\@list, [2, 3, 1], "example: singularize([2,2,3,1,2],'b')==[2,3,1]");

    # singularize([2,2,3,1,2],'e')==[3,1,2]
    @list = singularize([2, 2, 3, 1, 2], 'e');
    eq_or_diff(\@list, [3, 1, 2], "example: singularize([2,2,3,1,2],'e')==[3,1,2]");

    #
    #
    #
    return;
} ## end sub main
__END__
