=head1 NAME

Class::MakeMethods::Basic::Global - Basic shared methods

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Basic::Global (
    scalar => [ 'foo', 'bar' ],
    array => 'my_list',
    hash => 'my_index',
  );
  ....
  
  # Store and retrieve global values
  MyObject->foo('Foobar');
  print MyObject->foo();
  
  # All instances of your class access the same values
  $my_object->bar('Barbados'); 
  print $other_one->bar(); 
  
  # Array accessor
  MyObject->my_list(0 => 'Foozle', 1 => 'Bang!');
  print MyObject->my_list(1);
  
  # Hash accessor
  MyObject->my_index('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  print MyObject->my_index('foo');


=head1 DESCRIPTION

The Basic::Global subclass of MakeMethods provides basic accessors for data shared by an entire class, sometimes called "static" or "class data."

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

package Class::MakeMethods::Basic::Global;

$VERSION = 1.000;
use Class::MakeMethods '-isasubclass';

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 scalar - Shared Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or equivalently, on any object instance.

=item *

Stores a global value accessible only through this method.

=item *

If called without any arguments returns the current value.

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Hash (
    scalar => 'foo',
  );
  ...
  
  # Store value
  MyObject->foo('Foozle');
  
  # Retrieve value
  print MyObject->foo;

=cut

sub scalar {
  my $class = shift;
  map { 
    my $name = $_;
    $name => sub {
      my $self = shift;
      if ( scalar @_ ) {
	$value = shift;
      } else {
	$value;
      }
    }
  } @_;
}

########################################################################

=head2 array - Shared Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or equivalently, on any object instance.

=item *

Stores a global value accessible only through this method.

=item * 

The value will be a reference to an array (or undef).

=item *

If called without any arguments, returns the current array-ref value (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef). If the single argument is an array ref, then a slice of the referenced array is returned.

=item *

If called with a list of index-value pairs, stores the value at the given index in the referenced array. If the value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Hash (
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
    my $value = [];
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 1 ) {
	my $index = shift;
	ref($index) ? @{$value}[ @$index ] : $value->[ $index ];
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  $value->[ shift() ] = shift();
	}
	return $value;
      }
    }
  } @_;
}

########################################################################

=head2 hash - Shared Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or equivalently, on any object instance.

=item *

Stores a global value accessible only through this method.

=item * 

The value will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the current hash-ref value (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef). If the single argument is an array ref, then a slice of the referenced hash is returned.

=item *

If called with a list of key-value pairs, stores the value under the given key in the referenced hash. If the value was previously undefined, a new hash is autovivified. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the current hash-ref value.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Basic::Hash (
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
    my $value = {};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 1 ) {
	my $index = shift;
	ref($index) ? @{$value}{ @$index } : $value->{ $index };
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  my $key = shift;
	  $value->{ $key } = shift();
	}
	$value;
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
