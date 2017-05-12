=head1 NAME

Class::MakeMethods::Standard::Array - Methods for Array objects 

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Standard::Array (
    new => 'new',
    scalar => [ 'foo', 'bar' ],
    array => 'my_list',
    hash => 'my_index',
  );
  ...
  
  my $obj = MyObject->new( foo => 'Foozle' );
  print $obj->foo();
  
  $obj->bar('Barbados');
  print $obj->bar();
  
  $obj->my_list(0 => 'Foozle', 1 => 'Bang!');
  print $obj->my_list(1);
  
  $obj->my_index('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  print $obj->my_index('foo');

=head1 DESCRIPTION

The Standard::Array suclass of MakeMethods provides a basic
constructor and accessors for blessed-array object instances.

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

package Class::MakeMethods::Standard::Array;

$VERSION = 1.000;
use strict;
use Class::MakeMethods::Standard '-isasubclass';
use Class::MakeMethods::Utility::ArraySplicer 'array_splicer';

########################################################################

=head2 Positional Accessors and %FIELDS

Each accessor method is assigned the next available array index at
which to store its value.

The mapping between method names and array positions is stored in
a hash named %FIELDS in the declaring package. When a package
declares its first positional accessor, its %FIELDS are initialized
by searching its inheritance tree.

B<Warning>: Subclassing packages that use positional accessors is
somewhat fragile, since you may end up with two distinct methods assigned to the same position. Specific cases to avoid are:

=over 4

=item *

If you inherit from more than one class with positional accessors,
the positions used by the two sets of methods will overlap.

=item *

If your superclass adds additional positional accessors after you
declare your first, they will overlap yours.

=back

=cut

sub _array_index {
  my $class = shift;
  my $name = shift;
  no strict;
  local $^W = 0;
  if ( ! scalar %{$class . "::FIELDS"} ) {
    my @classes = @{$class . "::ISA"};
    my @fields;
    while ( @classes ) {
      my $superclass = shift @classes;
      if ( scalar %{$superclass . "::FIELDS"} ) {
	push @fields, %{$superclass . "::FIELDS"};
      } else {
	unshift @classes, @{$superclass . "::ISA"}
      }
    }
    %{$class . "::FIELDS"} = @fields
  }
  my $field_hash = \%{$class . "::FIELDS"};
  $field_hash->{$name} or $field_hash->{$name} = scalar keys %$field_hash
}

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 new - Constructor

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Has a reference to a sample item to copy. This defaults to a reference to an empty array, but you may override this with the C<'defaults' => I<array_ref>> method parameter. 

=item *

If called as a class method, makes a new array containing values from the sample item, and blesses it into that class.

=item *

If called on an array-based instance, makes a copy of it and blesses the copy into the same class as the original instance.

=item *

If passed a list of method-value pairs, calls each named method with the associated value as an argument. 

=item *

Returns the new instance.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Array (
    new => 'new',
  );
  ...
  
  # Bare constructor
  my $empty = MyObject->new();
  
  # Constructor with initial sequence of method calls
  my $obj = MyObject->new( foo => 'Foozle', bar => 'Barbados' );
  
  # Copy with overriding sequence of method calls
  my $copy = $obj->new( bar => 'Bob' );

=cut

sub new {
  my $class = shift;
  map { 
    my $name = $_->{name};
    my $defaults = $_->{defaults} || [];
    $name => sub {
      my $callee = shift;
      my $self = ref($callee) ? bless( [@$callee], ref($callee) ) 
			      : bless( [@$defaults],   $callee );
      while ( scalar @_ ) {
	my $method = shift;
	$self->$method( shift );
      }
      return $self;
    }
  } $class->_get_declarations(@_)
}

########################################################################

=head2 scalar - Instance Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value. This defaults to the next available slot in %FIELDS, but you may override this with the C<'array_index' => I<number>> method parameter, or by pre-filling the contents of %FIELDS. 

=item *

If called without any arguments returns the current value (or undef).

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Array (
    scalar => 'foo',
  );
  ...
  
  # Store value
  $obj->foo('Foozle');
  
  # Retrieve value
  print $obj->foo;

=cut

sub scalar {
  my $class = shift;
  map { 
    my $name = $_->{name};
    my $index = $_->{array_index} || 
		_array_index( $class->_context('TargetClass'), $name );
    $name => sub {
      my $self = shift;
      if ( scalar @_ ) {
	$self->[$index] = shift;
      } else {
	$self->[$index];
      }
    }
  } $class->_get_declarations(@_)
}

########################################################################

=head2 array - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value. This defaults to the next available slot in %FIELDS, but you may override this with the C<'array_index' => I<number>> method parameter, or by pre-filling the contents of %FIELDS. 

=item * 

The value for each instance will be a reference to an array (or undef).

=item *

If called without any arguments, returns the current array-ref value (or undef).

=item *

If called with a single non-ref argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef).

=item *

If called with a single array ref argument, uses that list to return a slice of the referenced array.

=item *

If called with a list of argument pairs, each with a non-ref index and an associated value, stores the value at the given index in the referenced array. If the instance's value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

=item *

If called with a list of argument pairs, each with the first item being a reference to an array of up to two numbers, loops over each pair and uses those numbers to splice the value array. 

The first controlling number is the position at which the splice will begin. Zero will start before the first item in the list. Negative numbers count backwards from the end of the array. 

The second number is the number of items to be removed from the list. If it is omitted, or undefined, or zero, no items are removed. If it is a positive integer, that many items will be returned.

If both numbers are omitted, or are both undefined, they default to containing the entire value array.

If the second argument is undef, no values will be inserted; if it is a non-reference value, that one value will be inserted; if it is an array-ref, its values will be copied.

The method returns the items that removed from the array, if any.

=back

Sample declaration and usage:
  
  package MyObject;
  use Class::MakeMethods::Standard::Array (
    array => 'bar',
  );
  ...
  
  # Clear and set contents of list
  print $obj->bar([ 'Spume', 'Frost' ] );  
  
  # Set values by position
  $obj->bar(0 => 'Foozle', 1 => 'Bang!');
  
  # Positions may be overwritten, and in any order
  $obj->bar(2 => 'And Mash', 1 => 'Blah!');
  
  # Retrieve value by position
  print $obj->bar(1);
  
  # Direct access to referenced array
  print scalar @{ $obj->bar() };

There are also calling conventions for slice and splice operations:

  # Retrieve slice of values by position
  print join(', ', $obj->bar( undef, [0, 2] ) );
  
  # Insert an item at position in the array
  $obj->bar([3], 'Potatoes' );  
  
  # Remove 1 item from position 3 in the array
  $obj->bar([3, 1], undef );  
  
  # Set a new value at position 2, and return the old value 
  print $obj->bar([2, 1], 'Froth' );

=cut

sub array {
  my $class = shift;
  map { 
    my $name = $_->{name};
    my $index = $_->{array_index} || 
		_array_index( $class->_context('TargetClass'), $name );
    my $init = $_->{auto_init};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	if ( $init and ! defined $self->[$index] ) {
	  $self->[$index] = [];
	}
	( ! $self->[$index] ) ? () : 
	( wantarray            ) ? @{ $self->[$index] } :
				   $self->[$index]
      } elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
	$self->[$index] = [ @{ $_[0] } ];
	( ! $self->[$index] ) ? () : 
	( wantarray            ) ? @{ $self->[$index] } :
				   $self->[$index]
      } else {
	$self->[$index] ||= [];
	array_splicer( $self->[$index], @_ );
      }
    }
  } $class->_get_declarations(@_)
}

########################################################################

=head2 hash - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value. This defaults to the next available slot in %FIELDS, but you may override this with the C<'array_index' => I<number>> method parameter, or by pre-filling the contents of %FIELDS. 


=item * 

The value for each instance will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the contents of the hash in list context, or a hash reference in scalar context (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef). If the single argument is an array ref, then a slice of the referenced hash is returned.

=item *

If called with a list of key-value pairs, stores the value under the given key in the referenced hash. If the instance's value was previously undefined, a new hash is autovivified. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the contents of the hash in list context, or a hash reference in scalar context.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Array (
    hash => 'baz',
  );
  ...
  
  # Set values by key
  $obj->baz('foo' => 'Foozle', 'bar' => 'Bang!');
  
  # Values may be overwritten, and in any order
  $obj->baz('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  
  # Retrieve value by key
  print $obj->baz('foo');
  
  # Retrive slice of values by position
  print join(', ', $obj->baz( ['foo', 'bar'] ) );
  
  # Direct access to referenced hash
  print keys %{ $obj->baz() };
  
  # Reset the hash contents to empty
  @{ $obj->baz() } = ();

=cut

sub hash {
  my $class = shift;
  map { 
    my $name = $_->{name};
    my $index = $_->{array_index} || 
		_array_index( $class->_context('TargetClass'), $name );
    my $init = $_->{auto_init};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	if ( $init and ! defined $self->[$index] ) {
	  $self->[$index] = {};
	}
	( ! $self->[$index] ) ? () : 
	( wantarray            ) ? %{ $self->[$index] } :
				   $self->[$index]
      } elsif ( scalar(@_) == 1 ) {
	if ( ref($_[0]) eq 'HASH' ) {
	  my $hash = shift;
	  $self->[$index] = { %$hash };
	} elsif ( ref($_[0]) eq 'ARRAY' ) {
	  return @{$self->[$index]}{ @{$_[0]} }
	} else {
	  return $self->[$index]->{ $_[0] }
	}
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  my $key = shift();
	  $self->[$index]->{ $key } = shift();
	}
	( wantarray            ) ? %{ $self->[$index] } :
				   $self->[$index]
      }
    }
  } $class->_get_declarations(@_)
}

########################################################################

=head2 object - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value. This defaults to the next available slot in %FIELDS, but you may override this with the C<'array_index' => I<number>> method parameter, or by pre-filling the contents of %FIELDS. 

=item * 

The value for each instance will be a reference to an object (or undef).

=item *

If called without any arguments returns the current value.

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Hash (
    object => 'foo',
  );
  ...
  
  # Store value
  $obj->foo( Foozle->new() );
  
  # Retrieve value
  print $obj->foo;

=cut

sub object {
  my $class = shift;
  map { 
    my $name = $_->{name};
    my $index = $_->{array_index} || 
		_array_index( $class->_context('TargetClass'), $name );
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
	$self->[$index] = $value;
      } else {
	if ( $init and ! defined $self->[$index] ) {
	  $self->[$index] = $class->$new_method();
	} else {
	  $self->[$index];
	}
      }
    }
  } $class->_get_declarations(@_)
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Standard> for more about this family of subclasses.

See L<Class::MakeMethods::Standard::Hash> for equivalent functionality
based on blessed hashes. If your module will be extensively
subclassed, consider switching to Standard::Hash to avoid the
subclassing concerns described above.

=cut

1;
