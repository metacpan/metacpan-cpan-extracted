#!/usr/bin/perl
################################################################################
#
# File:     01_compareValue.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter function compareValue.
#
################################################################################
#
# Updates:
# 2012-09-01 H. Klausing
#       Version number removed.
# 2012-08-12 v 1.0.2   H. Klausing
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
use Test::More(tests => 20);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Test::Exception;
use Array::CompareAndFilter qw(compareValue);

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

    #*** compareValue **********************************************************
    # Compare error detection, parameter 1
    dies_ok {compareValue('1', [1, 2, 3, 4, 5, 6, 7, 8])}
    'compareValue: Compare error detection, parameter 1, (1,[1,2,3,4,5,6,7,8])';

    # Compare error detection, parameter 2
    dies_ok {compareValue([1, 2, 3, 4, 5, 6, 7, 8], '2')}
    'compareValue: Compare error detection, parameter 2, ([1,2,3,4,5,6,7,8],1)';

    # Test - Compare error detection, without parameter 2
    dies_ok {compareValue([1, 2, 3, 4, 5, 6, 7, 8])}
    "compareValue: Compare error detection, without parameter 2, ([1,2,3,4,5,6,7,8])";

    # Test - Compare error detection, without parameters
    dies_ok {compareValue()} "compareValue: Compare error detection, without parameters, ()";

    # Compare empty arrays
    is(compareValue([], []), 1, 'compareValue: Compare empty arrays ([], [])');

    # Compare empty array against full array ([], [1,2,3,4,5])==0
    is(compareValue([], [1, 2, 3, 4, 5]), 0, 'compareValue: Compare empty array against full array ([], [1,2,3,4,5])==0');

    # Compare empty array against full array ([1,2,3,4,5],[])==0
    is(compareValue([1, 2, 3, 4, 5], []), 0, 'compareValue: Compare empty array against full array ([1,2,3,4,5],[])==0');

    # Compare array against different array ([1,2,3,4,5],[6,7,8,9])==0
    is(compareValue([1, 2, 3, 4, 5], [6, 7, 8, 9]),
        0, 'compareValue: Compare array against different array ([1,2,3,4,5],[6,7,8,9])==0');

    # Compare array against different array ([6,7,8,9],[1,2,3,4,5])==0
    is(compareValue([6, 7, 8, 9], [1, 2, 3, 4, 5]),
        0, 'compareValue: Compare array against different array ([6,7,8,9],[1,2,3,4,5])==0');

    # Compare arrays with 1 difference ([1,2,3,4],[1,2,3,4,5])==0
    is(compareValue([1, 2, 3, 4], [1, 2, 3, 4, 5]),
        0, 'compareValue: Compare arrays with 1 difference ([1,2,3,4],[1,2,3,4,5])==0');

    # Compare arrays with 1 difference ([1,2,3,4,5],[1,2,3,4])==0
    is(compareValue([1, 2, 3, 4, 5], [1, 2, 3, 4]),
        0, 'compareValue: Compare arrays with 1 difference ([1,2,3,4,5],[1,2,3,4])==0');

    # Compare two equal arrays ([1,2,3,4,5],[1,2,3,4,5])==1
    is(compareValue([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]), 1,
        'compareValue: Compare two equal arrays ([1,2,3,4,5],[1,2,3,4,5])==1');

    # Compare two equal arrays with multiple items ([1,1,1,2,2],[1,1,1,2,2])==1
    is(compareValue([1, 1, 1, 2, 2], [1, 1, 1, 2, 2]), 1,
        'compareValue: Compare two equal arrays ([1,1,1,2,2],[1,1,1,2,2])==1');

    # Compare two equal arrays with multiple items different order ([1,1,1,2,2],[1,2,1,2,1])==1
    is(compareValue([1, 1, 1, 2, 2], [1, 2, 1, 2, 1]),
        1, 'compareValue: Compare two equal arrays with multiple items different order ([1,1,1,2,2],[1,2,1,2,1])==1');

    # Compare two equal arrays with multiple items different order and size ([1,2],[1,2,1,2,1])==1
    is(compareValue([1, 2], [1, 2, 1, 2, 1]),
        1, 'compareValue: Compare two equal arrays with multiple items different order and size ([1,2],[1,2,1,2,1])==1');

    # Compare two equal arrays with multiple items different order and size ([1,2,1,2,1],[1,2])==1
    is(compareValue([1, 2, 1, 2, 1], [1, 2]),
        1, 'compareValue: Compare two equal arrays with multiple items different order and size ([1,2,1,2,1],[1,2])==1');

    # Compare array with 1 item against array with multiple items ([1],[1,1,1,1,1,1,1])==1
    is(compareValue([1], [1, 1, 1, 1, 1, 1, 1]),
        1, 'compareValue: Compare array with 1 item against array with multiple items ([1],[1,1,1,1,1,1,1])==1');

    # Compare array with 1 item against array with multiple items ([undef,undef],[undef])==1
    is(compareValue([undef, undef], [undef]),
        1, 'compareValue: Compare array with 1 item against array with multiple items ([undef,undef],[undef])==1');

    # examples
    # compareValue([1,2,3,3], [1,2,3])==1
    is(compareValue([1, 2, 3, 3], [1, 2, 3]), 1, 'example: compareValue([1,2,3,3], [1,2,3])==1');

    # examples
    # compareValue([1,2,3], [1,2,3,3])==1
    is(compareValue([1, 2, 3], [1, 2, 3, 3]), 1, 'example: compareValue([1,2,3], [1,2,3,3])==1');

    #
    #
    #
    return;
} ## end sub main
__END__
