#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Binary search-able heap in 100% Pure Perl
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Binary::Heap::Search;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
our $VERSION = 2017.117;

if (0)                                                                          # Save to S3:- this will not work, unless you're me, or you happen, to know the key
 {my $z = 'BinaryHeapSearch.zip';
  print for qx(zip $z $0 && aws s3 cp $z s3://AppaAppsSourceVersions/$z && rm $z);
 }

#1 Methods
sub new($)                                                                      # Create a new Binary Search-able Heap
 {my ($compare) = @_;                                                           # Sub to perform <=> on two elements of the heap
  return bless {compare=>$compare};
 }

sub arrays    {$_[0]{arrays} //= []}                                            ## Each array in the heap is in the order created by compare
sub compare   {$_[0]{compare}}                                                  ## A sub that performs <=>/cmp on any two elements on the heap
sub size      {scalar @{$_[0]->heaps}}                                          ## Number of arrays in the heap

sub mergeArrays($$$)                                                            ## Merge two ordered arrays to make a new ordered array
 {my ($compare, $b, $c) = @_;                                                   # Sub to order elements, first array of elements to be merged, second array of elements to be merged
  my @a;
  while(@$b and @$c)                                                            # Sequentially merge the two arrays
   {my $k = $compare->($$b[0], $$c[0]);                                         # Compare the smallest elements in each array
    if    ($k < 0) {push @a, shift @$b}                                         # Save smallest element
    elsif ($k > 0) {push @a, shift @$c}
    else {confess "Duplicate entry ", dump($$b[0])}
   }
  @a, @$b, @$c                                                                  # Add remaining un-merged elements, the order does not matter because one of the arrays will be emptied by the preceding merge
 }

sub mergeAdjacentArrays($$$)                                                    ## Merge adjacent arrays
 {my ($arrays, $compare, $start) = @_;                                          # Index of first array to be merged

  for my $small(reverse 1..$start)                                              # Each array that might be merge-able
   {my $b = $arrays->[$small-1];                                                # Larger array
    my $c = $arrays->[$small-0];                                                # Smaller array
    if ($b and @$b and $c and @$c and @$b <= @$c * 2)                           # Adjacent arrays are close enough in size to warrant merging
     {$arrays->[$small-1] = [mergeArrays($compare, $b, $c)];
     }
    else                                                                        # Adjacent arrays are to different in size to be worth merging
     {splice @$arrays, $small+1, $start-$small if $small != $start;             # Remove previously merged arrays - this inefficient operation is done just once on a small array
      return
     }
   }
  $#$arrays = 0;                                                                # All the arrays have been merged into just one array
 }

sub add($$)                                                                     # Add an element to the heap of ordered arrays
 {my ($heap, $element) = @_;                                                    # Heap, element (that can be ordered by compare)
  my $compare = $heap->compare;
  my $arrays  = $heap->arrays;

  for my $arrayIndex(0..$#$arrays)                                              # Try to put the element on top of one of the existing arrays starting at the largest one.  We could of course just add the new element as a single array at the end and then merge up through all the arrays, doing so would avoid the splice operation in merge() but seems to produce longer sequences of arrays than the technique used which is to find the first viable array.
   {my $array = $arrays->[$arrayIndex];
    my $c = $compare->($element, $array->[-1]);                                 # Compare the element to be added to the topmost element of the current array
    if ($c == 1)                                                                # The element to be added is greater than the largest element in the current array
     {push @$array, $element;                                                   # Add the element to the top of this array
      mergeAdjacentArrays($arrays, $compare, $arrayIndex) if $arrayIndex;       # Merge two adjacent arrays if they are close enough in size
      return;
     }
    elsif ($c == 0)                                                             # Duplicate element detected
     {confess "Duplicate element ", dump($element);
     }
   }
  push @$arrays, [$element];                                                    # Cannot put element on top of any array in the heap so create a new array
  mergeAdjacentArrays($arrays, $compare, $#$arrays) if $#$arrays;               # Try to merge the newest array if there is an existing array into which to merge it
 }

sub binarySearch($$$)                                                           ## Find an element in an array using binary search
 {my ($array, $compare, $element) = @_;                                         # Array, element
  my $m = 0;                                                                    # Check the lower bound of the array
  my $e = $array->[$m];                                                         # Lowest element in the array
  my $c = $compare->($element, $e);                                             # Compare with lowest element in the array
  return $e if $c == 0;                                                         # Equal to the lowest element
  return undef unless $c == 1;                                                  # Lower than any element in the array
  my $M = $#$array;                                                             # Check the upper bound of the array
  my $E = $array->[$M];                                                         # Highest element in the array
  my $C = $compare->($element, $E);                                             # Compare with highest element in the array
  return $E    if $C == 0;                                                      # Equal to the highest element
  return undef if $C == 1;                                                      # Lower than any element in the array

  while($m+1 < $M)                                                              # Narrow the zone
   {my $i = int(($m+$M)/2);                                                     # Index of a point halfway between
    my $e = $array->[$i];                                                       # Element at mid point
    my $c = $compare->($element, $e);                                           # Compare
    return $e if $c == 0;                                                       # Found
    ($c == 1 ? $m : $M) = $i;
   }                                                                            # Continue to narrow the range
  undef                                                                         # Not found
 }

sub find($$)                                                                    # Find an element in the heap
 {my ($heap, $element) = @_;                                                    # Heap, element (that can be ordered by compare)
  my $compare = $heap->compare;
  my $arrays  = $heap->arrays;

  for my $array(@$arrays)                                                       # Use a binary search on each array in the heap
   {my $e = binarySearch($array, $compare, $element);
    return $e if defined $e                                                     # Return matching element
   }
  undef                                                                         # Element not found
 }

# Test
sub test{eval join('', <Binary::Heap::Search::DATA>) or die $@}

test unless caller;

# Documentation
#extractDocumentation() unless caller;                                          # Extract the documentation

1;

=encoding utf-8

=head1 Name

Binary::Heap::Search - Binary search-able heap in 100% Pure Perl

=head1 Synopsis

=head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, modify and
install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

__DATA__
use utf8;
use Test::More tests=>85;

my $compare = sub
 {my ($a, $b) = @_;
  defined($a) && defined($b) or confess;
  $a cmp $b
 };

sub newHeap($$)
 {my ($string, $result) = @_;
  my $h = Binary::Heap::Search::new($compare);
  $h->add($_) for split //, $string;
  my $dump = dumpHeap($h);
# say STDERR "newHeap(\'$string\', \'$dump\');";
  ok $dump eq $result;
  $h
 }

sub dumpHeap($)
 {my ($h) = @_;
  join ',', map {join '', @$_} @{$h->arrays}
 }

newHeap('0',  '0') ;                                                            # Ascending
newHeap('01', '01');
newHeap('012', '012');
newHeap('0123', '0123');
newHeap('01234', '01234');
newHeap('012345', '012345');
newHeap('0123456', '0123456');
newHeap('01234567', '01234567');
newHeap('012345678', '012345678');
newHeap('0123456789', '0123456789');

newHeap('0', '0');                                                              # Descending
newHeap('10', '01');
newHeap('210', '012');
newHeap('3210', '123,0');
newHeap('43210', '01234');
newHeap('543210', '12345,0');
newHeap('6543210', '23456,01');
newHeap('76543210', '01234567');
newHeap('876543210', '12345678,0');
newHeap('9876543210', '23456789,01');

newHeap('edcba9876543210', '23456789abcde,01');
newHeap('fedcba9876543210', '3456789abcdef,012');

if (1)                                                                          # Mixed
 {my $h = newHeap(
   'GJKLM23mnoHklTUVWXFQRS45YZ01hiuvwIpqrsfgNOPbcdejxyzABCtDE6789a',
   '012345ABCDEFGHIJKLMNOPQRSTUVWXYZbcdefghijklmnopqrstuvwxyz,6789a');

  for(0..9, 'a'..'z', 'A'..'Z')                                                 # Find
   {ok $h->find($_) eq $_;
   }
 }

1
