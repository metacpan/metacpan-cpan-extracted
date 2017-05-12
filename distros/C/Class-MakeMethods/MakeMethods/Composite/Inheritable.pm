=head1 NAME

Class::MakeMethods::Composite::Inheritable - Overridable data

=head1 SYNOPSIS

  package MyClass;

  use Class::MakeMethods( 'Composite::Inheritable:scalar' => 'foo' );
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
  use Class::MakeMethods::Composite::Inheritable (
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


=head2 Class::MakeMethods Calling Interface

When you C<use> this package, the method declarations you provide
as arguments cause subroutines to be generated and installed in
your module.

See L<Class::MakeMethods::Standard/"Calling Conventions"> for more information.

=head2 Class::MakeMethods::Standard Declaration Syntax

To declare methods, pass in pairs of a method-type name followed
by one or more method names. 

See the "METHOD GENERATOR TYPES" section below for a list of the supported values of I<generator_type>.

See L<Class::MakeMethods::Standard/"Declaration Syntax"> and L<Class::MakeMethods::Standard/"Parameter Syntax"> for more information.

=cut

package Class::MakeMethods::Composite::Inheritable;

$VERSION = 1.000;
use strict;
use Carp;

use Class::MakeMethods::Composite '-isasubclass';
use Class::MakeMethods::Utility::Inheritable qw(get_vvalue set_vvalue find_vself );

########################################################################

=head1 METHOD GENERATOR TYPES

=head2 scalar - Overrideable Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class or instance method, on the declaring class or any subclass. 

=item *

If called without any arguments returns the current value for the callee. If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

=item *

If called with an argument, stores that as the value associated with the callee, whether instance or class, and returns it, 

=item * 

If called with multiple arguments, stores a reference to a new array with those arguments as contents, and returns that array reference.

=back

Sample declaration and usage:

  package MyClass;
  use Class::MakeMethods::Composite::Inheritable (
    scalar => 'foo',
  );
  ...
  
  # Store value
  MyClass->foo('Foozle');
  
  # Retrieve value
  print MyClass->foo;

=cut

use vars qw( %ScalarFragments );

sub scalar {
  (shift)->_build_composite( \%ScalarFragments, @_ );
}

%ScalarFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{target_class} ||= $Class::MethodMaker::CONTEXT{TargetClass};
	$method->{data} ||= {};
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;	
	if ( scalar(@_) == 0 ) {
	  return get_vvalue($method->{data}, $self);
	} else {
	  my $value = (@_ == 1 ? $_[0] : [@_]);
	  set_vvalue($method->{data}, $self, $value);
	}
      },
  ],
  'rw' => [],
  'p' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	unless ( UNIVERSAL::isa((caller(1))[0], $method->{target_class}) ) {
	  croak "Method $method->{name} is protected";
	}
      },
  ],
  'pp' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	unless ( (caller(1))[0] eq $method->{target_class} ) {
	  croak "Method $method->{name} is private";
	}
      },
  ],
  'pw' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	unless ( @_ == 0 or UNIVERSAL::isa((caller(1))[0], $method->{target_class}) ) {
	  croak "Method $method->{name} is write-protected";
	}
      },
  ],
  'ppw' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	unless ( @_ == 0 or (caller(1))[0] eq $method->{target_class} ) {
	  croak "Method $method->{name} is write-private";
	}
      },
  ],
  'r' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	@{ $method->{args} } = ();
      },
  ],
  'ro' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	unless ( @_ == 0 ) {
	  croak("Method $method->{name} is read-only");
	}
      },
  ],
  'wo' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	if ( @_ == 0 ) {
	  croak("Method $method->{name} is write-only");
	}
      },
  ],
  'return_original' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $v_self = find_vself($method->{data}, $self);
	$method->{scratch}{return_original} = 
					$v_self ? $method->{data}{$v_self} : ();
      },
    '+post' => sub { 
	my $method = pop @_;
	$method->{result} = \{ $method->{scratch}{return_original} };
      },
  ],
);

########################################################################

=head2 array - Overrideable Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, Must be called on a hash-based instance.

=item * 

The class value will be a reference to an array (or undef).

=item *

If called without any arguments, returns the current array-ref value (or undef).


=item *

If called with a single non-ref argument, uses that argument as an index to retrieve from the referenced array, and returns that value (or undef).

=item *

If called with a single array ref argument, uses that list to return a slice of the referenced array.

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
  use Class::MakeMethods::Composite::Inheritable (
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

B<NOTE: THIS METHOD GENERATOR HAS NOT BEEN WRITTEN YET.> 

=cut

use vars qw( %ArrayFragments );

sub array {
  (shift)->_build_composite( \%ArrayFragments, @_ );
}

%ArrayFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{hash_key} ||= $_->{name};
	$method->{data} ||= {};
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	
	if ( scalar(@_) == 0 ) {
	  my $v_self = find_vself($method->{data}, $self);
	  my $value = $v_self ? $method->{data}{$v_self} : ();
	  if ( $method->{auto_init} and ! $value ) {
	    $value = $method->{data}{$self} = [];
	  }
	  ( ! $value ) ? () : wantarray ? @$value : $value;
	  
	} elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
	  $method->{data}{$self} = [ @{ $_[0] } ];
	  wantarray ? @{ $method->{data}{$self} } : $method->{data}{$self}
	  
	} else {
	  if ( ! exists $method->{data}{$self} ) {
	    my $v_self = find_vself($method->{data}, $self);
	    $method->{data}{$self} = [ $v_self ? @{$method->{data}{$v_self}} : () ];
	  }
	  return array_splicer( $method->{data}{$self}, @_ );
	}
      },
  ],
);

########################################################################

=head2 hash - Overrideable Ref Accessor

For each method name passed, uses a closure to generate a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or on any instance or subclass, Must be called on a hash-based instance.

=item * 

The class value will be a reference to a hash (or undef).

=item *

If called without any arguments returns the contents of the hash in list context, or a hash reference in scalar context for the callee. If the callee has not had a value defined for this method, searches up from instance to class, and from class to superclass, until a callee with a value is located.

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
  use Class::MakeMethods::Composite::Inheritable (
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

use vars qw( %HashFragments );

sub hash {
  (shift)->_build_composite( \%HashFragments, @_ );
}

%HashFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{hash_key} ||= $_->{name};
	$method->{data} ||= {};
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	
	if ( scalar(@_) == 0 ) {
	  my $value = get_vvalue($method->{data}, $self);
	  if ( $method->{auto_init} and ! $value ) {
	    $value = set_vvalue( $method->{data}, $self, {} );
	  }
	  wantarray ? %$value : $value;
	} elsif ( scalar(@_) == 1 ) {
	  if ( ref($_[0]) eq 'HASH' ) {
	    %{$method->{data}{$self}} = %{$_[0]};
	  } elsif ( ref($_[0]) eq 'ARRAY' ) {
	    my $v_self = find_vself($method->{data}, $self) or return;
	    return @{ $method->{data}{$v_self} }{ @{$_[0]} }
	  } else {
	    my $v_self = find_vself($method->{data}, $self) or return;
	    return $method->{data}{$v_self}{ $_[0] }
	  }

	} elsif ( scalar(@_) % 2 ) {
	  Carp::croak "Odd number of items in assigment to $method->{name}";
	} else {
	  if ( ! exists $method->{data}{$self} ) {
	    my $v_self = find_vself($method->{data}, $self);
	    $method->{data}{$self} = { $v_self ? %{ $method->{data}{$v_self} } : () };
	  }
	  while ( scalar(@_) ) {
	    my $key = shift();
	    $method->{data}{$self}->{ $key } = shift();
	  }
	  wantarray ? %{$method->{data}{$self}} : $method->{data}{$self};
	}
      },
  ],
);

########################################################################

=head2 hook - Overrideable array of subroutines

A hook method is called from the outside as a normal method. However, internally, it contains an array of subroutine references, each of which are called in turn to produce the method's results.

Subroutines may be added to the hook's array by calling it with a blessed subroutine reference, as shown below. Subroutines may be added on a class-wide basis or on an individual object. 

You might want to use this type of method to provide an easy way for callbacks to be registered.

  package MyClass;
  use Class::MakeMethods::Composite::Inheritable ( 'hook' => 'init' );
  
  MyClass->init( Class::MakeMethods::Composite::Inheritable->Hook( sub { 
      my $callee = shift;
      warn "Init...";
  } );
  
  my $obj = MyClass->new;
  $obj->init();

=cut

use vars qw( %HookFragments );

sub hook {
  (shift)->_build_composite( \%HookFragments, @_ );
}

%HookFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{data} ||= {};
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	
	if ( scalar(@_) and 
	    ref($_[0]) eq 'Class::MakeMethods::Composite::Inheritable::Hook' ) {
	  if ( ! exists $method->{data}{$self} ) {
	    my $v_self = find_vself($method->{data}, $self);
	    $method->{data}{$self} = [ $v_self ? @{ $method->{data}{$v_self} } : () ];
	  }
	  push @{ $method->{data}{$self} }, map $$_, @_;
	} else {
	  my $v_self = find_vself($method->{data}, $self);
	  my $subs = $v_self ? $method->{data}{$v_self} : ();
	  my @subs = ( ( ! $subs ) ? () : @$subs );
	  
	  if ( ! defined $method->{wantarray} ) {
	    foreach my $sub ( @subs ) {
	      &$sub( @{$method->{args}} );	
	    }
	  } elsif ( ! $method->{wantarray} ) {
	    foreach my $sub ( @subs ) {
	      my $value = &$sub( @{$method->{args}} );
	      if ( defined $value ) { 
		$method->{result} = \$value;
	      }
	    }
	  } else {
	    foreach my $sub ( @subs ) {
	      my @value = &$sub( @{$method->{args}} );
	      if ( scalar @value ) { 
		push @{ $method->{result} }, @value;
	      }
	    }
	  }
	  
	}
	return Class::MakeMethods::Composite->CurrentResults();
      },
  ],
);

sub Hook (&) { 
  my $package = shift;
  my $sub = shift;
  bless \$sub, 'Class::MakeMethods::Composite::Inheritable::Hook';
}

########################################################################

=head2 object - Overrideable Ref Accessor

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
  use Class::MakeMethods::Composite::Inheritable (
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

See L<Class::MakeMethods::Composite> for more about this family of subclasses.

=cut

1;
