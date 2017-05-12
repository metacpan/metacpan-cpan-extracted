=head1 NAME

Class::MakeMethods::Standard::Inheritable - Overridable data

=head1 SYNOPSIS

  package MyClass;

  use Class::MakeMethods( 'Standard::Inheritable:scalar' => 'foo' );
  # We now have an accessor method for an "inheritable" scalar value
  
  MyClass->foo( 'Foozle' );   # Set a class-wide value
  print MyClass->foo();	      # Retrieve class-wide value
  
  my $obj = MyClass->new(...);
  print $obj->foo();          # All instances "inherit" that value...
  
  $obj->foo( 'Foible' );      # until you set a value for an instance.
  print $obj->foo();          # This now finds object-specific value.
  ...
  
  package MySubClass;
  @ISA = 'MyClass';
  
  print MySubClass->foo();    # Intially same as superclass,
  MySubClass->foo('Foobar');  # but overridable per subclass,
  print $subclass_obj->foo(); # and shared by its instances
  $subclass_obj->foo('Fosil');# until you override them... 
  ...
  
  # Similar behaviour for hashes and arrays is currently incomplete
  package MyClass;
  use Class::MakeMethods::Standard::Inheritable (
    array => 'my_list',
    hash => 'my_index',
  );
  
  MyClass->my_list(0 => 'Foozle', 1 => 'Bang!');
  print MyClass->my_list(1);
  
  MyClass->my_index('broccoli' => 'Blah!', 'foo' => 'Fiddle');
  print MyClass->my_index('foo');


=head1 DESCRIPTION

The MakeMethods subclass provides accessor methods that search an inheritance tree to find a value. This allows you to set a shared or default value for a given class, optionally override it in a subclass, and then optionally override it on a per-instance basis. 

Note that all MakeMethods methods are inheritable, in the sense that they work as expected for subclasses. These methods are different in that the I<data> accessed by each method can be inherited or overridden in each subclass or instance. See L< Class::MakeMethods::Utility::Inheritable> for more about this type of "inheritable" or overridable" data.


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

package Class::MakeMethods::Standard::Inheritable;

$VERSION = 1.000;
use strict;

use Class::MakeMethods::Standard '-isasubclass';
use Class::MakeMethods::Utility::Inheritable qw(get_vvalue set_vvalue find_vself);
use Class::MakeMethods::Utility::ArraySplicer 'array_splicer';

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 scalar - Class-specific Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class or instance method, on the declaring class or any subclass. 

=item *

If called without any arguments returns the current value for the callee. If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

=item *

If called with an argument, stores that as the value associated with the callee, whether instance or class, and returns it, 

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Standard::Inheritable (
    scalar => 'foo',
  );
  ...
  
  # Store value
  MyClass->foo('Foozle');
  
  # Retrieve value
  print MyClass->foo;

=cut

sub scalar {
  my $class = shift;
  map { 
    my $method = $_;
    my $name = $method->{name};
    $method->{data} ||= {};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	get_vvalue($method->{data}, $self);
      } else {
	my $value = shift;
	set_vvalue($method->{data}, $self, $value);
      }
    }
  } $class->_get_declarations(@_)
}

########################################################################

=head2 array - Class-specific Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, Must be called on a hash-based instance.

=item * 

The class value will be a reference to an array (or undef).

=item *

If called without any arguments, returns the contents of the array in list context, or an array reference in scalar context (or undef).

=item *

If called with a single array ref argument, sets the contents of the array to match the contents of the provided one.

=item *

If called with a single numeric argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef).

=item *

If called with a two arguments, the first undefined and the second an array ref argument, uses that array's contents as a list of indexes to return a slice of the referenced array.

=item *

If called with a list of argument pairs, each with a non-ref index and an associated value, stores the value at the given index in the referenced array. If the class value was previously undefined, a new array is autovivified. The current value in each position will be overwritten, and later arguments with the same index will override earlier ones. Returns the current array-ref value.

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
  use Class::MakeMethods::Standard::Inheritable (
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
  my $class = shift;
  map { 
    my $method = $_;
    my $name = $method->{name};
    $name => sub {
      my $self = shift;

     if ( scalar(@_) == 0 ) {
	my $v_self = find_vself($method->{data}, $self);
	my $value = $v_self ? $method->{data}{$v_self} : ();
	if ( $method->{auto_init} and ! $value ) {
	  $value = $method->{data}{$self} = [];
	}
	! $value ? () : wantarray ? @$value : $value;
	
      } elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
	$method->{data}{$self} = [ @{ $_[0] } ];
	wantarray ? @{ $method->{data}{$self} } : $method->{data}{$self}
	
      } else {
	if ( ! exists $method->{data}{$self} ) {
	  my $v_self = find_vself($method->{data}, $self);
	  $method->{data}{$self} = [ $v_self ? @$v_self : () ];
	}
	return array_splicer( $method->{data}{$self}, @_ );
      }
    } 
  } $class->_get_declarations(@_)
}

########################################################################

=head2 hash - Class-specific Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, Must be called on a hash-based instance.

=item * 

The class value will be a reference to a hash (or undef).

=item *

If called without any arguments, returns the contents of the hash in list context, or a hash reference in scalar context. If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

=item *

If called with one non-ref argument, uses that argument as an index to retrieve from the referenced hash, and returns that value (or undef). If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

=item *

If called with one array-ref argument, uses the contents of that array to retrieve a slice of the referenced hash. If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

=item *

If called with one hash-ref argument, sets the contents of the referenced hash to match that provided.

=item *

If called with a list of key-value pairs, stores the value under the given key in the hash associated with the callee, whether instance or class. If the callee did not previously have a hash-ref value associated with it, searches up instance to class, and from class to superclass, until a callee with a value is located, and copies that hash before making the assignments. The current value under each key will be overwritten, and later arguments with the same key will override earlier ones. Returns the contents of the hash in list context, or a hash reference in scalar context.

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Standard::Inheritable (
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

B<NOTE: THIS METHOD GENERATOR IS INCOMPLETE.> 

=cut

sub hash {
  my $class = shift;
  map { 
    my $method = $_;
    my $name = $method->{name};
    $name => sub {
      my $self = shift;
      if ( scalar(@_) == 0 ) {
	my $v_self = find_vself($method->{data}, $self);
	my $value = $v_self ? $method->{data}{$v_self} : ();
	if ( $method->{auto_init} and ! $value ) {
	  $value = $method->{data}{$self} = {};
	}
	! $value ? () : wantarray ? %$value : $value;
      } elsif ( scalar(@_) == 1 ) {
	if ( ref($_[0]) eq 'HASH' ) {
	  $method->{data}{$self} = { %{$_[0]} };
	} elsif ( ref($_[0]) eq 'ARRAY' ) {
	  my $v_self = find_vself($method->{data}, $self);
	  return unless $v_self;
	  return @{$method->{data}{$v_self}}{ @{$_[0]} } 
	} else {
	  my $v_self = find_vself($method->{data}, $self);
	  return unless $v_self;
	  return $method->{data}{$v_self}->{ $_[0] };
	}
      } elsif ( scalar(@_) % 2 ) {
	Carp::croak "Odd number of items in assigment to $method->{name}";
      } else {
	if ( ! exists $method->{data}{$self} ) {
	  my $v_self = find_vself($method->{data}, $self);
	  $method->{data}{$self} = { $v_self ? %$v_self : () };
	}
	while ( scalar(@_) ) {
	  my $key = shift();
	  $method->{data}{$self}->{ $key } = shift();
	}
	wantarray ? %{ $method->{data}{$self} } : $method->{data}{$self};
      }
    } 
  } $class->_get_declarations(@_)
} 

########################################################################

=head2 object - Class-specific Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, Must be called on a hash-based instance.

=item * 

The class value will be a reference to an object (or undef).

=item *

If called without any arguments returns the current value for the callee. If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

=item *

If called with an argument, stores that as the value associated with the callee, whether instance or class, and returns it, 

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Standard::Inheritable (
    object => 'foo',
  );
  ...
  
  # Store value
  MyClass->foo( Foozle->new() );
  
  # Retrieve value
  print MyClass->foo;

B<NOTE: THIS METHOD GENERATOR HAS NOT BEEN WRITTEN YET.> 

=cut

sub object { }

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Standard> for more about this family of subclasses.

=cut

1;
