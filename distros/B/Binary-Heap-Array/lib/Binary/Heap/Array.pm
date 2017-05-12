#!/usr/bin/perl
#-------------------------------------------------------------------------------
# An extensible array implemented as a binary heap in 100% Pure Perl
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Binary::Heap::Array;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text 2017.114 qw(:all);
use Time::HiRes qw(time);
our $VERSION = 2017.121;

saveToS3('BinaryHeapArray') if 0;                                               # Save to S3:- this will not work, unless you're me, or you happen, to know the key

my @speedChars = split //, 'ipsw';                                              # The names of the optimisations
my @packages;                                                                   # The names of the generated packages
our @optimisations;                                                             # All  combinations of optimizations

for my $speedNo(0..(1<<@speedChars)-1)                                          # Create a package for each combination of optimisations
 {my $pack = '';
  my $opts = '';
  for(keys @speedChars)                                                         # Each optimisation available
   {my $c = ($speedNo>>$_) % 2;
    $pack .= $c ? uc($speedChars[$_]) : lc($speedChars[$_]);
    $opts .= $c ? lc($speedChars[$_]) : '';
   }
  push @optimisations, $opts;                                                   # All optimization possibilities

  my $code = &code;                                                             # Base code
  my $s = <<END;
package Binary::Heap::Array::$pack;
use Data::Dump qw(dump);
use Data::Table::Text 2017.114 qw(:all);
use Carp;

sub speedNo{$speedNo}                                                           # Speed number

$code
END
  eval $s;                                                                      # Generate and optimise the package
  $@ and confess $@;
 }

#1 Methods
sub new(*)                                                                      # Create a new binary heap array.  A string of flags enables optimizations to the base version, which uses the minimum amount of memory at all times, to use more memory to obtain shorter run times, These flags are: 'i' - retain memory for subsequent reuse rather than freeing it as soon as possible; 'p' -  add two fields to each array to optimize shift/unshift operations; 's' - add a field to each array to cache the size of the array; 'w' - add a field each array to cache the current width of the array of subarrays.
 {my ($flags) = @_;                                                             # Optimization flags ipsw in any order surrounding quotes are not necessary
  my $f = $flags;
  my $name = 'Binary::Heap::Array::';
  for(@speedChars)                                                              # Generate package name matching requested optimisations
   {if ($f =~ m/$_/i)
     {  $f =~ s/$_//gi;
      $name .= uc($_);
     }
    else
     {$name .= lc($_);
     }
   }
  $f =~ /\A\s*\Z/ or confess "Invalid flags '$f' in '$flags'";                  # Check flags syntax

  return bless [], $name;                                                       # Bless into appropriately optimized package
 } # new

sub code {<<'END'}                                                              # Code to be optimised
sub speedInUse{(speedNo>>0)%2}                                                  ## Use a vec() in each array to mark which sub arrays can be reused rather than being freed immediately
sub speedPp   {(speedNo>>1)%2}                                                  ## Use pre/post to skip over elements at the start/end at the cost of two additional fields per array
sub speedSize {(speedNo>>2)%2}                                                  ## Cache the current size of the array at the cost of an additional field per array
sub speedWidth{(speedNo>>3)%2}                                                  ## Cache the current width of the array at the cost of an additional field per array

sub subarray                                                                    ## An array, always a power of 2 wide, containing sub arrays which contain the caller's data or slots which are empty, each of the sub arrays is a power of 2 wide which depends on its position in the array of sub arrays so that all of these arrays make good use of memory provided via a buddy memory allocation system to construct the binary heap array
 {my ($array) = @_;
  no overloading;
  $array->[0] //= []                                                            # Field 1
 }
sub speed :lvalue                                                               ## Algorithm to use
 {my ($array) = @_;
  no overloading;
  $array->[1] //= (my $v = 0)                                                   # Field 2
 }
sub inUse :lvalue                                                               ## A vec() of bits, the same width as subarray where each bit tells us whether the corresponding sub array is in use or not.
 {my ($array) = @_;
  no overloading;
  confess unless speedInUse;
  $array->[2] //= (my $v = '')                                                  # Field 3
 }
sub pre :lvalue                                                                 ## The number of entries to ignore at the beginning to assist with shift/unshift
 {my ($array) = @_;
  no overloading;
  confess unless speedPp;
  $array->[3] //= (my $v = 0)                                                   # Field 4
 }
sub post :lvalue                                                                ## The number of entries to ignore at the end to assist with pop/push
 {my ($array) = @_;
  no overloading;
  confess unless speedPp;
  $array->[4] //= (my $v = 0)                                                   # Field 5
 }
sub currentSize :lvalue                                                         ## The current size of the array
 {my ($array) = @_;
  no overloading;
  confess unless speedSize;
  $array->[5] //= (my $v = 0)                                                   # Field 6
 }
sub currentWidth :lvalue                                                        ## The current width of the array
 {my ($array) = @_;
  no overloading;
  confess unless speedWidth;
  $array->[6] //= (my $v = 0)                                                   # Field 7
 }

sub at($$) :lvalue                                                              # Address the element at a specified index so that it can get set or got
 {my ($array, $index) = @_;                                                     # Array, index of element
  my $n = size($array);                                                         # Array size
  return undef if $index < -$n or $index >= $n;                                 # Index out of range
  return &atUp(@_) if $index >= 0;
  &atDown(@_)
 } # at                                                                         # It would be nice to use overload @{} here but this requires flattening the array which would be very expensive on large arrays

sub inUseVector ($) :lvalue                                                     ## Sub arrays in use
 {my ($array) = @_;
  return inUse($array) if speedInUse;
  my $v = '';
  my @a = @{subarray($array)};
  vec($v, $_, 1) = !!$a[$_] for 0..$#a;
  $v
 }

sub pop($)                                                                      # Pop the topmost element from the leading full array and spread the remainder of its contents as sub arrays of the correct size for each preceding empty slot
 {my ($array) = @_;                                                             # Array from which an element is to be popped
  my $N = size($array);                                                         # Size of array
  return undef unless $N;                                                       # Cannot pop from an empty array

  if (speedPp)                                                                  # Fast with pre and post
   {my $element = at($array, -1);
    post($array)++;
    currentSize($array)-- if speedSize;                                         # Decrease cached size of array if possible - has to be done late to avoid confusion over at
    return $element;
   }
  else
   {currentSize($array)-- if speedSize;                                         # Decrease cached size of array if possible - has to be done late to avoid confusion over at
    my $S = subarray($array);                                                   # Sub array list for this array
    my $v = inUseVector($array);                                                # Sub arrays in use

    for my $i(keys @$S)                                                         # Index to each sub array
     {my $s = $S->[$i];                                                         # Sub array
      if (vec($v, $i, 1))                                                       # Full sub array
       {my $pop = CORE::pop @$s;                                                # Pop an element off the first full sub array
        for my $I(0..$i-1)                                                      # Distribute the remaining elements of this sub array so that each sub array is always a power of two wide which depends on teh position of the sub array in the array of sub arrays
         {my $j = 1<<$I;
          splice @{$S->[$I]}, 0, $j, splice @$s, -$j, $j;                       # Copy block across
          vec(inUse($array), $I, 1) = 1 if speedInUse;                          # Mark this sub array as in use
         }
        if ($N == 1)                                                            # We are popping the last element in a binary heap array
         {$#{subarray($array)} = -1;                                            # Remove all sub arrays
          inUse($array)        = '' if speedInUse;                              # Mark all sub arrays as not in use and shorten the vec() string at the same time
          currentWidth($array) =  0 if speedWidth;                              # New width of array of sub arrays
          @$S = ();                                                             # Empty the array of sub arrays
         }
        else                                                                    # Pop an element that is not the last element in a binary heap array
         {if (speedInUse)
           {vec(inUse($array), $i, 1) = 0;                                      # Mark sub array as not in use
           }
          else
           {$S->[$i] = undef;                                                   # Free sub array as it is no longer in use
           }
          my $W = width($array);                                                # Get current width
          my $w = containingPowerOfTwo($W);                                     # Current width is contained by this power of two
          inUse($array) = substr(inUse($array), 0, 1<<($w-3)) if speedInUse;    # Keep vec() string length in bounds - the 3 is because there 2**3 bits in a byte as used by vec()
          splice @$S, 1<<$w if @$S > 1<<$w;                                     # Shorten the array of sub arrays while leaving some room for a return to growth
          $S->[$_] = undef for $W..(1<<$w)-1;                                   # Remove outer inactive arrays but keep inner inactive arrays to reduce the allocation rate - the whole point of the inUse array
          currentWidth($array) = $w+1                                           # New width of array of sub arrays
            if speedWidth and currentWidth($array) <= $w;
         }
        return $pop                                                             # Return popped element
       }
     } # for each subarray
   }
  confess "This should not happen"                                              # We have already checked that there is at least one element on the array and so an element can be popped so we should not arrive here
 } # pop

sub push($$)                                                                    # Push a new element on to the top of the array by accumulating the leading full sub arrays in the first empty slot or create a new slot if none already available
 {my ($array, $element) = @_;                                                   # Array, element to push
  currentSize($array)++ if speedSize;                                           # Increase cached size of array if possible

  if (speedPp and my $p = post($array))                                         # Allow for post
   {if (size($array))                                                           # Quick push
     {post($array)--;
      at($array, -1) = $element;
     }
    else                                                                        # Push first element
     {post($array) = pre($array) = 0; @{subarray($array)} = ();
      inUse($array) = '' if speedInUse;
      $array->push($element);
     }
   }
  else                                                                          # No pops we can replace
   {my $S = subarray($array);                                                   # Sub array list
    my $v = inUseVector($array);                                                # Sub arrays in use
    if (defined (my $z = firstEmptySubArray($array)))                           # First empty sub array will be the target used to hold the results of the push
     {$S->[$z] = ();                                                            # Empty target array
      for my $i(reverse 0..$z-1)                                                # Index to each sub array preceding the target array
       {my $s = $S->[$i];                                                       # Sub array
        if (vec($v, $i, 1))                                                     # Sub array in use
         {CORE::push @{$S->[$z]}, @$s;                                          # Push in use sub array
          if (speedInUse)
           {vec(inUse($array), $i, 1) = 0;                                      # Mark this array as no longer in use
           }
          else
           {$S->[$i] = undef;                                                   # Free this array as is is no longer in use
           }
         }
       }
      CORE::push @{$S->[$z]}, $element;                                         # Save element on target array
      vec(inUse($array), $z, 1) = 1 if speedInUse;                              # Mark target array as in use
      currentWidth($array) = $z+1 if speedWidth and currentWidth($array) <= $z; # Cache new width if possible and greater
     }
    else                                                                        # All the current sub arrays are in use
     {my $w = width($array);                                                    # Current width of array of sub arrays
      my $W = 1<<containingPowerOfTwo($w+1);                                    # New width of array of sub arrays
      my $a = $S->[$w] = [];                                                    # Create new target sub array
      CORE::push @$a, vec($v, $_, 1) ? @{$S->[$_]} : () for reverse 0..$w-1;    # Push all sub arrays onto target
      CORE::push @$a, $element;                                                 # Push element onto target
      if (speedInUse)
       {vec(inUse($array), $_, 1) = 0 for 0..$w-1;                              # All original sub arrays are no longer in use
        vec(inUse($array), $w, 1) = 1;                                          # Newly built target sub array is in use
       }
      else
       {$S->[$_] = undef for 0..$w-1;                                           # All original sub arrays are no longer in use
       }
      currentWidth($array) = $w+1 if speedWidth and currentWidth($array) <= $w; # Cache new width if possible and greater
      $S->[$_] = undef for $w+1..$W-1;                                          # Pad out array of subs arrays so it is a power of two wide
     }
   }
  $array
 } # push

sub size($)                                                                     # Find the number of elements in the binary heap array
 {my ($array) = @_;                                                             # Array
  return currentSize($array) if speedSize;                                      # Use cached size if possible
  my $n = 0;                                                                    # Element count, width of current sub array
  my $s = subarray($array);                                                     # Array of sub arrays
  if ($s and @$s)                                                               # Sub array
   {my $v = inUseVector($array);                                                # Sub arrays in use
    my $p = 1;                                                                  # Width of current sub array
    for(0..$#$s)                                                                # Each sub array
     {$n += $p if vec($v, $_, 1);                                               # Add number of elements in this sub array if there are any
      $p += $p;                                                                 # Width of next sub array
     }
   }
  if (speedPp)
   {my $p = pre($array);                                                        # Allow for pre and post
    my $q = post($array);
    return $n - $p - $q                                                         # Count of elements found with modifications from pre and post
   }
  $n                                                                            # Count of elements found
 } # size

sub shift($)                                                                    # Remove and return the current first element of the array
 {my ($array) = @_;                                                             # Array
  my $n = size($array);                                                         # Size of array
  return undef unless $n;                                                       # Use cached size if possible
  my $element = at($array, 0);                                                  # Check that there is a first element
  if (speedPp)
   {pre($array)++;                                                              # Skip over the first element
    currentSize($array)-- if speedSize;                                         # Decrease cached size of array if possible
   }
  else                                                                          # Pop all elements and then push then on again one level down
   {my @a;                                                                      # save area for array
    CORE::unshift @a, $array->pop for 0..$n-1;                                  # Undo the existing array
    shift @a;                                                                   # Remove the shifted element
    $array->push($_) for @a;                                                    # Restore each element one place down
   }
  $element                                                                      # Return successfully removed element
 } # shift

sub unshift($$)                                                                 # Insert an element at the start of the array
 {my ($array, $element) = @_;                                                   # Array, element to be inserted

  if (speedPp and pre($array))
   {pre($array)--;                                                              # Skip over the existing preceding element
    currentSize($array)++ if speedSize;                                         # Increase cached size of array if possible
    at($array, 0) = $element;                                                   # Insert new element
   }
  elsif (speedPp)                                                               # Add a new sub array
   {my $w = width($array);
    if (speedInUse)
     {vec(inUse($array), $w, 1) = 1;
      vec(inUse($array), $_, 1) = 0 for $w+1..$w+$w-1;
     }
    currentWidth($array) = $w+1 if speedWidth and currentWidth($array) <= $w;   # Cache new width if possible and greater
    subarray($array)->[$w][pre($array) = (1<<$w)-1] = $element;                 # Insert element
    currentSize($array)++ if speedSize;                                         # Increase cached size of array if possible
   }
  else                                                                          # Pop all elements and then push then on again one level down
   {my @a;                                                                      # Save area for array
    CORE::unshift @a, $array->pop for 0..size($array)-1;                        # Undo the existing array
    $array->push($_) for $element, @a;                                          # Place new element followed by existing elements
   }
  $array                                                                        # Return array so we can chain operations
 } # unshift

sub width($)                                                                    ## Current width of array of sub arrays where the sub arrays hold data in use
 {my ($array) = @_;                                                             # Array
  return currentWidth($array) if speedWidth;                                    # Use cached width if possible
  my $w = -1;                                                                   # Width
  my $s = subarray($array);                                                     # Array of sub arrays
  my $v = inUseVector($array);                                                  # Sub arrays in use
  for(keys @$s) {$w = $_ if vec($v, $_, 1)}
  $w + 1                                                                        # Count of elements found
 } # width

sub firstEmptySubArray($)                                                       ## First unused sub array
 {my ($array) = @_;                                                             # Array
  my $w = width($array);                                                        # Width of array of sub arrays
  my $v = inUseVector($array);                                                  # Sub arrays in use
  for(0..$w-1)                                                                  # Each sub array
   {return $_ unless vec($v, $_, 1);                                            # First sub array not in use
   }
  undef                                                                         # All sub arrays are in use
 } # firstEmptySubArray

sub atUp($$) :lvalue                                                            ## Get the element at a specified positive index by going up through the array of sub arrays
 {my ($array, $index) = @_;                                                     # Array, index of element
  $index += pre($array) if speedPp;                                             # Allow for pre and post
  my $S = subarray($array);                                                     # Sub array list
  my $v = inUseVector($array);                                                  # Sub arrays in use
  for my $i(reverse 0..$#$S)                                                    # Start with the widest sub array
   {my $width = 1 << $i;                                                        # Width of array at this position in the array of sub arrays
    next unless vec($v, $i, 1);
    my $s = $S->[$i];                                                           # Sub array at this position
    return $s->[$index] if $index < $width;                                     # Get the indexed element from this sub array if possible
    $index -= $width;                                                           # Reduce the index by the size of this array and move onto the next sub array
   }
  undef
 } # atUp

sub atDown($$) :lvalue                                                          ## Get the element at a specified negative index by going down through the array of sub arrays
 {my ($array, $index) = @_;                                                     # Array, index of element
  $index -= post($array) if speedPp;                                            # Allow for pre and post
  my $S = subarray($array);                                                     # Sub array list
  my $v = inUseVector($array);                                                  # Sub arrays in use
  for my $i(0..$#$S)                                                            # Start with the narrowest sub array
   {my $width = 1 << $i;                                                        # Width of array at this position in the array of sub arrays
    next unless vec($v, $i, 1);
    my $s = $S->[$i];                                                           # Sub array at this position
    return $s->[$index] if -$index <= $width;                                   # Get the indexed element from this sub array if possible
    $index += $width;                                                           # Reduce the index by the size of this array and move onto the next sub array
   }
  undef
 } # atDown

use overload                                                                    # Operator overloading
  '@{}'=>\&convertToArray,                                                      # So we can process with a for loop
  '""' =>\&convertToString,                                                     # So we can convert to string
  'eq' =>\&equals;                                                              # Check whether two arrays are equal

sub convertToArray($)                                                           ## Convert to normal perl array so we can use it in a for loop
 {my ($array) = @_;                                                             # Array to convert
  my $w = width($array);                                                        # Width of array of sub arrays
  my $v = inUseVector($array);                                                  # Sub arrays in use
  my @a;
  for(reverse 0..$w-1)                                                          # Each sub array
   {next unless vec($v, $_, 1);
    my $a = subarray($array)->[$_];
    CORE::push @a, @{subarray($array)->[$_]};
   }
  if (speedPp)                                                                  # Allow for pre and post
   {my $p = pre($array);
    my $q = post($array);
    splice @a,   0, $p if $p;
    splice @a, -$q, $q if $q;
   }
  [@a]
 }

sub unpackVector($)                                                             # Unpack the in use vector
 {my ($array) = @_;
  my $v = inUseVector($array);
  $v ? unpack("b*", $v) : ''
 }

sub convertToString($)                                                          ## Convert to string
 {my ($array) = @_;                                                             # Array to convert

  my $e = sub
   {my $a = subarray($array);
    return '' unless $a and @$a;
    'subarrays='.nws(dump($a))
   }->();

   my $i = sub                                                                  # Array has inUse vector
   {return "inUse=".unpackVector($array).', ' if speedInUse && width($array);
    ''
   }->();

  my $p = speedPp ? sub                                                         # Array has pre/post
   {my $s = '';
    my $p = pre($array);  $s .= "pre=$p, "  if $p;
    my $q = post($array); $s .= "post=$q, " if $q;
    $s
   }->() : '';

  my $s = sub                                                                   # Size of array
   {my $s = size($array);
    return "size=$s, " if $s;
    '';
   }->();

  my $w = sub                                                                   # Width of array of sub arrays
   {my $w = width($array);
    return "width=$w, " if $w;
    '';
   }->();

  __PACKAGE__."($s$w$p$i$e)"                                                    # String representation of array
 }

sub equals($$)                                                                  ## Equals check whether two arrays are equal
 {my ($A, $B) = @_;                                                             # Arrays to check
  my $nA = $A->size;
  my $nB = $B->size;
  return 0 unless $nA == $nB;                                                   # Different sized arrays cannot be equal
  for(0..$nA-1)                                                                 # Check each element
   {return 0 unless $A->at($_) eq $B->at($_);
   }
  1
 }
END
# Test
sub test{eval join('', <Binary::Heap::Array::DATA>) or die $@}                  # Tests

test unless caller;

# Documentation
#extractDocumentation() unless caller;                                          # Extract the documentation

1;

=encoding utf-8

=head1 Name

Binary::Heap::Array - Extensible array each of whose component arrays is an
integral power of two wide.

=head1 Synopsis

  my $a = Binary::Heap::Array::new(ipsw);

  $a->push(1)->push(2);
  ok $a->size   == 2;
  ok $a->at( 0) == 1;
  ok $a->at( 1) == 2;
  ok $a->at(-1) == 2;
  ok $a->at(-2) == 1;
     $a->at( 0)  = 2;
  ok $a->at(-2) == 2;
  ok $a->pop    == 2;
  ok $a->size   == 1;
  ok $a->shift  == 2;
  ok $a->size   == 0;
  $a->unshift(3);
  ok $a->size   == 1;
  $a->unshift(2);
  ok $a->size   == 2;
  $a->unshift(1);
  ok $a->size   == 3;

=head1 Methods

=head2 new($flags)

sub new(*)                                                                      # Create a new binary heap array.  A string of flags enables optimizations to the base version, which uses the minimum amount of memory at all times, to use more memory to obtain shorter run times, These flags are: 'i' - retain memory for subsequent reuse rather than freeing it as soon as possible; 'p' -  add two fields to each array to optimize shift/unshift operations; 's' - add a field to each array to cache the size of the array; 'w' - add a field each array to cache the current width of the array of subarrays.

     Parameter  Description
  1  $flags     Optimization flags ipsw in any order surrounding quotes are not necessary

=head2 at :lvalue($array, $index)

Address the element at a specified index so that it can get set or got

     Parameter  Description
  1  $array     Array
  2  $index     index of element

=head2 pop($array)

Pop the topmost element from the leading full array and spread the remainder of its contents as sub arrays of the correct size for each preceding empty slot

     Parameter  Description
  1  $array     Array from which an element is to be popped

=head2 push($array, $element)

Push a new element on to the top of the array by accumulating the leading full sub arrays in the first empty slot or create a new slot if none already available

     Parameter  Description
  1  $array     Array
  2  $element   element to push

=head2 size($array)

Find the number of elements in the binary heap array

     Parameter  Description
  1  $array     Array

=head2 shift($array)

Remove and return the current first element of the array

     Parameter  Description
  1  $array     Array

=head2 unshift($array, $element)

Insert an element at the start of the array

     Parameter  Description
  1  $array     Array
  2  $element   element to be inserted

=head1 Index

L</at :lvalue($array, $index)>
L</new($flags)>
L</pop($array)>
L</push($array, $element)>
L</shift($array)>
L</size($array)>
L</unshift($array, $element)>

=head1 Installation

This module is written in 100% Pure Perl in a single file and is thus easy to
read, modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 See also

The arrays used to construct the binary heap array are all an integral power of
two wide and thus make good use of the memory allocated by
L<Data::Layout::BuddySystem> or similar.

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests=>186237;
sub debug{0}                                                                    # 0 - no debug, 1 - do debug
our @optimisations;                                                             # All  combinations of optimizations
my $speed;                                                                      # The name of the package to test

sub checkWidth($)                                                               # Check that all the arrays used in the construction of this binary heap array are a power of two in width
 {my ($array) = @_;                                                             # Array  to check
  my $s = $array->subarray;                                                     # Sub arrays
  return unless $s and @$s;                                                     # Empty array is OK
  !defined(powerOfTwo(scalar @$s))                                              # The array must either be empty or a power of two in width
    and confess "The width of this array of sub arrays is not a power of two: $array";

  for(@$s)                                                                      # Each sub array
   {next unless $_ and @$_;                                                     # Empty array is OK
    !defined(powerOfTwo(scalar @$_))                                            # The array must either be empty or a power of two in width
      and confess "The width of this sub array is not a power of two: $array";
   }
 } # checkWidth

sub newArray($)                                                                 # Push: create an array by pushing
 {my $number = $_[0]//0;
  my $array  = Binary::Heap::Array::new($speed);                                # Request an array with the desired optimizations
  $array->push($_-1) for 1..$number;
  checkWidth($array);
  $array
 }

sub ats($)                                                                      # At
 {my ($n) = @_;
  my $a = newArray($n);
  ok $a->at(0) == 0 if $n;
  ok $a->at(1) == 1 if $n > 1;
  ok $a->at(-1) == $n-1 if $n;
  ok $a->at($_-$n) == $_ for 0..$n-1;
 }

sub pops($)                                                                     # Pop
 {my ($n) = @_;
  my $a = newArray($n);
  for(reverse 0..$n-1)
   {ok $a->pop == $_;
    ok $a->size == $_;
    checkWidth($a);
   }
  ok !defined($a->pop);
  checkWidth($a);
 } # pops

sub shifts($)                                                                   # Shift
 {my ($n) = @_;
  my $a = newArray($n);
  for(0..$n-1)
   {ok $a->shift == $_;
    ok $a->size == $n - $_ - 1;
    checkWidth($a);
   }
  ok !defined($a->pop);
  checkWidth($a);
 } # shifts

my @times = ([qw(inUse pp size width time)]);                                   # Times table

if (1)                                                                          # Documentation test
 {my $a = Binary::Heap::Array::new(ipsw);

  $a->push(1)->push(2);
  ok $a->size   == 2;
  ok $a->at( 0) == 1;
  ok $a->at( 1) == 2;
  ok $a->at(-1) == 2;
  ok $a->at(-2) == 1;
     $a->at( 0)  = 2;
  ok $a->at(-2) == 2;
  ok $a->pop    == 2;
  ok $a->size   == 1;
  ok $a->shift  == 2;
  ok $a->size   == 0;
  $a->unshift(3);
  ok $a->size   == 1;
  $a->unshift(2);
  ok $a->size   == 2;
  $a->unshift(1);
  ok $a->size   == 3;
 }

for(@optimisations)
 {$speed = $_;                                                                  # The package to use
  my $package = newArray(0);                                                    # Example of the package
  my $startTime = time;                                                         # Start time of sequence

  if (1)                                                                        # Long tests
   {my @ops = qw(1 676 83 8 38 47 0 39 4893 75 979 90 34 2 2 4 88 30 34 97 93 98 981 33 93 938 8 58 934 33 4 3 43 823 42 3 149 99 43 33  83 83 89 349 34382 47 39 45 7 9 7 2 4 8 3 8 5 0 7 3 5 7 4 3 8 1 9 9 6 7 2 6 2 3 -10 6 5 3 4 5 7 8 0 1 6 7 1 9 5 5 6 7 8 7 0 6 2 1 2 4 2 -12 9 6 6 1 4 7 0 4 3 3 6 5 5 6 7 0 8 4 4 2 0 7 0 5 5 7 0 5 5 -22 8 1 6 0 8 1 1 4 1 1 6 4 6 6 4 2 6 7 4 2 1 5 4 0 5 3 -10 3 1 9 1 1 2 9 8 1 0 5 9 2 2 5 7 4 6 6 6 -1 4 2 4 1 3 5 6 4 5 3 6 6 7 -22 1 8 7 2 8 7 8 2 0 0 1 7 2 1 1 8 3 2 3 5 9 9 -13 3 9 7 4 0 5 6 1 1 0 3 4 6 3 7 2 6 0 7 3 9 1 1 4 7 5 9 5 2 1 8 1 3 2 6 0 8 9 5 1 1 6 5 7 4 3 7 5 2 1 9 3 9 7 8 2 5 1 5 2 0 8 2 6 4 6 4 2 7 4 0 2 7 4 0 3 5 5 7 -40 5 3 6 5 8 1 0 7 5 2 1 9 8 1 9 7 4 8 6 3 8 1 0 8 0 9 4 1 9 7 2 6 8 1 5 9 5 6 0 7 7 1 9 3 8 7 0 5 5 9 4 1 7 6 8 5 9 3 0 6 4 3 9 2 3 4 2 1 9 7 6 8 4 7 5 9 7 9 8 5 4 0 4 0 8 4 8 1 8 2 1 8 8 0 6 1 1 3 9 0 7 9 4 8 0 5 6 7 7 4 7 7 1 0 1 9 9 1 6 6 5 1 6 7 3 1 5 3 5 7 6 7 1 6 4 8 5 2 9 1 9 3 1 8 6 8 6 6 9 3 0 2 0 8 2 6 -78 2 0 1 9 0 8 1 8 6 3 7 8 9 1 6 3 9 3 4 6 9 2 7 8 1 0 0 1 6 8 7 0 1 1 0 1 5 2 4 3 1 7 5 4 2 7 2 6 1 7 6 2 0 4 1 8 5 6 4 3 8 6 5 3 9 3 2 4 3 8 6 8 6 9 1 1 5 4 9 2 7 9 3 5 1 6 8 4 8 9 4 3 4 1 0 1 4 2 5 5 7 5 4 8 0 4 7 3 9 7 2 1 4 9 1 2 1 0 3 5 4 5 8 5 2 4 2 1 6 0 7 6 0 8 8 6 7 4 0 4 5 5 1 6 8 5 2 8 -99  2 5 1 3 2 3 3 2 5 6 0 9 2 1 4 0 3 5 6 8 2 0 2 1 6 4 3 0 3 4 3 5 2 2 2 6 6 8 6 0 5 6 8 3 4 4 6 4 8 5 7 1 1 9 1 6 7 1 7 3 3 7 0 8 1 4 2 4 7 7 9 9 3 3 8 1 3 3 2 5 5 -21 2 8 1 1 0 4 1 0 3 0 8 9 3 5 1 1 6 0 4 8 6 4 3 0 3 3 9 0 6 7 2 8 8 4 7 5 7 3 1 8 2 9 7 7 4 4 3 3 7 9 2 3 4 1 0 6 1 4 9 6 0 7 8 4 9 5 1 8 2 4 3 3 8 1 3 2 3 9 0 5 7 9 2 8 4 4 2 7 2 3 4 1 8 4 4 1 0 3 9 1 7 0 7 7 6 9 3 6 2 9 8 9 2 4 6 8 4 6 2 7 7 3 4 3 5 8 1 7 6 4 8 9 9 1 6 6 7 8 4 4 1 5 0 0 0 -111 2 4 4 1 0 1 5 5 8 9 9 9 4 7 1 3 6 8 7 3 8 5 2 7 2 4 3 3 9 2 4 8 9 2 2 6 1 6 1 4 0 0 7 4 8 6 5 5 2 6 7 5 0 6 1 2 2 5 6 0 -45 2 3 8 4 0 9 1 4 6 9 8 3 8 7 9 3 2 2 2 9 3 5 9 7 9 0 3 5 1 4 0 1 8 9 0 1 5 -33 7 8 6 0 6 4 0 6 0 5 6 0 9 3 1 0 6 3 6 8 4 7 5 0 1 8 4 1 3 8 8 1 5 0 5 4 7 0 5 3 6 6 0 7 6 9 2 4 1 8 3 6 7 2 6 8 1 9 8 0 1 9 9 6 5 2 6 1 -121 7 0 0 8 5 6 3 3 9 3 1 7 5 1 2 2 4 9 0 8 7 4 2 0 8 0 0 1 7 6 4 3 8 1 6 9 4 9 5 0 -23 4 9 2 3 2 0 0 5 5 2 7 1 2 7 2 5 0 9 7 2 5);
    my $maxSize = 0;                                                            # Maximum size array built
    my $a = newArray(0);                                                        # Our    version of an array
    my @a;                                                                      # Perl's version of an array
    my $nop = 0;                                                                # Operation count

    while(@ops > 1)
     {my $s = CORE::shift(@ops) %  4;
      my $n = CORE::shift(@ops) % 16;
      ++$nop;
      if ($s == 0)
       {say STDERR "AAAA $nop push $a" if debug;
        for(1..$n)
         {CORE::push @a, $_;    $a->push($_);
         }
        say STDERR "BBBB push size=", $a->size if debug;
       }
      elsif ($s == 1)
       {say STDERR "AAAA $nop for $n unshift $a" if debug;
        for(1..$n)
         {CORE::unshift @a, $_; $a->unshift($_);
         }
        say STDERR "BBBB unshift size=", $a->size if debug;
       }
      elsif ($s == 2)
       {say STDERR "AAAA $nop for $n pop $a" if debug;
        for(1..$n)
         {my ($i, $j) = ($a->pop, CORE::pop(@a));
          ok ((!defined($i) && !defined($j)) || $i == $j);
         }
        say STDERR "BBBB pop size=", $a->size if debug;
       }
      elsif ($s == 3)
       {say STDERR "AAAA $nop for $n shift $a" if debug;
        for(1..$n)
         {my ($i, $j) = ($a->shift, CORE::shift(@a));
          ok ((!defined($i) && !defined($j)) || $i == $j);
         }
        say STDERR "BBBB shift size=", $a->size if debug;
       }

      ok $a->size == @a;                                                        # Compare with perl array
      if ($nop % 32 == 0)
       {ok $a->at($_) == $a[$_]   for 0..$#a;
        ok $a->size == @$a;                                                     # Compare with generated array
        ok $a->at($_) == $a->[$_] for 0..$#a;
       }

      $maxSize = @$a > $maxSize ? @$a : $maxSize;
     }
    ok $maxSize == 486;
   }

  for(1..256)                                                                   # All components of the array are a power of two wide so they fit well in a buddy system
   {my $a = newArray($_);
    ok $a->size == $_;
   }

  ats($_) for (0..11, 29, 51, 127, 256);                                        # At

  if (1)                                                                        # Mixed
   {my $a = newArray(0);

    $a->push(1)->push(2);
    ok $a->size   == 2;
    ok $a->at( 0) == 1;
    ok $a->at( 1) == 2;
    ok $a->at(-1) == 2;
    ok $a->at(-2) == 1;
       $a->at( 0)  = 2;
    ok $a->at(-2) == 2;
    ok $a->pop    == 2;
    ok $a->size   == 1;
    ok $a->shift  == 2;
    ok $a->size   == 0;
    $a->unshift(3);
    ok $a->size   == 1;
    $a->unshift(2);
    ok $a->size   == 2;
    $a->unshift(1);
    ok $a->size   == 3;
   }

  if (1)                                                                        # As array
   {my $i = 0;
    ok $_ == $i++ for @{newArray(9)};
   }

  pops(227);                                                                    # Pop

  if (1)                                                                        # Shift/pop small
   {my $a = newArray(3);
    ok $a->shift == 0;
    ok $a->at(1) == 2;
    ok $a->at(0) == 1;
    ok $a->pop   == 2;
    ok $a->size  == 1;
    ok $a->at(0) == 1;
    ok $a->shift == 1;
    ok $a->size  == 0;
   }

  shifts(257);                                                                  # Shift

  if (1)                                                                        # Shift/pop big
   {my $a = newArray(1025);
    ok $a->at(1000) == 1000;
    ok $a->shift    ==    0;
    ok $a->at(1000) == 1001;
   }

  if (1)                                                                        # Pop multiple
   {my $N = 1025;
    my $a = newArray($N);
    for(1..$N)
     {my @a;
      CORE::push @a, $a->pop;
      $a->push(CORE::pop @a);
      ok $a->at($N-1) == $N-1;
     }
   }

  if (1)                                                                        # Shift multiple
   {for my $N(1..9)
     {my $a = newArray($N);
      for(1..$N)
       {$a->push($a->shift);
        ok $a->size == $N;
       }
      ok $a eq newArray($N);
     }
   }
  push @times, [$package->speedInUse, $package->speedPp, $package->speedSize,
                $package->speedWidth, sprintf("%5.2f", time() - $startTime)];
 }

say STDERR "\n", formatTable([@times]);                                         # Write timing information

1
__END__
    inUse  pp  size  width  time
 1      0   0     0      0  16.74
 2      1   0     0      0   9.96
 3      0   1     0      0   1.88
 4      1   1     0      0   1.29
 5      0   0     1      0  14.44
 6      1   0     1      0   8.57
 7      0   1     1      0   1.73
 8      1   1     1      0   1.22
 9      0   0     0      1  14.04
10      1   0     0      1   9.23
11      0   1     0      1   2.03
12      1   1     0      1   1.35
13      0   0     1      1  12.08
14      1   0     1      1   8.44
15      0   1     1      1   1.52
16      1   1     1      1   1.18
