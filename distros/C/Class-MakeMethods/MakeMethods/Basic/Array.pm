=head1 NAME

Class::MakeMethods::Basic::Array - Basic array methods

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Basic::Array (
    new => 'new',
    scalar => [ 'foo', 'bar' ],
    array => 'my_list',
    hash => 'my_index',
  );
  ...
  
  # Constructor
  my $obj = MyObject->new( foo => 'Foozle' );
  
  # Scalar Accessor
  print $obj->foo();
  
  $obj->bar('Barbados');
  print $obj->bar();
  
  # Array accessor
  $obj->my_list(0 => 'Foozle', 1 => 'Bang!');
  print $obj->my_list(1);
  
  # Hash accessor
  $obj->my_index('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  print $obj->my_index('foo');


=head1 DESCRIPTION

The Basic::Array subclass of MakeMethods provides a basic
constructor and accessors for blessed-array object instances.

=head2 Calling Conventions

When you C<use> this package, the method names you provide
as arguments cause subroutines to be generated and installed in
your module.

See L<Class::MakeMethods::Basic/"Calling Conventions"> for a summary, or L<Class::MakeMethods/"USAGE"> for full details.

=head2 Declaration Syntax

To declare methods, pass in pairs of a method-type name followed
by one or more method names. Valid method-type names for this
package are listed in L<"METHOD GENERATOR TYPES">.

See L<Class::MakeMethods::Basic/"Declaration Syntax"> for more
syntax information.

=cut

package Class::MakeMethods::Basic::Array;

$VERSION = 1.000;
use strict;
use Class::MakeMethods '-isasubclass';

########################################################################

=head2 About Positional Accessors

Each accessor method claims the next available spot in the array
to store its value in.

The mapping between method names and array positions is stored in
a hash named %FIELDS in the target package. When the first positional
accessor is defined for a package, its %FIELDS are initialized by
searching its inheritance tree.

B<Caution>: Subclassing packages that use positional accessors is
somewhat fragile, since you may end up with two distinct methods
assigned to the same position. Specific cases to avoid are:

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

If called as a class method, makes a new array and blesses it into that class.

=item *

If called on an array-based instance, makes a copy of it and blesses the copy into the same class as the original instance.

=item *

If passed a list of method-value pairs, calls each named method with the associated value as an argument. 

=item *

Returns the new instance.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Array (
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
    my $name = $_;
    $name => sub {
      my $callee = shift;
      my $self = ref($callee) ? bless( [@$callee], ref($callee) ) 
			      : bless( [], $callee );
      while ( scalar @_ ) {
	my $method = shift;
	$self->$method( shift );
      }
      return $self;
    }
  } @_;
}

########################################################################

=head2 scalar - Instance Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value.

=item *

If called without any arguments returns the current value (or undef).

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Array (
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
    my $name = $_;
    my $index = _array_index( $class->_context('TargetClass'), $name );
    $name => sub {
      my $self = shift;
      if ( scalar @_ ) {
	$self->[$index] = shift;
      } else {
	$self->[$index];
      }
    }
  } @_;
}

########################################################################

=head2 array - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value.

=item * 

The value for each instance will be a reference to an array (or undef).

=item *

If called without any arguments, returns the current array-ref value (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef). If the single argument is an array ref, then a slice of the referenced array is returned.

=item *

If called with a list of index-value pairs, stores the value at the given index in the referenced array. If the instance's value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Array (
    array => 'bar',
  );
  ...
  
  # Set values by position
  $obj->bar(0 => 'Foozle', 1 => 'Bang!');
  
  # Positions may be overwritten, and in any order
  $obj->bar(2 => 'And Mash', 1 => 'Blah!');
  
  # Retrieve value by position
  print $obj->bar(1);
  
  # Retrieve slice of values by position
  print join(', ', $obj->bar( [0, 2] ) );
  
  # Direct access to referenced array
  print scalar @{ $obj->bar() };
  
  # Reset the array contents to empty
  @{ $obj->bar() } = ();

=cut

sub array {
  my $class = shift;
  map { 
    my $name = $_;
    my $index = _array_index( $class->_context('TargetClass'), $name );
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	return $self->[$index];
      } elsif ( scalar(@_) == 1 ) {
	return $self->[$index]->[ shift() ];
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  my $k = shift();
	  $self->[$index]->[ $k ] = shift();
	}
	return $self->[$index];
      }
    }
  } @_;
}

########################################################################

=head2 hash - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on an array-based instance.

=item *

Determines the array position associated with the method name, and uses that as an index into each instance to access the related value.

=item * 

The value for each instance will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the current hash-ref value (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef). If the single argument is an array ref, then a slice of the referenced hash is returned.

=item *

If called with a list of key-value pairs, stores the value under the given key in the referenced hash. If the instance's value was previously undefined, a new hash is autovivified. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the current hash-ref value.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Array (
    hash => 'baz',
  );
  ...
  
  # Set values by key
  $obj->baz('foo' => 'Foozle', 'bar' => 'Bang!');
  
  # Values may be overwritten, and in any order
  $obj->baz('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  
  # Retrieve value by key
  print $obj->baz('foo');
  
  # Retrieve slice of values by position
  print join(', ', $obj->baz( ['foo', 'bar'] ) );
  
  # Direct access to referenced hash
  print keys %{ $obj->baz() };
  
  # Reset the hash contents to empty
  @{ $obj->baz() } = ();

=cut

sub hash {
  my $class = shift;
  map { 
    my $name = $_;
    my $index = _array_index( $class->_context('TargetClass'), $name );
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	return $self->[$index];
      } elsif ( scalar(@_) == 1 ) {
	return $self->[$index]->{ shift() };
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  my $k = shift();
	  $self->[$index]->{ $k } = shift();
	}
	return $self->[$index];
      }
    }
  } @_;
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Basic> for more about this family of subclasses.

=cut

1;
