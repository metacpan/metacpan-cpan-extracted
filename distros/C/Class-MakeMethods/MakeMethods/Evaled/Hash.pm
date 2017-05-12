=head1 NAME

Class::MakeMethods::Evaled::Hash - Typical hash methods


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Evaled::Hash (
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

The Evaled::Hash subclass of MakeMethods provides a simple constructor and accessors for blessed-hash object instances.

=head2 Calling Conventions

When you C<use> this package, the method names you provide
as arguments cause subroutines to be generated and installed in
your module.

See L<Class::MakeMethods::Standard/"Calling Conventions"> for a summary, or L<Class::MakeMethods/"USAGE"> for full details.

=head2 Declaration Syntax

To declare methods, pass in pairs of a method-type name followed
by one or more method names. Valid method-type names for this
package are listed in L<"METHOD GENERATOR TYPES">.

See L<Class::MakeMethods::Standard/"Declaration Syntax"> for more
syntax information.


=cut

package Class::MakeMethods::Evaled::Hash;

$VERSION = 1.000;
use strict;
use Class::MakeMethods::Evaled '-isasubclass';

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 new - Constructor

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

If called as a class method, makes a new hash and blesses it into that class.

=item *

If called on a hash-based instance, makes a copy of it and blesses the copy into the same class as the original instance.

=item *

If passed a list of key-value pairs, appends them to the new hash. These arguments override any copied values, and later arguments with the same name will override earlier ones.

=item *

Returns the new instance.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Evaled::Hash (
    new => 'new',
  );
  ...
  
  # Bare constructor
  my $empty = MyObject->new();
  
  # Constructor with initial values
  my $obj = MyObject->new( foo => 'Foozle', bar => 'Barbados' );
  
  # Copy with overriding value
  my $copy = $obj->new( bar => 'Bob' );

=cut

sub new {
  (shift)->evaled_methods( q{
    sub __NAME__ {
      my $callee = shift;
      if ( ref $callee ) {
	bless { %$callee, @_ }, ref $callee;
      } else {
	bless { @_ }, $callee;
      }
    }
  }, @_ )
}

########################################################################

=head2 scalar - Instance Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Uses the method name as a hash key to access the related value for each instance.

=item *

If called without any arguments returns the current value.

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Evaled::Hash (
    scalar => 'foo',
  );
  ...
  
  # Store value
  $obj->foo('Foozle');
  
  # Retrieve value
  print $obj->foo;

=cut

sub scalar {
  (shift)->evaled_methods( q{
    sub __NAME__ {
      my $self = shift;
      if ( scalar @_ ) {
	$self->{'__NAME__'} = shift;
      } else {
	$self->{'__NAME__'};
      }
    }
  }, @_ )
}

########################################################################

=head2 array - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Uses the method name as a hash key to access the related value for each instance.

=item * 

The value for each instance will be a reference to an array (or undef).

=item *

If called without any arguments, returns the current array-ref value (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef). 

=item *

If called with a list of index-value pairs, stores the value at the given index in the referenced array. If the instance's value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

=back

Sample declaration and usage:
  
  package MyObject;
  use Class::MakeMethods::Evaled::Hash (
    array => 'bar',
  );
  ...
  
  # Set values by position
  $obj->bar(0 => 'Foozle', 1 => 'Bang!');
  
  # Positions may be overwritten, and in any order
  $obj->bar(2 => 'And Mash', 1 => 'Blah!');
  
  # Retrieve value by position
  print $obj->bar(1);
    
  # Direct access to referenced array
  print scalar @{ $obj->bar() };
  
  # Reset the array contents to empty
  @{ $obj->bar() } = ();

=cut

sub array {
  (shift)->evaled_methods( q{
    sub __NAME__ {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	return $self->{'__NAME__'};
      } elsif ( scalar(@_) == 1 ) {
	$self->{'__NAME__'}->[ shift() ];
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to __NAME__";
      } else {
	while ( scalar(@_) ) {
	  my $key = shift();
	  $self->{'__NAME__'}->[ $key ] = shift();
	}
	return $self->{'__NAME__'};
      }
    }
  }, @_ )
}

########################################################################

=head2 hash - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Uses the method name as a hash key to access the related value for each instance.

=item * 

The value for each instance will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the current hash-ref value (or undef).

=item *

If called with one argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef). 

=item *

If called with a list of key-value pairs, stores the value under the given key in the referenced hash. If the instance's value was previously undefined, a new hash is autovivified. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the current hash-ref value.

=back

Sample declaration and usage:
  
  package MyObject;
  use Class::MakeMethods::Evaled::Hash (
    hash => 'baz',
  );
  ...
  
  # Set values by key
  $obj->baz('foo' => 'Foozle', 'bar' => 'Bang!');
  
  # Values may be overwritten, and in any order
  $obj->baz('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  
  # Retrieve value by key
  print $obj->baz('foo');
  
  # Direct access to referenced hash
  print keys %{ $obj->baz() };
  
  # Reset the hash contents to empty
  @{ $obj->baz() } = ();

=cut

sub hash {
  (shift)->evaled_methods( q{
    sub __NAME__ {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	return $self->{'__NAME__'};
      } elsif ( scalar(@_) == 1 ) {
	$self->{'__NAME__'}->{ shift() };
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to '__NAME__'";
      } else {
	while ( scalar(@_) ) {
	  $self->{'__NAME__'}->{ shift() } = shift();
	}
	return $self->{'__NAME__'};
      }
    }
  }, @_ )
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Evaled> for more about this family of subclasses.

=cut

1;
