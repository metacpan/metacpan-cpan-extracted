#!/usr/bin/perl
################################################################################
#
# File:     10_singularize.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function singular.
#
################################################################################
#
# Updates:
# 2014-09-21 v 1.100   H. Klausing
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
use Test::More(tests => 9);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(singular);

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

    #*** singular ***********************************************************
    # Test - Compare error detection, parameter is not array
    dies_ok {singular('1')} 'singular: Compare error detection, parameter is not array';

    # Test - Get singular items of array, ([1,2,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])
    @list = singular([1, 2, 3, 4, 5, 6, 7, 8]);
    eq_or_diff(
        \@list,
        [1, 2, 3, 4, 5, 6, 7, 8],
        'singular: Get singular items of array, ([1,2,3,4,5,6,7,8])==([1,2,3,4,5,6,7,8])'
    );

    # Test - Compare error detection, without parameter 1
    dies_ok {singular()} "singular: Compare error detection, without parameter 1, ()";

    # Test - Get singular items with empty array for default, ([])==([])
    @list = singular([]);
    eq_or_diff(\@list, [], 'singular: Get singular items with empty array for default, ([])==([])');

    # Test - Get singular items of array with repeated items, ([1,2,1,2,1,2])==([1,2])
    @list = singular([1, 2, 1, 2, 1, 2]);
    eq_or_diff(\@list, [1, 2], 'singular: Get singular items of array with repeated items, ([1,2,1,2,1,2])==([1,2])');

    # Test - Get singular items of array with undef, with order check, ([undef])=>die
    @list = singular([undef]);
    eq_or_diff(\@list, [undef], 'example: singular([undef])==[undef]');

    # Test - Get singular items of array with undefk, ([1,2,undef,1])=>die
    @list = singular([1, 2, undef,1]);
    eq_or_diff(\@list, [1, 2, undef], 'singular: Get singular items of array with undefk, ([1,2,undef,1])=>([1, 2, undef])');

    # example
    # singular([1,2,3,4,5])==[1,2,3,4,5]
    @list = singular([1, 2, 3, 4, 5]);
    eq_or_diff(\@list, [1, 2, 3, 4, 5], 'example: singular([1,2,3,4,5])==[1,2,3,4,5]');

    # singular([2,1,1,1,1])==[2,1]
    @list = singular([2, 1, 1, 1, 1]);
    eq_or_diff(\@list, [2, 1], 'example: singular([2,1,1,1,1])==[2,1]');

    #
    #
    #
    return;
} ## end sub main
__END__
