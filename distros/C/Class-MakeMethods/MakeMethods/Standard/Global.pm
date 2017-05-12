=head1 NAME

Class::MakeMethods::Standard::Global - Global data

=head1 SYNOPSIS

  package MyClass;
  use Class::MakeMethods::Standard::Global (
    scalar => [ 'foo' ],
    array  => [ 'my_list' ],
    hash   => [ 'my_index' ],
  );
  ...
  
  MyClass->foo( 'Foozle' );
  print MyClass->foo();

  print MyClass->new(...)->foo(); # same value for any instance
  print MySubclass->foo();        # ... and for any subclass
  
  MyClass->my_list(0 => 'Foozle', 1 => 'Bang!');
  print MyClass->my_list(1);
  
  MyClass->my_index('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  print MyClass->my_index('foo');


=head1 DESCRIPTION

The Standard::Global suclass of MakeMethods provides basic accessors for shared data.

=head2 Calling Conventions

When you C<use> this package, the method names you provide
as arguments cause subroutines to be generated and installed in
your module.

See L<Class::MakeMethods::Standard/"Calling Conventions"> for more information.

=head2 Declaration Syntax

To declare methods, pass in pairs of a method-type name followed
by one or more method names. 

Valid method-type names for this package are listed in L<"METHOD
GENERATOR TYPES">.

See L<Class::MakeMethods::Standard/"Declaration Syntax"> and L<Class::MakeMethods::Standard/"Parameter Syntax"> for more information.

=cut

package Class::MakeMethods::Standard::Global;

$VERSION = 1.000;
use strict;
use Class::MakeMethods::Standard '-isasubclass';
use Class::MakeMethods::Utility::ArraySplicer 'array_splicer';

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 scalar - Global Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, and behaves identically regardless of what it was called on.

=item *

If called without any arguments returns the current value.

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Standard::Global (
    scalar => 'foo',
  );
  ...
  
  # Store value
  MyClass->foo('Foozle');
  
  # Retrieve value
  print MyClass->foo;

=cut

sub scalar {
  map { 
    my $name = $_->{name};
    my $data;
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	$data;
      } else {
	$data = shift;
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 array - Global Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, and behaves identically regardless of what it was called on.

=item * 

The global value will be a reference to an array (or undef).

=item *

If called without any arguments, returns the current array-ref value (or undef).


=item *

If called with a single non-ref argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef).

=item *

If called with a single array ref argument, uses that list to return a slice of the referenced array.

=item *

If called with a list of argument pairs, each with a non-ref index and an associated value, stores the value at the given index in the referenced array. If the global value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

=item *

If called with a list of argument pairs, each with the first item being a reference to an array of up to two numbers, loops over each pair and uses those numbers to splice the value array. 

The first controlling number is the position at which the splice will begin. Zero will start before the first item in the list. Negative numbers count backwards from the end of the array. 

The second number is the number of items to be removed from the list. If it is omitted, or undefined, or zero, no items are removed. If it is a positive integer, that many items will be returned.

If both numbers are omitted, or are both undefined, they default to containing the entire value array.

If the second argument is undef, no values will be inserted; if it is a non-reference value, that one value will be inserted; if it is an array-ref, its values will be copied.

The method returns the items that removed from the array, if any.

=back

Sample declaration and usage:
  
  package MyClass;
  use Class::MakeMethods::Standard::Global (
    array => 'bar',
  );
  ...
  
  # Clear and set contents of list
  print MyClass->bar([ 'Spume', 'Frost' ] );  
  
  # Set values by position
  MyClass->bar(0 => 'Foozle', 1 => 'Bang!');
  
  # Positions may be overwritten, and in any order
  MyClass->bar(2 => 'And Mash', 1 => 'Blah!');
  
  # Retrieve value by position
  print MyClass->bar(1);
  
  # Direct access to referenced array
  print scalar @{ MyClass->bar() };

There are also calling conventions for slice and splice operations:

  # Retrieve slice of values by position
  print join(', ', MyClass->bar( undef, [0, 2] ) );
  
  # Insert an item at position in the array
  MyClass->bar([3], 'Potatoes' );  
  
  # Remove 1 item from position 3 in the array
  MyClass->bar([3, 1], undef );  
  
  # Set a new value at position 2, and return the old value 
  print MyClass->bar([2, 1], 'Froth' );

=cut

sub array {
  map { 
    my $name = $_->{name};
    my $data;
    my $init = $_->{auto_init};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	if ( $init and ! defined $data ) {
	  $data = [];
	}
	! $data ? () : wantarray ? @$data : $data;
      } elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
	$data = [ @{ $_[0] } ];
	wantarray ? @$data : $data;
      } else {
	$data ||= [];
	return array_splicer( $data, @_ );
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 hash - Global Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, and behaves identically regardless of what it was called on.

=item * 

The global value will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the contents of the hash in list context, or a hash reference in scalar context (or undef).

=item *

If called with one non-ref argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef).

=item *

If called with one array-ref argument, uses the contents of that array to retrieve a slice of the referenced hash.

=item *

If called with one hash-ref argument, sets the contents of the referenced hash to match that provided.

=item *

If called with a list of key-value pairs, stores the value under the given key in the referenced hash. If the global value was previously undefined, a new hash is autovivified. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the contents of the hash in list context, or a hash reference in scalar context.

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Standard::Global (
    hash => 'baz',
  );
  ...
  
  # Set values by key
  MyClass->baz('foo' => 'Foozle', 'bar' => 'Bang!');
  
  # Values may be overwritten, and in any order
  MyClass->baz('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  
  # Retrieve value by key
  print MyClass->baz('foo');
  
  # Retrive slice of values by position
  print join(', ', MyClass->baz( ['foo', 'bar'] ) );
  
  # Direct access to referenced hash
  print keys %{ MyClass->baz() };
  
  # Reset the hash contents to empty
  @{ MyClass->baz() } = ();

=cut

sub hash {
  map { 
    my $name = $_->{name};
    my $data;
    my $init = $_->{auto_init};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	if ( $init and ! defined $data ) {
	  $data = {};
	}
	! $data ? () : wantarray  ? %$data : $data
      } elsif ( scalar(@_) == 1 ) {
	if ( ref($_[0]) eq 'HASH' ) {
	  my $hash = shift;
	  $data = { %$hash };
	} elsif ( ref($_[0]) eq 'ARRAY' ) {
	  return @{$data}{ @{$_[0]} }
	} else {
	  return $data->{ $_[0] }
	}
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  my $key = shift();
	  $data->{ $key } = shift();
	}
	wantarray ? %$data : $data;
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 object - Global Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, and behaves identically regardless of what it was called on.

=item * 

The global value will be a reference to an object (or undef).

=item *

If called without any arguments returns the current value.

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Standard::Global (
    object => 'foo',
  );
  ...
  
  # Store value
  MyClass->foo( Foozle->new() );
  
  # Retrieve value
  print MyClass->foo;

=cut

sub object {
  map { 
    my $name = $_->{name};
    my $data;
    my $class = $_->{class};
    my $init = $_->{auto_init};
    if ( $init and ! $class ) { 
      Carp::croak("Use of auto_init requires value for class parameter") 
    }
    my $new_method = $_->{new_method} || 'new';
    $name => sub {
      my $self = shift;
      if ( scalar @_ ) {
	my $value = shift;
	if ( $class and ! UNIVERSAL::isa( $value, $class ) ) {
	  Carp::croak "Wrong argument type ('$value') in assigment to $name";
	}
	$data = $value;
      } else {
	if ( $init and ! defined $data ) {
	  $data = $class->$new_method();
	}
	$data;
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Standard> for more about this family of subclasses.

=cut

1;
