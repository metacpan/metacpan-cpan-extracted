=head1 NAME

Class::MakeMethods::Standard::Hash - Standard hash methods

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Standard::Hash (
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

The Standard::Hash suclass of MakeMethods provides a basic constructor and accessors for blessed-hash object instances.

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

package Class::MakeMethods::Standard::Hash;

$VERSION = 1.000;
use strict;
use Class::MakeMethods::Standard '-isasubclass';
use Class::MakeMethods::Utility::ArraySplicer 'array_splicer';

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 new - Constructor

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

Has a reference to a sample item to copy. This defaults to a reference to an empty hash, but you may override this with the C<'defaults' => I<hash_ref>>  method parameter. 

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
  use Class::MakeMethods::Standard::Hash (
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
  map { 
    my $name = $_->{name};
    my $defaults = $_->{defaults} || {};
    $name => sub {
      my $callee = shift;
      my $self = ref($callee) ? bless( { %$callee }, ref $callee ) 
			      : bless( { %$defaults },   $callee );
      while ( scalar @_ ) {
	my $method = shift;
	UNIVERSAL::can( $self, $method ) 
	  or Carp::croak("Can't call method '$method' in constructor for " . ( ref($callee) || $callee ));
	$self->$method( shift );
      }
      return $self;
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 scalar - Instance Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Has a specific hash key to use to access the related value for each instance.
This defaults to the method name, but you may override this with the C<'hash_key' => I<string>> method parameter. 

=item *

If called without any arguments returns the current value.

=item *

If called with an argument, stores that as the value, and returns it, 

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Hash (
    scalar => 'foo',
  );
  ...
  
  # Store value
  $obj->foo('Foozle');
  
  # Retrieve value
  print $obj->foo;

=cut

sub scalar {
  map { 
    my $name = $_->{name};
    my $hash_key = $_->{hash_key} || $_->{name};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	$self->{$hash_key};
      } else {
	$self->{$hash_key} = shift;
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 array - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Has a specific hash key to use to access the related value for each instance.
This defaults to the method name, but you may override this with the C<'hash_key' => I<string>> method parameter. 

=item * 

The value for each instance will be a reference to an array (or undef).

=item *

If called without any arguments, returns the contents of the array in list context, or an array reference in scalar context (or undef).

=item *

If called with a single array ref argument, sets the contents of the array to match the contents of the provided one.

=item *

If called with a single numeric argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef).

=item *

If called with a two arguments, the first undefined and the second an array ref argument, uses that array's contents as a list of indexes to return a slice of the referenced array.

=item *

If called with a list of argument pairs, each with a numeric index and an associated value, stores the value at the given index in the referenced array. If the instance's value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

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
  use Class::MakeMethods::Standard::Hash (
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
  map { 
    my $name = $_->{name};
    my $hash_key = $_->{hash_key} || $_->{name};
    my $init = $_->{auto_init};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	if ( $init and ! defined $self->{$hash_key} ) {
	  $self->{$hash_key} = [];
	}
	( ! $self->{$hash_key} ) ? () : 
	( wantarray            ) ? @{ $self->{$hash_key} } :
				   $self->{$hash_key}
      } elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
	$self->{$hash_key} = [ @{ $_[0] } ];
	( ! $self->{$hash_key} ) ? () : 
	( wantarray            ) ? @{ $self->{$hash_key} } :
				   $self->{$hash_key}
      } else {
	$self->{$hash_key} ||= [];
	return array_splicer( $self->{$hash_key}, @_ );
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 hash - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Has a specific hash key to use to access the related value for each instance.
This defaults to the method name, but you may override this with the C<'hash_key' => I<string>> method parameter. 

=item * 

The value for each instance will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the contents of the hash in list context, or a hash reference in scalar context (or undef).

=item *

If called with one non-ref argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef).

=item *

If called with one array-ref argument, uses the contents of that array to retrieve a slice of the referenced hash.

=item *

If called with one hash-ref argument, sets the contents of the referenced hash to match that provided.

=item *

If called with a list of key-value pairs, stores the value under the given key in the referenced hash. If the instance's value was previously undefined, a new hash is autovivified. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the contents of the hash in list context, or a hash reference in scalar context.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Standard::Hash (
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
  %{ $obj->baz() } = ();

=cut

sub hash {
  map { 
    my $name = $_->{name};
    my $hash_key = $_->{hash_key} || $_->{name};
    my $init = $_->{auto_init};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	if ( $init and ! defined $self->{$hash_key} ) {
	  $self->{$hash_key} = {};
	}
	( ! $self->{$hash_key} ) ? () : 
	( wantarray            ) ? %{ $self->{$hash_key} } :
				   $self->{$hash_key}
      } elsif ( scalar(@_) == 1 ) {
	if ( ref($_[0]) eq 'HASH' ) {
	  $self->{$hash_key} = { %{$_[0]} };
	} elsif ( ref($_[0]) eq 'ARRAY' ) {
	  return @{$self->{$hash_key}}{ @{$_[0]} }
	} else {
	  return $self->{$hash_key}->{ $_[0] }
	}
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $name";
      } else {
	while ( scalar(@_) ) {
	  my $key = shift();
	  $self->{$hash_key}->{ $key } = shift();
	}
	return $self->{$hash_key};
      }
    }
  } (shift)->_get_declarations(@_)
}

########################################################################

=head2 object - Instance Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

Must be called on a hash-based instance.

=item *

Has a specific hash key to use to access the related value for each instance.
This defaults to the method name, but you may override this with the C<'hash_key' => I<string>> method parameter. 

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
  map { 
    my $name = $_->{name};
    my $hash_key = $_->{hash_key} || $_->{name};
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
	$self->{$hash_key} = $value;
      } else {
	if ( $init and ! defined $self->{$hash_key} ) {
	  $self->{$hash_key} = $class->$new_method();
	}
	$self->{$hash_key};
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
