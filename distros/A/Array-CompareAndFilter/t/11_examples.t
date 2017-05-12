#!/usr/bin/perl
################################################################################
#
# File:     11_examples.t
# Date:     2012-07-27
# Author:   H. Klausing (h.klausing (at) gmx.de)
#
# Description:
#   Tests for Array::CompareAndFilter verification of the POD examples.
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
use Test::More(tests => 53);    # <-- put test numbers here
use Test::Differences qw(eq_or_diff);
use Array::CompareAndFilter qw(:all);

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

    #*** POD examples *********************************************************
    is(compareValue([1, 2, 3, 3], [1, 2, 3]), 1, "compareValue([1,2,3,3], [1,2,3]))");
    is(compareItem([1, 2, 3], [2, 3, 1]), 1, "compareItem([1,2,3], [2,3,1]))");
    is(compareOrder([1, 2, 3], [1, 2, 3]), 1, "compareOrder([1,2,3], [1,2,3])");
    @list = intersection([1, 2, 3], [2, 3, 4, 2]);
    eq_or_diff(\@list, [2, 3], "intersection([1,2,3], [2,3,4,2])");    # "The intersection items (\@inter) are 2 & 3.";
    @list = substractItem([3, 1, 2, 3], [2, 3]);
    eq_or_diff(\@list, [1, 3], "substractItem([3,1,2,3], [2,3])");    # "The substractItem items (\@subItem) are 1 & 3"
    @list = substractValue([3, 1, 2, 3], [2, 3]);
    eq_or_diff(\@list, [1], "substractValue([3,1,2,3], [2,3])");      # "The substractValue items (\@subValue) is 1";
    @list = difference([1, 2, 3, 4], [1, 3, 4, 5]);
    eq_or_diff(\@list, [2, 5], "difference([1,2,3,4], [1,3,4,5])");    # "The difference items (\@diff) are 2 & 5.";
    @list = unscramble([1, 2], [1, 4, 3]);
    eq_or_diff(\@list, [1, 2, 3, 4], "unscramble([1,2], [1,4,3])");    # "The unscramble items (\@unscramble) are 1,2,3 & 4.";
    @list = unique([1, 2, 3, 4, 6], [1, 2, 3, 5]);
    eq_or_diff(\@list, [4, 6], "unique([1,2,3,4,6], [1,2,3,5])");      # "The unique items (@unique) are 4 & 6.";
    @list = singularize([3, 2, 3, 4, 1]);
    eq_or_diff(\@list, [1, 2, 3, 4], "singularize([3,2,3,4,1])");    # "The singularize items (\@singularize) are 1, 2, 3 & 4."
    @list = singularize([3, 2, 3, 4, 1], 'b');
    eq_or_diff(\@list, [3, 2, 4, 1], "singularize([3,2,3,4,1],'b')")
      ;                                                              # "The singularize items (\@singularize) are 3, 2, 4 & 1.";
    @list = singularize([3, 2, 3, 4, 1], 'e');
    eq_or_diff(\@list, [2, 3, 4, 1], "singularize([3,2,3,4,1],'e')")
      ;                                                              # "The singularize items (\@singularize) are 2, 3, 4 & 1.";
    is(compareValue([1, 2, 3], [3, 2, 1]), 1, "compareValue([1,2,3], [3,2,1])");    # returns 1
    is(compareValue([1, 2, 3],     [3, 2, 1, 2, 3]), 1, "compareValue([1,2,3], [3,2,1,2,3])");        # returns 1
    is(compareValue([1, 2, undef], [3, 2, 1, 2, 3]), 0, "compareValue([1,2,undef], [3,2,1,2,3])");    # returns 0
    is(compareValue([1, 2, 4],     [3, 2, 1, 2, 3]), 0, "compareValue([1,2,4], [3,2,1,2,3])");        # returns 0
    is(compareItem([1, 2, 3],     [3,     2, 1]), 1, "compareItem([1,2,3], [3,2,1])");                # returns 1
    is(compareItem([1, 2, undef], [undef, 2, 1]), 1, "compareItem([1,2,undef], [undef,2,1])");        # returns 1
    is(compareItem([1, 2, 3], [3, 2, 1, 2, 3]), 0, "compareItem([1,2,3], [3,2,1,2,3])");              # returns 0
    is(compareItem([1, 2, 3], [4, 2, 1]), 0, "compareItem([1,2,3], [4,2,1])");                        # returns 0
    is(compareOrder([1, 2, 3], [1, 2, 3]), 1, "compareOrder([1,2,3], [1,2,3])");                      # returns 1
    is(compareOrder([undef], [undef]), 1, "compareOrder([undef], [undef])");                          # returns 1
    is(compareOrder([],      []),      1, "compareOrder([], [])");                                    # returns 1
    is(compareOrder([1, 2, 3], [1, 2, 3, 3]), 0, "compareOrder([1,2,3], [1,2,3,3])");                 # returns 0
    is(compareOrder([1, 2, 3], [1, 3, 2]), 0, "compareOrder([1,2,3], [1,3,2])");                      # returns 0
    @list = intersection([1, 2, 3], [1, 2, 3]);                                                       # returns (1,2,3)
    eq_or_diff(\@list, [1, 2, 3], "intersection([1,2,3], [1,2,3])");
    @list = intersection([undef], [undef]);                                                           # returns (undef)
    eq_or_diff(\@list, [undef], "intersection([undef], [undef])");
    @list = intersection([], []);                                                                     # returns ()
    eq_or_diff(\@list, [], "intersection([], [])");
    @list = intersection([1, 2], [2, 3]);                                                             # returns (2)
    eq_or_diff(\@list, [2], "intersection([1,2], [2,3])");
    @list = intersection([2,1,2], [3,1,2,2]);                                                             # returns (2)
    eq_or_diff(\@list, [1,2,2], "intersection([2,1,2], [3,1,2,2])");
    @list = substractItem([1, 2, 3, 4], [1, 2, 3]);                                                   # returns (4)
    eq_or_diff(\@list, [4], "substractItem([1,2,3,4], [1,2,3])");
    @list = substractItem([undef], [undef]);                                                          # returns ()
    eq_or_diff(\@list, [], "substractItem([undef], [undef])");
    @list = substractItem([1, 2], [3]);                                                               # returns (1,2)
    eq_or_diff(\@list, [1, 2], "substractItem([1,2], [3])");
    @list = substractItem([1, 3, 2, 2], [2, 1, 2]);                                                   # returns (3)
    eq_or_diff(\@list, [3], "substractItem([1,3,2,2], [2,1,2])");
    @list = substractValue([1, 2, 3, 2, 1], [1, 2]);                                                  # returns (3)
    eq_or_diff(\@list, [3], "substractValue([1,2,3,2,1], [1,2])");
    @list = substractValue([undef, undef], [undef]);                                                  # returns ()
    eq_or_diff(\@list, [], "substractValue([undef,undef], [undef])");
    @list = substractValue([], [1, 2]);                                                               # returns ()
    eq_or_diff(\@list, [], "substractValue([], [1,2])");
    @list = substractValue([1, 2], [1, 3]);                                                           # returns (2)
    eq_or_diff(\@list, [2], "substractValue([1,2], [1,3])");
    @list = difference([1, 2, 3, 4], [1, 3, 4, 5]);                                                   # returns (2,5)
    eq_or_diff(\@list, [2, 5], "difference([1,2,3,4], [1,3,4,5])");
    @list = difference([1], [2]);                                                                     # returns (1,2)
    eq_or_diff(\@list, [1, 2], "difference([1], [2])");
    @list = difference([undef, 1], [2, 3, 1]);                                                        # returns (2,3,undef)
    eq_or_diff(\@list, [2, 3, undef], "difference([undef,1], [2,3,1])");
    @list = difference([2, 1], [3, 1, 2]);                                                            # returns (3)
    eq_or_diff(\@list, [3], "difference([2,1], [3,1,2])");
    @list = unscramble([1, 2], [1, 4, 3]);                                                            # returns (1,2,3,4)
    eq_or_diff(\@list, [1, 2, 3, 4], "unscramble([1,2], [1,4,3])");
    @list = unscramble([1, 1], [2, 3, 3, 1]);                                                         # returns (1,2,3)
    eq_or_diff(\@list, [1, 2, 3], "unscramble([1,1], [2,3,3,1])");
    @list = unscramble([1, 1], []);                                                                   # returns (1)
    eq_or_diff(\@list, [1], "unscramble([1,1], [])");
    @list = unique([1, 2, 3], [2, 1, 4, 3]);                                                          # returns ()
    eq_or_diff(\@list, [], "unique([1,2,3], [2,1,4,3])");
    @list = unique([1, 2, 3, 4], [1, 2, 3, 5]);                                                       # returns (4)
    eq_or_diff(\@list, [4], "unique([1,2,3,4], [1,2,3,5])");
    @list = unique([1, 2, 3, 5], [2, 3, 4]);                                                          # returns (1,5)
    eq_or_diff(\@list, [1, 5], "unique([1,2,3,5], [2,3,4])");
    @list = singularize([qw(d b d b c a)]);                                                           # returns (qw(a b c d))
    eq_or_diff(\@list, [qw(a b c d)], "singularize([qw(d b d b c a)])");
    @list = singularize([3, 2, 3, 4, 1]);                                                             # returns (1,2,3,4)
    eq_or_diff(\@list, [1, 2, 3, 4], "singularize([3,2,3,4,1])");
    @list = singularize([3, 2, 3, 4, 1], 's');                                                        # returns (1,2,3,4)
    eq_or_diff(\@list, [1, 2, 3, 4], "singularize([3,2,3,4,1])");
    @list = singularize([3, 2, 3, 4, 1], 'b');                                                        # returns (3,2,4,1)
    eq_or_diff(\@list, [3, 2, 4, 1], "singularize([3,2,3,4,1])");
    @list = singularize([3, 2, 3, 4, 1], 'e');                                                        # returns (2,3,4,1)
    eq_or_diff(\@list, [2, 3, 4, 1], "singularize([3,2,3,4,1])");

    #
    #
    #
    return;
} ## end sub main
__END__
