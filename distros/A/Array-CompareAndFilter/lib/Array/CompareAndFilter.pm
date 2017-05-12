#!/usr/bin/perl
################################################################################
#
# File:     CompareAndFilter.pm
# Date:     2012-06-25
# Author:   H. Klausing (h.klausing (at) gmx.de)
# Version:  v1.100
#
# Description:
#   Compares and filters contents of arrays.
#
#
# Options:
#
# Tidy:     -l=128 -pt=2 -sbt=2 -bt=2 -bbt=2 -csc -csci=28 -bbc -bbb -lbl=1 -sob -bar -nsfs -nolq
#
################################################################################
#
# Updates:
# 2014-09-14 v1.100   H. Klausing
#       - version handling improved, version format changed.
#       - reason for perl 5.18 message 'Smartmatch is experimental at ...' removed.
# 2012-09-01 v1.0.3   H. Klausing
#       subroutine intersection corrected - multiple lists elements were handled
#       correctly now.
#       version number incremented
# 2012-08-12 v1.0.2   H. Klausing
#       version number incremented
# 2012-08-05 v1.0.1   H. Klausing
#       Test scripts modifed, external modules eleminated.
#       compareOrder() modified, it's using ~~ smart-match operator.
#       Documentation updated.
# 2012-06-25 v1.0.0   H. Klausing
#       Initial script version
#
################################################################################
#
use v5.010;    # loads all features available in perl 5.10 (no real requirement)
our $VERSION = 'v1.100';    # Version number

#--- ToDo list -----------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#
#
#
#--- module name ------------------------
package Array::CompareAndFilter;
require Exporter;
#
#
#
#--- process requirements ---------------
use strict;
use warnings;
#
#
#
#--- global variables -------------------
use constant UNDEF => '?undef?';
#
#
#
#--- Interface to caller ----------------
our @ISA       = qw(Exporter);
our @EXPORT    = qw();           # standard export
our @EXPORT_OK = qw(
    compareValue compareItem compareOrder
    intersection difference substractItem substractValue
    unscramble
    unique singularize singular);    # export if required
our %EXPORT_TAGS = (                 # Export as group
    all => [
        qw(compareValue compareItem compareOrder intersection difference substractItem substractValue unscramble unique singularize singular)
    ],
    compare   => [qw(compareValue compareItem compareOrder)],
    substract => [qw(substractItem substractValue)],
);
#
#
#
#--- used modules -----------------------
#
#
#
#-------------------------------------------------------------------------------
# compareValue   matches the contents of two arrays. The result is true
# if all values from ARRAY1 are found in ARRAY2. The amount of found
# items is ignored for this test. Value is defined as a data value of
# an item.
# If an item value is undef it will be handled like the text '?undef?'
# compareValue([1,2,3], [2,1,3])  == 1
# compareValue([1,1,2], [1,2,2,1])  == 1
# compareValue([1,1,2], [1,1,2,2,3])  == 0
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   1 = both arrays have the same value content
#           0 = content of arrays are not equal; this will be set if one
#               of the following conditions were found:
#               - different items in both arrays
#-------------------------------------------------------------------------------
sub compareValue {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parmeter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parmeter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');
    my %list1 = setItems($arr1_ref, 1);
    my %list2 = setItems($arr2_ref, -1);

    # check if all items counted twice
    for (keys %list1) {
        return 0 if (not defined $list2{$_});
    }

    for (keys %list2) {
        return 0 if (not defined $list1{$_});
        return 0 if ($list1{$_} + $list2{$_});
    }
    return 1;
}
#
#
#
#-------------------------------------------------------------------------------
# compareItem   matches the contents of two arrays. The result is true
# if all items from ARRAY1 are found in ARRAY2. The amount of found
# items is important for this test.
# If an item value is undef it will be handled like the text '?undef?'
# compareItem([1,2,3,5], [2,1,4,3])  == 0
# compareItem([1,2,3,4], [2,1,4,3])  == 1
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   1 = both arrays have the same content
#           0 = content of arrays are not equal; this will be set if one of
#               the following conditions were found:
#               - different items in both arrays
#-------------------------------------------------------------------------------
sub compareItem {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # use item value as hash key to shrink data and count the occurrence
    my %count = incrementItems([(@$arr1_ref, @$arr2_ref)]);    # count amount of items

    # check if all items counted twice
    for (keys %count) {
        return 0 if ($count{$_} % 2);
    }
    return 1;
}
#
#
#
#-------------------------------------------------------------------------------
# compareOrder   matches the order of two arrays. The result is true if
# the item values of both arrays are equal and the order are same.
# compareOrder([1,2,3,4], [2,1,4,3])  == 0
# compareOrder([1,2,3,4], [1,2,3,4])  == 1
# If an item value is undef it will be handled like the text '?undef?'
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   1 = both arrays have the same content
#           0 = content of arrays are not equal; this will be set if one of
#               the following conditions were found:
#               - different items
#               - sorted content is different
#-------------------------------------------------------------------------------
sub compareOrder {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');
    my $size1 = scalar(@{$arr1_ref});
    my $size2 = scalar(@{$arr2_ref});

    if ($size1 != $size2) {
        return 0;
    }

    if (!defined($arr1_ref->[0]) && !defined($arr2_ref->[0])) {
        return 1;
    } elsif (!defined($arr1_ref->[0]) || !defined($arr2_ref->[0])) {
        return 0;
    }

    for (my $i = 0; $i < scalar(@{$arr1_ref}); $i++) {
        if ($arr1_ref->[$i] ne $arr2_ref->[$i]) {
            return 0;
        }
    }
    return 1;
}
#
#
#
#-------------------------------------------------------------------------------
# intersection   get all items that a listed in both arrays.
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# intersection([1,2,5,4], [2,1,4,3])  ==> (1,2,4)
# intersection([1,2,4,3,4], [2,1,3])  ==> (1,2,3)
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   Sorted list of equal items
#-------------------------------------------------------------------------------
sub intersection {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # use item value as hash key to shrink data and count the occurrence
    my %cnt1 = incrementItems($arr1_ref);
    my %cnt2 = incrementItems($arr2_ref);
    my @resultList;

    foreach my $key (keys %cnt1) {
        while ($cnt1{$key}--) {

            if (defined($cnt2{$key}) && $cnt2{$key}) {
                push(@resultList, $key);
                $cnt2{$key}--;
            }
        }
    }
    return prepareReturnList(\@resultList);
}
#
#
#
#-------------------------------------------------------------------------------
# difference   matches the contents of two arrays.
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# difference([1,2,3,4], [1,3,4,5])  == [2,5]
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   Sorted list of items that are not stored in the othe array.
#-------------------------------------------------------------------------------
sub difference {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # use item value as hash key to shrink data and count the occurrence
    my %count = incrementItems([(@$arr1_ref, @$arr2_ref)]);    # count amount of items
    my @diff;

    for (keys %count) {

        if ($count{$_} <= 1) {
            push(@diff, $_);
        }
    }
    return prepareReturnList(\@diff);
}
#
#
#
#-------------------------------------------------------------------------------
# substractItem   removes items listed in ARRAYREF1 from the ARRAYREF1.
# One item in ARRAYREF1 removes one items in ARRAYREF2.
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# substractItem([1,3,4,5],[1,2,3,4])  == [5]
# substractItem([1,1,4,5],[1,5])  == [1,4]
# Param1:   reference to first array (minuend)
# Param2:   reference to second array (subtrahend)
# Return:   difference of ARRAYREF1 - ARRAYREF2
#-------------------------------------------------------------------------------
sub substractItem {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # copy ARRAYREF1 content to return array
    my @resultList = @$arr1_ref;

    for (my $i = 0; $i < scalar(@$arr2_ref); $i++) {
        for (my $j = 0; $j < scalar(@resultList); $j++) {
            no warnings;

            if ($arr2_ref->[$i] eq $resultList[$j]) {
                splice(@resultList, $j, 1);
                last;
            }
            use warnings;
        }
    }
    return @resultList;
}
#
#
#
#-------------------------------------------------------------------------------
# substractValue   removes items listed in ARRAYREF1 from the ARRAYREF1.
# A value listed in ARRAYREF1 will be remove all equal values from
# ARRAYREF2. The function returns the undeleted items from ARRAYREF1
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# substractValue([1,2,3,4], [1,3,4,5])  == [5]
# substractValue([1,5], [1,1,4,5])  == [4]
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   list of result items
#-------------------------------------------------------------------------------
sub substractValue {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # copy ARRAYREF1 content to return array
    my @arr1;
    push(@arr1, (defined($_) ? $_ : UNDEF)) for (@$arr1_ref);
    my @arr2;
    push(@arr2, (defined($_) ? $_ : UNDEF)) for (@$arr2_ref);
    my @resultList = ();    # result list
    my %subtrahend;
    $subtrahend{$_} = 1 for (@arr2);    # remove double item values
    my @exclude = keys %subtrahend;

    foreach my $item (@arr1) {
        no warnings;                    # to avoid Argument "?undef?" isn't numeric in smart match

        if (not($item ~~ @exclude)) {
            if (not $item ~~ @resultList) {
                push(@resultList, ($item ne UNDEF) ? $item : undef);
            }
        }
        use warnings;
    }
    return @resultList;
}
#
#
#
#-------------------------------------------------------------------------------
# unscramble   matches the contents of two arrays.
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# unscramble([1,2], [1,4,3])  == [1,2,3,4]
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   Sorted list of singular items stored in array1 and array2
#-------------------------------------------------------------------------------
sub unscramble {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # use item value as hash key to shrink data and count the occurrence
    my %count = incrementItems([(@$arr1_ref, @$arr2_ref)]);    # count amount of items
    my @union;

    for (keys %count) {
        push(@union, $_);
    }
    return prepareReturnList(\@union);
}
#
#
#
#-------------------------------------------------------------------------------
# unique   Gets items from array1 that are not listed in array2.
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# unique([1,2,3], [2,1,4,3])  == []
# unique([1,2,3,4], [1,2,3,5])  == [4]
# unique([1,2,3,5], [1,2,3,4])  == [5]
# Param1:   reference to first array
# Param2:   reference to second array
# Return:   Sorted list with items that contain in array1 but not in
# 			array2.
#-------------------------------------------------------------------------------
sub unique {
    my ($arr1_ref, $arr2_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr1_ref) ne 'ARRAY');
    die "Parameter 2 must be an array reference!" if (ref($arr2_ref) ne 'ARRAY');

    # use item value as hash key to shrink data and count the occurrence
    my %countInc = incrementItems($arr1_ref);    # count amount of item values
    my %countDec = incrementItems($arr2_ref);    # count amount of item values

    # check for unique items
    my @unique;

    for (keys %countInc) {

        if (not defined($countDec{$_})) {
            push(@unique, $_);
        }
    }
    return prepareReturnList(\@unique);
}
#
#
#
#-------------------------------------------------------------------------------
# singularize   singulars all items of an array.
# If an item value is undef it will be handled like the text '?undef?'.
# Before the result is returned this value is changed back to undef.
# singularize([1,2,3,4,5])      == [1,2,3,4,5]
# singularize([1,1,1,1,2])      == [1,2]
# singularize([2,2,3,1,2],'s')  == [1,2,3]
# singularize([2,2,3,1,2],'b')  == [2,3,1]
# singularize([2,2,3,1,2],'e')  == [3,1,2]
# Param1:   reference to array
# Param2:   order selection (default is 's')
#           'b' - keep order from the begin of array
#           'e' - keep order from the end of array
#           all other - sort output
# Return:   Sorted list of singular items.
#-------------------------------------------------------------------------------
sub singularize {
    my ($arr_ref, $order) = @_;
    $order = $order // 's';
    die "Parameter 1 must be an array reference!" if (ref($arr_ref) ne 'ARRAY');
    die "Parameter 2 must be a scalar!"           if (ref($order) ne '');

    if ($order =~ /^(b|e)$/i) {
        my @outList;

        if ($order =~ /^(b)$/i) {

            # order from begin of array
            foreach my $item (@$arr_ref) {
                $item = $item // UNDEF;

                if (not(grep {$item eq $_} @outList)) {
                    push(@outList, $item);
                }
            }
        } else {

            # order from end of array
            for (my $i = scalar(@$arr_ref) - 1; $i >= 0; $i--) {
                my $item = $arr_ref->[$i] // UNDEF;
                no warnings;

                if (not($item ~~ @outList)) {
                    unshift(@outList, $item);
                }
                use warnings;
            }
        }

        for (my $i = 0; $i < scalar(@outList); $i++) {
            if ($outList[$i] eq UNDEF) {
                $outList[$i] = undef;
                last;
            }
        }
        return @outList;
    } ## end if ($order =~ /^(b|e)$/i)
    my %count = incrementItems($arr_ref);    # count amount of items
    return prepareReturnList([keys %count]);
} ## end sub singularize
#
#
#
#-------------------------------------------------------------------------------
# singular   is the short form of singularize([],'b').
# If an item value is undef this subfunction can not be used.
# Before the result is returned this value is changed back to undef.
# singular([1,2,3,4,5])      == [1,2,3,4,5]
# singular([1,1,1,1,2])      == [1,2]
# singular([2,2,3,1,2])      == [2,1,2]
# Param1:   reference to array
# Return:   Sorted list of singular items.
#-------------------------------------------------------------------------------
sub singular {
    my ($arr_ref) = @_;
    die "Parameter 1 must be an array reference!" if (ref($arr_ref) ne 'ARRAY');
    my %found=();
    no warnings;
    my @outlist = grep { !$found{$_}++ } @{$arr_ref};
    use warnings;

    return @outlist;
}
#
#
#
#-------------------------------------------------------------------------------
# incrementItems counts all items values. If an item value is undefined
# the used return key is '?undef?'.
# Param1:   reference to array
# Return:   hash list of counted items.
#-------------------------------------------------------------------------------
sub incrementItems {
    my ($arr_ref,) = @_;
    my %countList;
    $countList{defined() ? $_ : UNDEF}++ for (@$arr_ref);
    return %countList;
}
#
#
#
#-------------------------------------------------------------------------------
# setItems defines to each item, used as a key, a value. If an item
# value is undefined the used key name is '?undef?'.
# Param1:   reference to array
# Param2:   value that will be used to fill the value part of each
#			key/value pair.
# Return:   hash list of counted items.
#-------------------------------------------------------------------------------
sub setItems {
    my ($arr_ref, $value) = @_;
    my %resultList;
    $resultList{defined() ? $_ : UNDEF} = $value for (@$arr_ref);
    return %resultList;
}
#
#
#
#-------------------------------------------------------------------------------
# prepareReturnList removes the content of $unDef to undef and sorts the
# return values.
# Param1:   reference to array
# Return:   array list of items
#-------------------------------------------------------------------------------
sub prepareReturnList {
    my ($arr_ref) = @_;
    my @returnList;
    no warnings;
    push(@returnList, (($_ ne UNDEF) ? $_ : undef)) for (sort @$arr_ref);
    use warnings;
    return @returnList;
}
#
#
#
1;

=pod

=head1 NAME

Array::CompareAndFilter - Basic functions to compare and filter arrays
for different requirements.

=head1 SYNOPSIS

 use Array::CompareAndFilter qw(compareValue compareItem compareOrder intersection difference unscramble unique);
 # or use Array::CompareAndFilter qw(:all);

 # compare the content of two arrays
 if(compareValue([1,2,3,3], [1,2,3])) {
     say "Both arrays have same content.";                      # output
 } else {
     say "Arrays has different content.";
 }

 # compare the content of two arrays
 if(compareItem([1,2,3], [2,3,1])) {
     say "Both arrays have same content.";                      # output
 } else {
     say "Arrays are different.";
 }

 # compare the content and the order of two arrays
 if(compareOrder([1,2,3], [1,2,3])) {
     say "Both arrays have same content in the same order.";    # output
 } else {
     say "Arrays are different.";
 }

 # intersection gets equal items of two arrays
 my @inter = intersection([1,2,3], [2,3,4,2]);
 say "The intersection items (\@inter) are 2 & 3.";

 # substractItem substract ARR2 items from ARR1
 my @subItem = substractItem([3,1,2,3], [2,3]);
 say "The substractItem items (\@subItem) are 1 & 3";

 # substractValue substract ARR2 value from ARR1
 my @subValue = substractValue([3,1,2,3], [2,3]);
 say "The substractValue items (\@subValue) is 1";

 # difference gets items that are not part of the other aray
 my @diff = difference([1,2,3,4], [1,3,4,5]);
 say "The difference items (\@diff) are 2 & 5.";

 # union gets a list of items that part of all arrays
 my @unscramble = unscramble([1,2], [1,4,3]);
 say "The unscramble items (\@unscramble) are 1,2,3 & 4.";

 # unique gets a list of items of array1 that part are not in array2
 my @unique = unique([1,2,3,4,6], [1,2,3,5]);
 say "The unique items (@unique) are 4 & 6.";

 # singularize gets a list of singular items of array
 my @singularize = singularize([3,2,3,4,1]);
 say "The singularize items (\@singularize) are 1, 2, 3 & 4.";
 my @singularize = singularize([3,2,3,4,1],'b');
 say "The singularize items (\@singularize) are 3, 2, 4 & 1.";
 my @singularize = singularize([3,2,3,4,1],'e');
 say "The singularize items (\@singularize) are 2, 3, 4 & 1.";

 # singular gets a list of singular items of array from first to last
 my @singular = singular([3,2,3,4,1]);
 say "The singular items (\@singular) are 3, 2, 4 & 1.";

=head1 DESCRIPTION

This module helps to solve easy tasks with arrays. Comparing of arrays or
filtering array data are this kind of task that this module supports.

=head2 Functions

The following parameter names ARRAY, ARRAY1 and ARRAY2 are synonyms for
array any kind of arrays. If these names are listed in square brackets it
is a synonym of a reference. E.g. [ARRAY1] is a reference to the array
ARRAY1.

Other parameter types will not excepted. If a given scalar value to the
functions has not the reference type ARRAY the function exits with an
error message. E.g. a call of compareValue([1,2,3], 3) will throw an error.

=head3 compareValue

=over 4

=item B<compareValue>([ARRAY1],[ARRAY2])

I<compareValue> compares all values of two arrays. If each value of one
array is found in the other array it will return true (1). The function
returns false (0) if a difference in the content was found. The
comparison is case sensitive. Value is defined as a data value of
# an item.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples for return value 1

 compareValue([1,2,3], [3,2,1]);            # returns 1
 compareValue([1,2,3], [3,2,1,2,3]);        # returns 1

=item Examples for return value 0

 compareValue([1,2,undef], [3,2,1,2,3]);    # returns 0
 compareValue([1,2,4], [3,2,1,2,3]);        # returns 0

=back

=back

=head3 compareItem

=over 4

=item B<compareItem>([ARRAY1],[ARRAY2])

I<compareItem> compares all items of two arrays. If the size and the
contents are equal this function will return 1. The function returns 0
if a difference in the size or in the content is found. The comparison
is case sensitive.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples for return value 1

 compareItem([1,2,3], [3,2,1]);             # returns 1
 compareItem([1,2,undef], [undef,2,1]);     # returns 1

=item Examples for return value 0

 compareItem([1,2,3], [3,2,1,2,3]);         # returns 0
 compareItem([1,2,3], [4,2,1]);             # returns 0

=back

=back

=head3 compareOrder

=over 4

=item B<compareOrder>([ARRAY1],[ARRAY2])

I<compareOrder> compares all items of two arrays. If the size, content
and the order of items are same it will return 1. The function returns 0
if a difference in size, content or order of items is found. The
comparison is case sensitive.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples for return value 1

 compareOrder([1,2,3], [1,2,3]);            # returns 1
 compareOrder([undef], [undef]);            # returns 1
 compareOrder([], []);                      # returns 1

=item Examples for return value 0

 compareOrder([1,2,3], [1,2,3,3]);          # returns 0
 compareOrder([1,2,3], [1,3,2]);            # returns 0

=back

=back

=head3 intersection

=over 4

=item B<intersection>([ARRAY1],[ARRAY2])

I<intersection> returns all items that are listed in each of both arrays
as a sorted list. If one array has no items or no item is listed in the
other array this function returns an empty array. The comparison is
case sensitive.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples

 intersection([1,2,3], [1,2,3]);            # returns (1,2,3)
 intersection([undef], [undef]);            # returns (undef)
 intersection([], []);                      # returns ()
 intersection([1,2], [2,3]);                # returns (2)
 intersection([2,1,2], [3,1,2,2]);          # returns (1,2,2)

=back

=back

=head3 substractItem

=over 4

=item B<substractItem>([ARRAY1],[ARRAY2])

I<substractItem> returns an array with a subtraction list of the
operation ARRAY1 - ARRAY2. If an item value in ARRAY2 is listed in
ARRAY1, than one item of ARRAY1 will be removed from the begin of the
list. To remove multiple items, same amount of items have to be listed
in ARRAY1. If no match between an item of ARRAY2 to ARRAY1 is found,
no change will happen in ARRAY1.

The item order of ARRAY1 will be kept in the result list.

=over 4

=item Examples

 substractItem([1,2,3,4], [1,2,3]);         # returns (4)
 substractItem([undef], [undef]);           # returns ()
 substractItem([1,2], [3]);                 # returns (1,2)
 substractItem([1,3,2,2], [2,1,2]);         # returns (3)

=back

=back

=head3 substractValue

=over 4

=item B<substractValue>([ARRAY1],[ARRAY2])

I<substractValue> returns an array with a subtraction list of the
operation ARRAY1 - ARRAY2. A value in ARRAY2 removes all items of
ARRAY1 that have the same value. If no match between an item of ARRAY2
to ARRAY1 is found, no change will happen in ARRAY1.

The item order of ARRAY1 will be kept in the result list.

=over 4

=item Examples

 substractValue([1,2,3,2,1], [1,2]);        # returns (3)
 substractValue([undef,undef], [undef]);    # returns ()
 substractValue([], [1,2]);                 # returns ()
 substractValue([1,2], [1,3]);              # returns (2)

=back

=back

=head3 difference

=over 4

=item B<difference>([ARRAY1],[ARRAY2])

I<difference> returns a list of items that are not listed in the other
array. The comparison is case sensitive.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples

 difference([1,2,3,4], [1,3,4,5]);          # returns (2,5)
 difference([1], [2]);                      # returns (1,2)
 difference([undef,1], [2,3,1]);            # returns (2,3,undef)
 difference([2,1], [3,1,2]);                # returns (3)

=back

=back


=head3 unscramble

=over 4

=item B<unscramble>([ARRAY1],[ARRAY2])

I<unscramble> returns a summary list of items. Each item value of
both arrays will exist maximal one time.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples

 unscramble([1,2], [1,4,3]);                # returns (1,2,3,4)
 unscramble([1,1], [2,3,3,1]);              # returns (1,2,3)
 unscramble([1,1], []);                     # returns (1)

=back

=back

=head3 unique

=over 4

=item B<unique>([ARRAY1],[ARRAY2])

I<unique> checks all item values of ARRAY1 in the array of ARRAY2.
It will return all items which were not found in ARRAY2.

If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples

 unique([1,2,3], [2,1,4,3]);                # returns ()
 unique([1,2,3,4], [1,2,3,5]);              # returns (4)
 unique([1,2,3,5], [2,3,4]);                # returns (1,5)

=back

=back

=head3 singularize

=over 4

=item B<singularize>([ARRAY])

I<singularize> removes all double items values of the given array list.
By using an order argument the output can be selected for some different
result variations.

'B<b>' or 'B<B>' scans the input array by the item values from the
begin and returns a list were the first found position of each value is
used. E.g. [1,2,1,3] -> (1,2,3)

'B<e>' or 'B<E>' scans the input array by the item values from the
end and returns a list were the last found position of each value is
used. E.g. [1,2,1,3] -> (2,1,3)

No order argument or other data then 'b|B' or 'e|B' will return a sorted
list of singularize values.

If sorting is selected than following issue needes to be considered.
If an item value is undefined it will be handled within the function like
the text like '?undef?'. If an item value of ARRAY1 or ARRAY2 has the same
value than the function returns a undef for this.

=over 4

=item Examples

 singularize([qw(d b d b c a)]);            # returns ('a','b','c','d')
 singularize([3,2,3,4,1]);                  # returns (1,2,3,4)
 singularize([3,2,3,4,1],'s');              # returns (1,2,3,4)
 singularize([3,2,3,4,1],'b');              # returns (3,2,4,1)
 singularize([3,2,3,4,1],'e');              # returns (2,3,4,1)

=back

=back

=head3 singular

=over 4

=item B<singular>([ARRAY])

I<singular> removes all double items values of the given array list.
This subfunction scans the input array by the item values from the
begin and returns a list were the first found position of each value is
used. E.g. [1,2,1,3] -> (1,2,3)

It is expected that the array has no undefined element. Otherwise use
singularize().

=over 4

=item Examples

 singular([qw(d b d b c a)]);            # returns ('d','b','c','a')
 singular([3,2,3,4,1]);                  # returns (3,2,4,1)

=back

=back

=head1 VERSION

v1.100

=head1 AUTHOR

H. Klausing <h.klausing (at) gmx.de>

=head1 LICENSE

Copyright (c) 2012 H. Klausing, All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
__END__

