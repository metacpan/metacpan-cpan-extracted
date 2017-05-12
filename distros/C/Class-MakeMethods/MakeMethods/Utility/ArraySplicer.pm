=head1 NAME

Class::MakeMethods::Utility::ArraySplicer - Common array ops

=head1 SYNOPSIS

  use Class::MakeMethods::Utility::ArraySplicer;
  
  # Get one or more values
  $value = array_splicer( $array_ref, $index );
  @values = array_splicer( $array_ref, $index_array_ref );
  
  # Set one or more values
  array_splicer( $array_ref, $index => $new_value, ... );
  
  # Splice selected values in or out
  array_splicer( $array_ref, [ $start_index, $end_index], [ @values ]);

=head1 DESCRIPTION

This module provides a utility function and several associated constants which support a general purpose array-splicer interface, used by several of the Standard and Composite method generators.

=cut

########################################################################

package Class::MakeMethods::Utility::ArraySplicer;

$VERSION = 1.000;

@EXPORT_OK = qw( 
  array_splicer
  array_set array_clear array_push array_pop array_unshift array_shift
);
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

use strict;

########################################################################

=head2 array_splicer

This is a general-purpose array accessor function. Depending on the arguments passed to it, it will get, set, slice, splice, or otherwise modify your array.

=over 4

=item *

If called without any arguments, returns the contents of the array in list context, or an array reference in scalar context (or undef).

  # Get all values
  $value_ref = array_splicer( $array_ref );
  @values = array_splicer( $array_ref );

=item *

If called with a single numeric argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef).

  # Get one value
  $value = array_splicer( $array_ref, $index );

=item *

If called with a single array ref argument, sets the contents of the array to match the contents of the provided one.

  # Set contents of array
  array_splicer( $array_ref, [ $value1, $value2, ... ] );

  # Reset the array contents to empty
  array_splicer( $array_ref, [] );

=item *

If called with a two arguments, the first undefined and the second an array ref argument, uses that array's contents as a list of indexes to return a slice of the referenced array.

  # Get slice of values
  @values = array_splicer( $array_ref, undef, [ $index1, $index2, ... ] );

=item *

If called with a list of argument pairs, each with a numeric index and an associated value, stores the value at the given index in the referenced array. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

  # Set one or more values by index
  array_splicer( $array_ref, $index1 => $value1, $index2 => $value2, ... );

=item *

If called with a list of argument pairs, each with the first item being a reference to an array of up to two numbers, loops over each pair and uses those numbers to splice the value array. 

  # Splice selected values in or out
  array_splicer( $array_ref, [ $start_index, $count], [ @values ]);

The first controlling number is the position at which the splice will begin. Zero will start before the first item in the list. Negative numbers count backwards from the end of the array. 

The second number is the number of items to be removed from the list. If it is omitted, or undefined, or zero, no items are removed. If it is a positive integer, that many items will be returned.

If both numbers are omitted, or are both undefined, they default to containing the entire value array.

If the second argument is undef, no values will be inserted; if it is a non-reference value, that one value will be inserted; if it is an array-ref, its values will be copied.

The method returns the items that removed from the array, if any.

Here are some examples of common splicing operations.

  # Insert an item at position in the array
  $obj->bar([3], 'Potatoes' );  
  
  # Remove 1 item from position 3 in the array
  $obj->bar([3, 1], undef );  
  
  # Set a new value at position 2, and return the old value 
  print $obj->bar([2, 1], 'Froth' );

  # Unshift an item onto the front of the list
  array_splicer( $array_ref, [0], 'Bubbles' );

  # Shift the first item off of the front of the list
  print array_splicer( $array_ref, [0, 1], undef );

  # Push an item onto the end of the list
  array_splicer( $array_ref, [undef], 'Bubbles' );

  # Pop the last item off of the end of the list
  print array_splicer( $array_ref, [undef, 1], undef );

=back

=cut

sub array_splicer {
  my $value_ref = shift;
  
  # RETRIEVE VALUES
  if ( scalar(@_) == 0 ) {
    return wantarray ? @$value_ref : $value_ref;
  
  # FETCH BY INDEX
  } elsif ( scalar(@_) == 1 and length($_[0]) and ! ref($_[0]) and $_[0] !~ /\D/) {
    $value_ref->[ $_[0] ]
  
  # SET CONTENTS
  } elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
    @$value_ref = @{ $_[0] };
    return wantarray ? @$value_ref : $value_ref;
    
  # ASSIGN BY INDEX
  } elsif ( ! ( scalar(@_) % 2 ) and ! grep { ! ( length($_) and ! ref($_) and $_ !~ /\D/ ) } map { $_[$_] } grep { ! ( $_ % 2 ) } ( 0 .. $#_ ) ) {
    while ( scalar(@_) ) {
      my $key = shift();
      $value_ref->[ $key ] = shift();
    }
    $value_ref;

  # SLICE
  } elsif ( ! scalar(@_) == 2 and ! defined $_[0] and ref $_[1] eq 'ARRAY' ) {
    @{$value_ref}[ @{ $_[1] } ]
  
  # SPLICE
  } elsif ( ! scalar(@_) % 2 and ref $_[0] eq 'ARRAY' ) {
    my @results;
    while ( scalar(@_) ) {
      my $key = shift();
      my $value = shift();
      my @values = ! ( $value ) ? () : ! ref ( $value ) ? $value : @$value;
      my $key_v = $key->[0];
      my $key_c = $key->[1];
      if ( defined $key_v ) {
	if ( $key_c ) {
	  # straightforward two-value splice
	} else {
	  # insert at position
	  $key_c = 0;
	}
      } else {
	if ( ! defined $key_c ) {
	  # target the entire list
	  $key_v = 0;
	  $key_c = scalar @$value_ref;
	} elsif ( $key_c ) {
	  # take count items off the end
	  $key_v = - $key_c
	} else {
	  # insert at the end
	  $key_v = scalar @$value_ref;
	  $key_c = 0;
	}
      }
      push @results, splice @$value_ref, $key_v, $key_c, @values
    }
    ( ! wantarray and scalar @results == 1 ) ? $results[0] : @results;
    
  } else {
    Carp::confess 'Unexpected arguments to array accessor: ' . join(', ', map "'$_'", @_ );
  }
}

########################################################################

=head2 Constants

There are also constants symbols to facilitate some common combinations of splicing arguments:

  # Reset the array contents to empty
  array_splicer( $array_ref, array_clear );
  
  # Set the array contents to provided values
  array_splicer( $array_ref, array_splice, [ 2, 3 ] );
  
  # Unshift an item onto the front of the list
  array_splicer( $array_ref, array_unshift, 'Bubbles' );
  
  # Shift it back off again
  print array_splicer( $array_ref, array_shift );
  
  # Push an item onto the end of the list
  array_splicer( $array_ref, array_push, 'Bubbles' );
  
  # Pop it back off again
  print array_splicer( $array_ref, array_pop );

=cut

use constant array_splice => undef;
use constant array_clear => ( [] );

use constant array_push => [undef];
use constant array_pop => ( [undef, 1], undef );

use constant array_unshift => [0];
use constant array_shift => ( [0, 1], undef );

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Standard::Hash> and numerous other classes for
examples of usage.

=cut

1;
