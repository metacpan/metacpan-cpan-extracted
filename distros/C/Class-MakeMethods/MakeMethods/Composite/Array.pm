=head1 NAME

Class::MakeMethods::Composite::Array - Basic array methods

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Composite::Array (
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

The Composite::Array suclass of MakeMethods provides a basic
constructor and accessors for blessed-array object instances.

=head2 Class::MakeMethods Calling Conventions

When you C<use> this package, the method declarations you provide
as arguments cause subroutines to be generated and installed in
your module.

You can also omit the arguments to C<use> and instead make methods
at runtime by passing the declarations to a subsequent call to
C<make()>.

You may include any number of declarations in each call to C<use>
or C<make()>. If methods with the same name already exist, earlier
calls to C<use> or C<make()> win over later ones, but within each
call, later declarations superceed earlier ones.

You can install methods in a different package by passing C<-TargetClass =E<gt> I<package>> as your first arguments to C<use> or C<make>. 

See L<Class::MakeMethods> for more details.

=head2 Class::MakeMethods::Basic Declaration Syntax

The following types of Basic declarations are supported:

=over 4

=item *

I<generator_type> => "I<method_name>"

=item *

I<generator_type> => "I<name_1> I<name_2>..."

=item *

I<generator_type> => [ "I<name_1>", "I<name_2>", ...]

=back

See the "METHOD GENERATOR TYPES" section below for a list of the supported values of I<generator_type>.

For each method name you provide, a subroutine of the indicated
type will be generated and installed under that name in your module.

Method names should start with a letter, followed by zero or more
letters, numbers, or underscores.

=head2 Class::MakeMethods::Composite Declaration Syntax

The Composite syntax also provides several ways to optionally
associate a hash of additional parameters with a given method
name. 

=over 4

=item *

I<generator_type> => [ "I<name_1>" => { I<param>=>I<value>... }, ... ]

A hash of parameters to use just for this method name. 

(Note: to prevent confusion with self-contained definition hashes,
described below, parameter hashes following a method name must not
contain the key 'name'.)

=item *

I<generator_type> => [ [ "I<name_1>", "I<name_2>", ... ] => { I<param>=>I<value>... } ]

Each of these method names gets a copy of the same set of parameters.

=item *

I<generator_type> => [ { "name"=>"I<name_1>", I<param>=>I<value>... }, ... ]

By including the reserved parameter C<name>, you create a self
contained declaration with that name and any associated hash values.

=back

Basic declarations, as described above, are treated as having an empty parameter hash.

=cut

package Class::MakeMethods::Composite::Array;

$VERSION = 1.000;
use strict;
use Class::MakeMethods::Composite '-isasubclass';

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
  use Class::MakeMethods::Composite::Array (
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

use vars qw( %ConstructorFragments );

sub new {
  (shift)->_build_composite( \%ConstructorFragments, @_ );
}

%ConstructorFragments = (
  '' => [
    '+init' => sub {
	my $method = pop @_;
	$method->{target_class} ||= $Class::MethodMaker::CONTEXT{TargetClass};
	$method->{defaults} ||= [];
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $obj = ref($self) ? bless( [ @$self ], ref $self ) 
			     : bless( { @[$method->{defaults}] }, $self );
	@_ = %{$_[0]} 
		if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );
	while ( scalar @_ ) {
	  my $method = shift @_;
	  $obj->$method( shift @_ );
	}
	$obj;
      },
  ],
  'with_values' => [
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	@_ = @[$_[0]] 
		if ( scalar @_ == 1 and ref $_[0] eq 'ARRAY' );
	bless( [ @_ ], ref($self) || $self );
      }
  ],
);

########################################################################

=head2 new_with_values - Constructor

For each method name passed, returns a subroutine with the following characteristics:

=over 4

=item *

May be called as a class method, or (equivalently) on any existing object of that class. 

=item *

Creates an array, blesses it into the class, and returns the new instance.

=item *

If no arguments are provided, the returned array will be empty. If passed a single array-ref argument, copies its contents into the new array. If called with multiple arguments, copies them into the new array. (Note that this is a "shallow" copy, not a "deep" clone.)

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Composite::Array (
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

=item * 

If called with multiple arguments, stores a reference to a new array with those arguments as contents, and returns that array reference.

=back

Sample declaration and usage:

  package MyObject;
  use Class::MakeMethods::Composite::Array (
    scalar => 'foo',
  );
  ...
  
  # Store value
  $obj->foo('Foozle');
  
  # Retrieve value
  print $obj->foo;

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
	$method->{array_index} ||= 
		_array_index( $method->{target_class}, $name );
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	if ( scalar(@_) == 0 ) {
	  $self->[$method->{array_index}];
	} elsif ( scalar(@_) == 1 ) {
	  $self->[$method->{array_index}] = shift;
	} else {
	  $self->[$method->{array_index}] = [@_];
	}
      },
  ],
  'rw' => [],
  'p' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	unless ( UNIVERSAL::isa((caller(1))[0], $method->{target_class}) ) {
	  croak "Method $method->{name} is protected";
	}
      },
  ],
  'pp' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	unless ( (caller(1))[0] eq $method->{target_class} ) {
	  croak "Method $method->{name} is private";
	}
      },
  ],
  'pw' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	unless ( @$args == 0 or UNIVERSAL::isa((caller(1))[0], $method->{target_class}) ) {
	  croak "Method $method->{name} is write-protected";
	}
      },
  ],
  'ppw' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	unless ( @$args == 0 or (caller(1))[0] eq $method->{target_class} ) {
	  croak "Method $method->{name} is write-private";
	}
      },
  ],
  'r' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	@$args = ();
      },
  ],
  'ro' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	unless ( @$args == 0 ) {
	  croak("Method $method->{name} is read-only");
	}
      },
  ],
  'wo' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	if ( @$args == 0 ) {
	  croak("Method $method->{name} is write-only");
	}
      },
  ],
  'return_original' => [ 
    '+pre' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	$method->{scratch}{return_original} = $self->[$method->{array_index}];
      },
    '+post' => sub { 
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	$method->{result} = \{ $method->{scratch}{return_original} };
      },
  ],
);

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
  use Class::MakeMethods::Composite::Array (
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


use vars qw( %ArrayFragments );

sub array {
  (shift)->_build_composite( \%ArrayFragments, @_ );
}

%ArrayFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{target_class} ||= $Class::MethodMaker::CONTEXT{TargetClass};
	$method->{array_index} ||= 
		_array_index( $method->{target_class}, $name );
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	if ( scalar(@$args) == 0 ) {
	  if ( $method->{auto_init} and 
			! defined $self->[$method->{array_index}] ) {
	    $self->[$method->{array_index}] = [];
	  }
	  wantarray ? @{ $self->[$method->{array_index}] } : $self->[$method->{array_index}];
	} elsif ( scalar(@_) == 1 and ref $_[0] eq 'ARRAY' ) {
	  $self->[$method->{array_index}] = [ @{ $_[0] } ];
	  wantarray ? @{ $self->[$method->{array_index}] } : $self->[$method->{array_index}];
	} else {
	  $self->[$method->{array_index}] ||= [];
	  Class::MakeMethods::Composite::__array_ops( 
		$self->[$method->{array_index}], @$args );
	}
      },
  ],
);

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
  use Class::MakeMethods::Composite::Array (
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


use vars qw( %HashFragments );

sub hash {
  (shift)->_build_composite( \%HashFragments, @_ );
}

%HashFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{hash_key} ||= $_->{name};
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift @_;
	my $args = \@_;
	if ( scalar(@$args) == 0 ) {
	  if ( $method->{auto_init} and ! defined $self->[$method->{array_index}] ) {
	    $self->[$method->{array_index}] = {};
	  }
	  wantarray ? %{ $self->[$method->{array_index}] } : $self->[$method->{array_index}];
	} elsif ( scalar(@$args) == 1 ) {
	  if ( ref($_[0]) eq 'HASH' ) {
	    %{$self->[$method->{array_index}]} = %{$_[0]};
	  } elsif ( ref($_[0]) eq 'ARRAY' ) {
	    return @{$self->[$method->{array_index}]}{ @{$_[0]} }
	  } else {
	    return $self->[$method->{array_index}]->{ $_[0] }
	  }
	} elsif ( scalar(@$args) % 2 ) {
	  croak "Odd number of items in assigment to $method->{name}";
	} else {
	  while ( scalar(@$args) ) {
	    my $key = shift @$args;
	    $self->[$method->{array_index}]->{ $key} = shift @$args;
	  }
	  wantarray ? %{ $self->[$method->{array_index}] } : $self->[$method->{array_index}];
	}
      },
  ],
);

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
  use Class::MakeMethods::Composite::Hash (
    object => 'foo',
  );
  ...
  
  # Store value
  $obj->foo( Foozle->new() );
  
  # Retrieve value
  print $obj->foo;

=cut

use vars qw( %ObjectFragments );

sub object {
  (shift)->_build_composite( \%ObjectFragments, @_ );
}

%ObjectFragments = (
  '' => [
    '+init' => sub {
	my ($method) = @_;
	$method->{hash_key} ||= $_->{name};
      },
    'do' => sub {
	my $method = pop @_;
	my $self = shift;
	if ( scalar @_ ) {
	  my $value = shift;
	  if ( $method->{class} and ! UNIVERSAL::isa( $value, $method->{class} ) ) {
	    croak "Wrong argument type ('$value') in assigment to $method->{name}";
	  }
	  $self->[$method->{array_index}] = $value;
	} else {
	  if ( $method->{auto_init} and ! defined $self->[$method->{array_index}] ) {
	    my $class = $method->{class} 
				or die "Can't auto_init without a class";
	    my $new_method = $method->{new_method} || 'new';
	    $self->[$method->{array_index}] = $class->$new_method();
	  }
	  $self->[$method->{array_index}];
	}
      },
  ],
);

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Composite> for more about this family of subclasses.

=cut

1;
