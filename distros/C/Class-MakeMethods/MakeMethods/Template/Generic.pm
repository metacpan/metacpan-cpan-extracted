=head1 NAME

Class::MakeMethods::Template::Generic - Templates for common meta-method types

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods (
    'Template::Hash:new'       => [ 'new' ],
    'Template::Hash:scalar'    => [ 'foo' ]
    'Template::Static:scalar'  => [ 'bar' ]
  );
  
  package main;

  my $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" );
  print $obj->foo();
  $obj->bar("Bamboozle"); 

=head1 DESCRIPTION

This package provides a variety of abstract interfaces for constructors
and accessor methods, which form a common foundation for meta-methods
provided by the Hash, Scalar, Flyweight, Static, PackageVar, and
ClassVar implementations.

Generally speaking, the Generic meta-methods define calling interfaces
and behaviors which are bound to differently scoped data by each
of those subclasses.

=cut

########################################################################

package Class::MakeMethods::Template::Generic;

use Class::MakeMethods::Template '-isasubclass';

$VERSION = 1.008;
use strict;
use Carp;

# use AutoLoader 'AUTOLOAD';

########################################################################

sub generic {
  {
    'params' => {
    },
    'modifier' => {
      '-import' => {  'Template::Universal:generic' => '*' },
    },
    'code_expr' => { 
      '-import' => {  'Template::Universal:generic' => '*'  },
      '_VALUE_' => undef,
      '_REF_VALUE_' => q{ _VALUE_ },
      '_GET_VALUE_' => q{ _VALUE_ },
      '_SET_VALUE_{}' => q{ ( _VALUE_ = * ) },
      '_PROTECTED_SET_VALUE_{}' => q{ (_ACCESS_PROTECTED_ and _SET_VALUE_{*}) },
      '_PRIVATE_SET_VALUE_{}' => q{ ( _ACCESS_PRIVATE_ and _SET_VALUE_{*} ) },
    },
  }
}

# 1;

# __END__

########################################################################

=head2 new Constructor

There are several types of hash-based object constructors to choose from.

Each of these methods creates and returns a reference to a new
blessed instance. They differ in how their (optional) arguments
are interpreted to set initial values, and in how they operate when
called as class or instance methods.

B<Interfaces>: The following interfaces are supported.

=over 4

=item -with_values,

Provides the with_values behavior.

=item -with_init

Provides the with_init behavior. 

=item -with_methods

Provides the with_methods behavior.

=item -new_and_init

Provides the with_init behavior for I<*>, and the general purpose method_init behavior as an init method.

=item -copy_with_values

Provides the copy behavior.

=back

B<Behaviors>: The following types of constructor methods are available.

=over 4

=item with_values

Creates and blesses a new instance. 

If arguments are passed they are included in the instance, otherwise it will be empty.

Returns the new instance.

May be called as a class or instance method.

=item with_methods

Creates, blesses, and returns a new instance.

The arguments are treated as a hash of method-name/argument-value
pairs, with each such pair causing a call C<$self-E<gt>name($value)>.

=item with_init 

Creates and blesses a new instance, then calls a method named C<init>,
passing along any arguments that were initially given.

Returns the new instance.

The I<init>() method should be defined in the class declaring these methods.

May be called as a class or instance method.

=item and_then_init

Creates a new instance using method-name/argument-value pairs, like C<with_methods>, but then calls a method named C<init> before returning the new object. The C<init> method does not receive any arguments.

The I<init>() method should be defined in the class declaring these methods.

=item instance_with_methods

If called as a class method, creates, blesses, and returns a new
instance. If called as an object method, operates on and returns
the existing instance.

Accepts name-value pair arguments, or a reference to hash of such
pairs, and calls the named method for each with the supplied value
as a single argument. (See the Universal method_init behavior for
more discussion of this pattern.)

=item copy_with values

Produce a copy of an instance. Can not be called as a class method.

The copy is a *shallow* copy; any references will be shared by the
instance upon which the method is called and the returned newborn.

If a list of key-value pairs is passed as arguments to the method,
they are added to the copy, overwriting any values with the same
key that may have been copied from the original.

=item copy_with_methods

Produce a copy of an instance. Can not be called as a class method.

The copy is a *shallow* copy; any references will be shared by the
instance upon which the method is called and the returned newborn.

Accepts name-value pair arguments, or a reference to hash of such
pairs, and calls the named method on the copy for each with the
supplied value as a single argument before the copy is returned.

=item copy_instance_with_values

If called as a class method, creates, blesses, and returns a new
instance. If called as an object method, produces and returns a
copy of an instance.

The copy is a *shallow* copy; any references will be shared by the
instance upon which the method is called and the returned newborn.

If a list of key-value pairs is passed as arguments to the method,
they are added to the copy, overwriting any values with the same
key that may have been copied from the original.

=item copy_instance_with_methods

If called as a class method, creates, blesses, and returns a new
instance. If called as an object method, produces and returns a
copy of an instance.

The copy is a *shallow* copy; any references will be shared by the
instance upon which the method is called and the returned newborn.

Accepts name-value pair arguments, or a reference to hash of such
pairs, and calls the named method on the copy for each with the supplied value as
a single argument before the copy is returned.

=back

B<Parameters>: The following parameters are supported:

=over 4

=item init_method

The name of the method to call after creating a new instance. Defaults to 'init'.

=back

=cut

sub new {
  {
    '-import' => { 
      # 'Template::Generic:generic' => '*',
    },
    'interface' => {
      default		=> 'with_methods',
      with_values	=> 'with_values',
      with_methods	=> 'with_methods', 	
      with_init		=> 'with_init',
      and_then_init     => 'and_then_init',
      new_and_init   => { '*'=>'new_with_init', 'init'=>'method_init'},
      instance_with_methods => 'instance_with_methods', 	
      copy	    	=> 'copy_with_values',
      copy_with_values	=> 'copy_with_values',
      copy_with_methods	=> 'copy_with_methods', 	
      copy_instance_with_values	=> 'copy_instance_with_values',
      copy_instance_with_methods => 'copy_instance_with_methods', 	
    },
    'behavior' => {
      'with_methods' => q{
	  $self = _EMPTY_NEW_INSTANCE_;
	  _CALL_METHODS_FROM_HASH_
	  return $self;
        },
      'with_values' => q{
	  $self = _EMPTY_NEW_INSTANCE_;
	  _SET_VALUES_FROM_HASH_
	  return $self;
	},
      'with_init' => q{
	  $self = _EMPTY_NEW_INSTANCE_;
	  my $init_method = $m_info->{'init_method'} || 'init';
	  $self->$init_method( @_ );
	  return $self;
	},
      'and_then_init' => q{
	  $self = _EMPTY_NEW_INSTANCE_;
	  _CALL_METHODS_FROM_HASH_
	  my $init_method = $m_info->{'init_method'} || 'init';
	  $self->$init_method();
	  return $self;
	},
      'instance_with_methods' => q{
	  $self = ref ($self) ? $self : _EMPTY_NEW_INSTANCE_;
	  _CALL_METHODS_FROM_HASH_
	  return $self;
        },
      'copy_with_values' => q{ 
	  @_ = ( %$self, @_ );
	  $self = _EMPTY_NEW_INSTANCE_;
	  _SET_VALUES_FROM_HASH_
	  return $self;
	},
      'copy_with_methods' => q{ 
	  @_ = ( %$self, @_ );
	  $self = _EMPTY_NEW_INSTANCE_;
	  _CALL_METHODS_FROM_HASH_
	  return $self;
	},
      'copy_instance_with_values' => q{
	  $self = bless { ( ref $self ? %$self : () ) }, _SELF_CLASS_;
	  _SET_VALUES_FROM_HASH_
	  return $self;
	},
      'copy_instance_with_methods' => q{
	  $self = bless { ref $self ? %$self : () }, _SELF_CLASS_;
	  _CALL_METHODS_FROM_HASH_
	  return $self;
	},
    },
  }
}

########################################################################

=head2 scalar Accessor

A generic scalar-value accessor meta-method which serves as an
abstraction for basic "get_set" methods and numerous related
interfaces

  use Class::MakeMethods -MakerClass => "...", 
	scalar => [ 'foo', 'bar' ];
  ...
  $self->foo( 'my new foo value' );
  print $self->foo();

(Note that while you can use the scalar methods to store references to
various data structures, there are other meta-methods defined below that
may be more useful for managing references to arrays, hashes, and objects.)

B<Interfaces>: The following calling interfaces are available.

=over 4

=item get_set (default)

Provides get_set method for I<*>.

Example: Create method foo, which sets the value of 'foo' for this
instance if an argument is passed in, and then returns the value
whether or not it's been changed:

  use Class::MakeMethods -MakerClass => "...", 
    scalar => [ 'foo' ];

=item get_protected_set

Provides an get_set accessor for I<*> that croaks if a new value
is passed in from a package that is not a subclass of the declaring
one.

=item get_private_set

Provides an get_set accessor for I<*> that croaks if a new value
is passed in from a package other than the declaring one.

=item read_only

Provides an accessor for I<*> that does not modify its value. (Its
initial value would have to be set by some other means.)

=item eiffel

Provides get behavior as I<*>, and set behavior as set_I<*>.

Example: Create methods bar which returns the value of 'bar' for
this instance (takes no arguments), and set_bar, which sets the
value of 'bar' (no return):

  use Class::MakeMethods -MakerClass => "...", 
    scalar => [ --eiffel => 'bar' ];

=item java

Provides get behavior as getI<*>, and set behavior as setI<*>.

Example: Create methods getBaz which returns the value of 'Baz'
for this instance (takes no arguments), and setBaz, which sets the
value for this instance (no return):

  use Class::MakeMethods -MakerClass => "...", 
    scalar => [ --java => 'Baz' ];


=item init_and_get

Creates methods which cache their results in a hash key.

Provides the get_init behavior for I<*>, and an delete behavior for clear_I<*>. 
Specifies default value for init_method parameter of init_I<*>.


=item with_clear

Provides get_set behavior for I<*>, and a clear_I<*> method. 

=back


B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get_set

If no argument is provided, returns the value of the current instance. The value defaults to undef.

If an argument is provided, it is stored as the value of the current
instance (even if the argument is undef), and that value is returned.

Also available as get_protected_set and get_private_set, which are
available for public read-only access, but have access control
limitations.

=item get

Returns the value from the current instance.

=item set

Sets the value for the current instance. If called with no arguments,
the value is set to undef. Does not return a value.

=item clear

Sets value to undef. 

=item get_set_chain

Like get_set, but if called with an argument, returns the object it was called on. This allows a series of mutators to be called as follows:

  package MyObject;
  use Class::MakeMethods (
    'Template::Hash:scalar --get_set_chain' => 'foo bar baz'
  );
  ...
  
  my $obj = MyObject->new->foo('Foozle');
  $obj->bar("none")->baz("Brazil");
  print $obj->foo, $obj->bar, $obj->baz;

=item get_set_prev 

Like get_set, but if called with an argument, returns the previous value before it was changed to the new one. 

=item get_init

If the value is currently undefined, calls the init_method. Returns the value.

=back

B<Parameters>: The following parameters are supported:

=over 4

=item init_method

The name of a method to be called to initialize this meta-method. 

Only used by the get_init behavior.

=back

=cut

sub scalar {
  {
    '-import' => { 'Template::Generic:generic' => '*' },
    'interface' => {
      default	    => 'get_set',
      get_set       => { '*'=>'get_set' },
      noclear       => { '*'=>'get_set' },
      with_clear    => { '*'=>'get_set', 'clear_*'=>'clear' },
      
      read_only	    => { '*'=>'get' },
      get_private_set    => 'get_private_set',
      get_protected_set    => 'get_protected_set',
      
      eiffel	    => { '*'=>'get',     'set_*'=>'set_return' },
      java	    => { 'get*'=>'get',  'set*'=>'set_return' },
      
      init_and_get  => { '*'=>'get_init', -params=>{ init_method=>'init_*' } },
      
    },
    'behavior' => {
      'get'	=> q{ _GET_VALUE_ },
      'set'	=> q{ _SET_VALUE_{ shift() } },
      'set_return' => q{ _BEHAVIOR_{set}; return },
      'clear'	=> q{ _SET_VALUE_{ undef } },
      'defined'	=> q{ defined _VALUE_ },
      
      'get_set'	=> q { 
	  if ( scalar @_ ) {
	    _BEHAVIOR_{set}
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
      'get_set_chain' => q { 
	  if ( scalar @_ ) {
	    _BEHAVIOR_{set};
	    return _SELF_
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
      'get_set_prev' => q { 
	  my $value = _BEHAVIOR_{get};
	  if ( scalar @_ ) {
	    _BEHAVIOR_{set};
	  }
	  return $value;
	},
      
      'get_private_set' => q{ 
	  if ( scalar @_ ) { 
	    _PRIVATE_SET_VALUE_{ shift() } 
	    } else {
	    _BEHAVIOR_{get}
	  }
	},
      'get_protected_set' => q{ 
	  if ( scalar @_ ) { 
	    _PROTECTED_SET_VALUE_{ shift() } 
	    } else {
	    _BEHAVIOR_{get}
	  }
	},
      'get_init' => q{
	  if ( ! defined _VALUE_ ) {
	    my $init_method = _ATTR_REQUIRED_{'init_method'};
	    _SET_VALUE_{ _SELF_->$init_method( @_ ) };
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
      
    },
    'params' => {
      new_method => 'new'
    },
  } 
}

########################################################################

=head2 string Accessor

A generic scalar-value accessor meta-method which serves as an
abstraction for basic "get_set" methods and numerous related
interfaces

  use Class::MakeMethods -MakerClass => "...", 
	string => [ 'foo', 'bar' ];
  ...
  $self->foo( 'my new foo value' );
  print $self->foo();

This meta-method extends the scalar meta-method, and supports the same interfaces and parameters.

However, it generally treats values as strings, and can not be used to store references.

B<Interfaces>: In addition to those provided by C<scalar>, the following calling interfaces are available.

=over 4

=item -get_concat

Provides the get_concat behavior for I<*>, and a clear_I<*> method.  

Example: 

  use Class::MakeMethods
    get_concat => { name => 'words', join => ", " };

  $obj->words('foo');
  $obj->words('bar');
  $obj->words() eq 'foo, bar';

=back

B<Behaviors>: In addition to those provided by C<scalar>, the following types of accessor methods are available.

=over 4

=item concat

Concatenates the argument value with the existing value.

=item get_concat

Like get_set except sets do not clear out the original value, but instead
concatenate the new value to the existing one.

=back

B<Parameters>: In addition to those provided by C<scalar>, the following parameters are supported.

=over 4

=item join

If the join parameter is defined, each time the get_concat behavior
is invoked, it will glue its argument onto any existing value with
the join string as the separator. The join field is applied I<between>
values, not prior to the first or after the last. Defaults to undefined

=back

=cut

sub string {
  {
    '-import' => { 'Template::Generic:scalar' => '*' },
    'interface' => {
      get_concat    => { '*'=>'get_concat', 'clear_*'=>'clear', 
		-params=>{ 'join' => '' }, },
    },
    'params' => {
      'return_value_undefined' => '',
    },
    'behavior' => {
      'get' => q{ 
	  if ( defined( my $value = _GET_VALUE_) ) { 
	    _GET_VALUE_;
	  } else {  
	    _STATIC_ATTR_{return_value_undefined};
	  }
	},
      'set' => q{ 
	  my $new_value = shift();
	  _SET_VALUE_{ "$new_value" };
  	},
      'concat' => q{ 
	  my $new_value = shift();
	  if ( defined( my $value = _GET_VALUE_) ) { 
	    _SET_VALUE_{join( _STATIC_ATTR_{join}, $value, $new_value)};
	  } else {
	    _SET_VALUE_{ "$new_value" };
	  }
  	},
      'get_concat' => q{
	  if ( scalar @_ ) {
	    _BEHAVIOR_{concat}
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
    },
  }
}

########################################################################

=head2 string_index

  string_index => [ qw / foo bar baz / ]

Creates string accessor methods, like string above, but also
maintains a static hash index in which each object is stored under
the value of the field when the slot is set. 

This is a unique index, so only one object can have a given key.
If an object has a slot set to a value which another object is
already set to the object currently set to that value has that slot
set to undef and the new object will be put into the hash under
that value. 

Objects with undefined values are not stored in the index.

Note that to free items from memory, you must clear these values!

B<Methods>:

=over 4

=item *

The method find_x is defined which if called with any arguments
returns a list of the objects stored under those values in the
hash. Called with no arguments, it returns a reference to the hash.

=back

B<Profiles>:

=over 4

=item *

find_or_new

  'string_index -find_or_new' => [ qw / foo bar baz / ]

Just like string_index except the find_x method is defined to call the new
method to create an object if there is no object already stored under
any of the keys you give as arguments.

=back

=cut

sub string_index {
  ( {
    '-import' => { 'Template::Generic:generic' => '*' },
    'params' => { 
      'new_method' => 'new',
    },
    'interface' => {
      default => { '*'=>'get_set', 'clear_*'=>'clear', 'find_*'=>'find' },
      find_or_new=>{'*'=>'get_set', 'clear_*'=>'clear', 'find_*'=>'find_or_new'}
    },
    'code_expr' => { 
      _REMOVE_FROM_INDEX_ => q{ 
	  if (defined ( my $old_v = _GET_VALUE_ ) ) {
	    delete _ATTR_{'index'}{ $old_v };
	  }
	},
      _ADD_TO_INDEX_ => q{ 
	  if (defined ( my $new_value = _GET_VALUE_ ) ) {
	    if ( my $old_item = _ATTR_{'index'}{$new_value} ) {
	      # There's already an object stored under that value so we
	      # need to unset it's value.
	      # And maybe issue a warning? Or croak?
	      my $m_name = _ATTR_{'name'};
	      $old_item->$m_name( undef );
	    }
	    
	    # Put ourself in the index under that value
	    _ATTR_{'index'}{$new_value} = _SELF_;
	  }
	},
      _INDEX_HASH_ => '_ATTR_{index}',
    },
    'behavior' => {
      '-init' => [ sub { 
	  my $m_info = $_[0]; 
	  defined $m_info->{'index'} or $m_info->{'index'} = {};
	  return;
	} ],
      'get' => q{ 
	  return _GET_VALUE_; 
	},
      'set' => q{ 
	  my $new_value = shift;
	  
	  _REMOVE_FROM_INDEX_
	  
	  # Set our value to new
	  _SET_VALUE_{ $new_value };
	  
	  _ADD_TO_INDEX_
	},
      'get_set' => q{
	  if ( scalar @_ ) {
	    _BEHAVIOR_{set}
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
      'clear' => q{
	  _REMOVE_FROM_INDEX_
	  _SET_VALUE_{ undef };
	},
      'find' => q{
	  if ( scalar @_ ) {
	    return @{ _ATTR_{'index'} }{ @_ };
	  } else {
	    return _INDEX_HASH_
	  }
	},
      'find_or_new' => q{
	  if ( scalar @_ ) {
	    my $class = _SELF_CLASS_;
	    my $new_method = _ATTR_REQUIRED_{'new_method'};
	    my $m_name = _ATTR_{'name'};
	    foreach (@_) {
	      next if defined _ATTR_{'index'}{$_};
	      # create new instance and set its value; it'll add itself to index
	      $class->$new_method()->$m_name($_);
	    }
	    return @{ _ATTR_{'index'} }{ @_ };
	  } else {
	    return _INDEX_HASH_
	  }
	},
    },
  } )
}

########################################################################

=head2 number Accessor

A generic scalar-value accessor meta-method which serves as an
abstraction for basic "get_set" methods and numerous related
interfaces

  use Class::MakeMethods -MakerClass => "...", 
	string => [ 'foo', 'bar' ];
  ...
  $self->foo( 23 );
  print $self->foo();

This meta-method extends the scalar meta-method, and supports the same interfaces and parameters.

However, it generally treats values as numbers, and can not be used to store strings or references.

B<Interfaces>: In addition to those provided by C<scalar>, the following calling interfaces are available.

=over 4

=item -counter

Provides the numeric get_set behavior for I<*>, and numeric I<*>_incr and I<*>_reset methods.  

=back

B<Behaviors>: In addition to those provided by C<scalar>, the following types of accessor methods are available.

=over 4

=item get_set

The get_set behavior is similar to the default scalar behavior except that empty values are treated as zero.

=item increment

If no argument is provided, increments the I<hash_key> value by 1.
If an argument is provided, the value is incremented by that amount.
Returns the increased value.

=item clear

Sets the value to zero.

=back

=cut

sub number {
  {
    '-import' => { 'Template::Generic:scalar' => '*' },
    'interface' => {
      counter       => { '*'=>'get_set', '*_incr'=>'incr', '*_reset'=>'clear' },
    },
    'params' => {
      'return_value_undefined' => 0,
    },
    'behavior' => {
      'get_set' => q{ 
	  if ( scalar @_ ) {
	    local $_ = shift;
	    if ( defined $_ ) {
	      croak "Can't set _STATIC_ATTR_{name} to non-numeric value '$_'"
					if ( /[^\+\-\,\d\.e]/ );
	      s/\,//g; 
	    }
	    _SET_VALUE_{ $_ }
	  }
	  defined( _GET_VALUE_ ) ? _GET_VALUE_ 
				 : _STATIC_ATTR_{return_value_undefined}
	},
      'incr' => q{ 
	  _VALUE_ ||= 0; 
	  _VALUE_ += ( scalar @_ ? shift : 1 ) 
	},
      'decr' => q{ 
	  _VALUE_ ||= 0; 
	  _VALUE_ -= ( scalar @_ ? shift : 1 ) 
	},
    },
  }
}

########################################################################

=head2 boolean Accessor

A generic scalar-value accessor meta-method which serves as an abstraction for basic "get_set" methods and numerous related interfaces

  use Class::MakeMethods -MakerClass => "...", 
	string => [ 'foo', 'bar' ];
  ...
  $self->foo( 1 );
  print $self->foo();
  $self->clear_foo;

This meta-method extends the scalar meta-method, and supports the
same interfaces and parameters. However, it generally treats values
as true-or-false flags, and can not be used to store strings,
numbers, or references.

B<Interfaces>: 

=over 4 

=item flag_set_clear (default)

Provides the get_set behavior for I<*>, and set_I<*> and clear_I<*> methods to set the value to true or false.  

=back

B<Behaviors>: In addition to those provided by C<scalar>, the following types of accessor methods are available.

=over 4

=item get_set

The get_set behavior is similar to the get_set scalar behavior
except that empty or false values are treated as zero, and true
values are treated as zero.

=item set_true

Sets the value to one.

=item set_false

Sets the value to zero.
=back

=cut

sub boolean {
  {
    '-import' => { 'Template::Generic:scalar' => '*' },
    'interface' => {
      default => {'*'=>'get_set', 'clear_*'=>'set_false',
						      'set_*'=>'set_true'},
      flag_set_clear => {'*'=>'get_set', 'clear_*'=>'set_false',
						      'set_*'=>'set_true'},
    },
    'behavior' => {
      'get'	=> q{ _GET_VALUE_ || 0 },
      'set'	=> q{ 
	if ( shift ) {
	  _BEHAVIOR_{set_true}
	} else {
	  _BEHAVIOR_{set_false}
	}
      },      
      'set_true' => q{ _SET_VALUE_{ 1 } },
      'set_false' => q{ _SET_VALUE_{ 0 } },
      'set_value' => q{ 
	_SET_VALUE_{ scalar @_ ? shift : 1 }
      },
    },
  }
}

########################################################################

=head2 bits Accessor

A generic accessor for bit-field values.

The difference between 'Template::Generic:bits' and
'Template::Generic:boolean' is that all flags created with this
meta-method are stored in a single vector for space efficiency.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides get_set behavior for I<*>, a set_I<*> method which sets
the value to true and a clear_I<*> method which sets the value to
false.

Also defines methods named bits, bit_fields, and bit_dump with the
behaviors below. These methods are shared across all of the boolean
meta-methods defined by a single class.

=item class_methods

.

=back

B<Basic Behaviors>: The following types of bit-level accessor methods are available.

=over 4

=item get_set

Returns the value of the named flag.  If called with an argument, it first
sets the named flag to the truth-value of the argument.

=item set_true

Sets the value to true.

=item set_false

Sets the value to false.

=back

B<Group Methods>: The following types of methods manipulate the overall vector value.

=over 4

=item bits

Returns the vector containing all of the bit fields (remember however
that a vector containing all 0 bits is still true).

=item bit_dump

Returns a hash of the flag-name/flag-value pairs.

=item bits_size

Returns the number of bits that can fit into the current vector.

=item bits_complement

Returns the twos-complement of the vector.

=item bit_pos_get

Takes a single argument and returns the value of the bit stored in that position.

=item bit_pos_set

Takes two arguments and sets the bit stored in the position of the first argument to the value of the second argument.

=back

B<Class Methods>: The following types of class methods are available.

=over 4

=item bit_names

Returns a list of all the flags by name.

=back

=cut

sub bits {
  {
    '-import' => { 
      # 'Template::Generic:generic' => '*',
    },
    'interface' => {
      default => { 
	'*'=>'get_set', 'set_*'=>'set_true', 'clear_*'=>'set_false',
	'bit_fields'=>'bit_names', 'bit_string'=>'bit_string',
	'bit_list'=>'bit_list', 'bit_hash'=>'bit_hash',
      },
      class_methods => { 
	'bit_fields'=>'bit_names', 'bit_string'=>'bit_string', 
	'bit_list'=>'bit_list', 'bit_hash'=>'bit_hash',
      },
    },
    'code_expr' => {
      '_VEC_POS_VALUE_{}' => 'vec(_VALUE_, *, 1)',
      _VEC_VALUE_ => '_VEC_POS_VALUE_{ _ATTR_{bfp} }',
      _CLASS_INFO_ => '$Class::MakeMethods::Template::Hash::bits{_STATIC_ATTR_{target_class}}',
    },
    'modifier' => {
      '-all' => [ q{
	  defined _VALUE_ or _VALUE_ = "";
	  *
	} ],
    },
    'behavior' => {
      '-init' => sub {
	my $m_info = $_[0]; 
	
	$m_info->{bfp} ||= do {
	  my $array = ( $Class::MakeMethods::Template::Hash::bits{$m_info->{target_class}} ||= [] );
	  my $idx;
	  foreach ( 0..$#$array ) { 
	    if ( $array->[$_] eq $m_info->{'name'} ) { $idx = $_; last }
	  }
          unless ( $idx ) {
	    push @$array, $m_info->{'name'}; 
	    $idx = $#$array;
	  }
	  $idx;
	};
	
	return;	
      },
      'bit_names' => q{
	  @{ _CLASS_INFO_ };
	},
      'bit_string' => q{
	  if ( @_ ) {
	    _SET_VALUE_{ shift @_ };
	  } else {
	    _VALUE_;
	  }
	},
      'bits_size' => q{
	  8 * length( _VALUE_ );
	},
      'bits_complement' => q{
	  ~ _VALUE_;
	},
      'bit_hash' => q{
	  my @bits = @{ _CLASS_INFO_ };
	  if ( @_ ) {
	    my %bits = @_;
	    _SET_VALUE_{ pack 'b*', join '', map { $_ ? 1 : 0 } @bits{ @bits } };
	    return @_;
	  } else {
	    map { $bits[$_], vec(_VALUE_, $_, 1) } 0 .. $#bits
	  }
	},
      'bit_list' => q{
	  if ( @_ ) {
	    _SET_VALUE_{ pack 'b*', join( '', map { $_ ? 1 : 0 } @_ ) };
	    return map { $_ ? 1 : 0 } @_;
	  } else {
	    split //, unpack "b*", _VALUE_;
	  }
	},
      'bit_pos_get' => q{
	  vec(_VALUE_, $_[0], 1)
	},
      'bit_pos_set' => q{
	  vec(_VALUE_, $_[0], 1) = ( $_[1] ? 1 : 0 )
	},
      
      'get_set' => q{
	  if ( @_ ) {
	    _VEC_VALUE_ = ( $_[0] ? 1 : 0 );
	  } else {
	    _VEC_VALUE_;
	  }
	},
      'get' => q{
	  _VEC_VALUE_;
	},
      'set' => q{
	  _VEC_VALUE_ = ( $_[0] ? 1 : 0 );
	},
      'set_true' => q{
	  _VEC_VALUE_ = 1;
	},
      'set_false' => q{
	  _VEC_VALUE_ = 0;
	},
  
    },
  }
}


########################################################################

=head2 array Accessor

Creates accessor methods for manipulating arrays of values.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides get_set behavior for I<*>, and I<verb>_I<*> methods for the non-get behaviors below.

=item minimal

Provides get_set behavior for I<*>, and I<*>_I<verb> methods for clear behavior.

=item get_set_items

Provides the get_set_items for I<*>.

=item x_verb

Provides get_push behavior for I<*>, and I<*>_I<verb> methods for the non-get behaviors below.

=item get_set_ref

Provides the get_set_ref for I<*>.

=item get_set_ref_help

Provides the get_set_ref for I<*>, and I<verb>_I<*> methods for the non-get behaviors below.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get_set_items

Called with no arguments returns a reference to the array stored in the slot.

Called with one simple scalar argument it treats the argument as an index
and returns the value stored under that index.

Called with more than one argument, treats them as a series of index/value
pairs and adds them to the array.

=item get_push

If arguments are passed, these values are pushed on to the list; if a single array ref is passed, its values are used as the arguments.

This method returns the list of values stored in the slot. In an array
context it returns them as an array and in a scalar context as a
reference to the array.

=item get_set_ref

If arguments are passed, these values are placed on the list, replacing the current contents; if a single array ref is passed, its values are used as the arguments.

This method returns the list of values stored in the slot. In an array
context it returns them as an array and in a scalar context as a
reference to the array.

=item get_set

If arguments are passed, these values are placed on the list, replacing the current contents.

This method returns the list of values stored in the slot. In an array
context it returns them as an array and in a scalar context as a
reference to the array.


=item push

Append items to tail.

=item pop

Remove an item from the tail.

=item shift

Remove an item from the front.

=item unshift

Prepend items to front.

=item splice

Remove or replace items.

=item clear

Remove all items.

=item count

Returns the number of item in the list.

=back

=cut

sub array {
  {
    '-import' => { 'Template::Generic:generic' => '*' },
    'interface' => {
      default => { 
	'*'=>'get_set', 
	map( ($_.'_*' => $_ ), qw( pop push unshift shift splice clear count )),
	map( ('*_'.$_ => $_ ), qw( ref index ) ),
      },
      minimal => { '*'=>'get_set', '*_clear'=>'clear' },
      get_set_items => { '*'=>'get_set_items' },
      x_verb => { 
	'*'=>'get_set', 
	map( ('*_'.$_ => $_ ), qw(pop push unshift shift splice clear count ref index )),
      },
      get_set_ref => { '*'=>'get_set_ref' },
      get_set_ref_help => { '*'=>'get_set_ref', '-base'=>'default' },
    },
    'modifier' => {
      '-all' => [ q{ _ENSURE_REF_VALUE_; * } ],
    },
    'code_expr' => { 
      '_ENSURE_REF_VALUE_' => q{ _REF_VALUE_ ||= []; },
    },
    'behavior' => {
      'get_set' => q{
	  @{_REF_VALUE_} = @_ if ( scalar @_ );
 	  return wantarray ? @{_GET_VALUE_} : _REF_VALUE_;
	},
      'get_set_ref' => q{
	  @{_REF_VALUE_} = ( ( scalar(@_) == 1 and ref($_[0]) eq 'ARRAY' ) ? @{$_[0]} : @_ ) if ( scalar @_ );
 	  return wantarray ? @{_GET_VALUE_} : _REF_VALUE_;
	},
      'get_push' => q{
	  push @{_REF_VALUE_}, map { ref $_ eq 'ARRAY' ? @$_ : ($_) } @_;
 	  return wantarray ? @{_GET_VALUE_} : _REF_VALUE_;
	},
      'ref' => q{ _REF_VALUE_ },
      'get' => q{ return wantarray ? @{_GET_VALUE_} : _REF_VALUE_ },
      'set' => q{ @{_REF_VALUE_} = @_ },
      'pop' => q{ pop @{_REF_VALUE_} },
      'push' => q{ push @{_REF_VALUE_}, @_ },
      'shift' => q{ shift @{_REF_VALUE_} },
      'unshift' => q{ unshift @{_REF_VALUE_}, @_ },
      'slice' => q{ _GET_VALUE_->[ @_ ] },
      'splice' => q{ splice @{_REF_VALUE_}, shift, shift, @_ },
      'count' => q{ scalar @{_GET_VALUE_} },
      'clear' => q{ @{ _REF_VALUE_ } = () },
      'index' => q{
	  my $list = _REF_VALUE_; 
	  ( scalar(@_) == 1 ) ? $list->[shift]
	  : wantarray ? (map $list->[$_], @_) : [map $list->[$_], @_] 
	},
      'get_set_items' => q{
	  if ( scalar @_ == 0 ) {
	    return _REF_VALUE_;
	  } elsif ( scalar @_ == 1 ) {
	    return _GET_VALUE_->[ shift() ];
	  } else {
	    _BEHAVIOR_{set_items}
	  }
	},
      'set_items' => q{
	! (@_ % 2) or croak "Odd number of items in assigment to _STATIC_ATTR_{name}";
	while ( scalar @_ ) {
	  my ($index, $value) = splice @_, 0, 2;
	  _REF_VALUE_->[ $index ] = $value;
	}
	return _REF_VALUE_;
      },
    }
  }
}

########################################################################

=head2 hash Accessor

Creates accessor methods for manipulating hashes of key-value pairs.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides get_set behavior for I<*>, and I<*>_I<verb> methods for most of the other behaviors below.

=item get_set_items

Provides the get_set_items for I<*>.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get_set_items

Called with no arguments returns a reference to the hash stored.

Called with one simple scalar argument it treats the argument as a key
and returns the value stored under that key.

Called with more than one argument, treats them as a series of key/value
pairs and adds them to the hash.

=item get_push

Called with no arguments returns the hash stored, as a hash
in a list context or as a reference in a scalar context.

Called with one simple scalar argument it treats the argument as a key
and returns the value stored under that key.

Called with one array reference argument, the array elements
are considered to be be keys of the hash. x returns the list of values
stored under those keys (also known as a I<hash slice>.)

Called with one hash reference argument, the keys and values of the
hash are added to the hash.

Called with more than one argument, treats them as a series of key/value
pairs and adds them to the hash.

=item get_set

Like get_push, except if called with more then one argument, empties
the current hash items before adding those arguments to the hash.

=item push

Called with one hash reference argument, the keys and values of the
hash are added to the hash.

Called with more than one argument, treats them as a series of key/value
pairs and adds them to the hash.

=item keys

Returns a list of the keys of the hash.

=item values

Returns a list of the values in the hash.

=item tally

Takes a list of arguments and for each scalar in the list increments the
value stored in the hash and returns a list of the current (after the
increment) values.

=item exists

Takes a single key, returns whether that key exists in the hash.

=item delete

Takes a list, deletes each key from the hash, and returns the corresponding values.

=item clear

Resets hash to empty.

=back

=cut

sub hash {
  {
    '-import' => { 'Template::Generic:generic' => '*' },
    'interface' => {
      'default' => { 
	'*'=>'get_set', 
	map {'*_'.$_ => $_} qw(push set keys values delete exists tally clear),
      },
      get_set_items => { '*'=>'get_set_items' },
    },
    'modifier' => {
      '-all' => [ q{ _ENSURE_REF_VALUE_; * } ],
    },
    'code_expr' => { 
      '_ENSURE_REF_VALUE_' => q{ _REF_VALUE_ ||= {}; },
      _HASH_GET_ => q{
	( wantarray ? %{_GET_VALUE_} : _REF_VALUE_ )
      },
      _HASH_GET_VALUE_ => q{
	  ( ref $_[0] eq 'ARRAY' ? @{ _GET_VALUE_ }{ @{ $_[0] } } 
				 : _REF_VALUE_->{ $_[0] } )
      },
      _HASH_SET_ => q{
	! (@_ % 2) or croak "Odd number of items in assigment to _STATIC_ATTR_{name}";
	%{_REF_VALUE_} = @_
      },
      _HASH_PUSH_ => q{
	! (@_ % 2) 
	  or croak "Odd number of items in assigment to _STATIC_ATTR_{name}";
	my $count;
	while ( scalar @_ ) { 
	  local $_ = shift; 
	  _REF_VALUE_->{ $_ } = shift();
	  ++ $count;
	}
	$count;
      },
    },
    'behavior' => {
      'get_set' => q {
	  # If called with no arguments, return hash contents
	  return _HASH_GET_ if (scalar @_ == 0);
	  
	  # If called with a hash ref, act as if contents of hash were passed
	  # local @_ = %{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );
	  @_ = %{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );
	  
	  # If called with an index, get that value, or a slice for array refs
          return _HASH_GET_VALUE_ if (scalar @_ == 1 );
	
	  # Push on new values and return complete set
	  _HASH_SET_;
	  return _HASH_GET_;
	},

      'get_push' => q{
	  # If called with no arguments, return hash contents
	  return _HASH_GET_ if (scalar @_ == 0);
	  
	  # If called with a hash ref, act as if contents of hash were passed
	  # local @_ = %{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );
	  @_ = %{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );
	
	  # If called with an index, get that value, or a slice for array refs
          return _HASH_GET_VALUE_ if (scalar @_ == 1 );
	
	  # Push on new values and return complete set
	  _HASH_PUSH_;
	  return _HASH_GET_;
	},
      'get_set_items' => q{
	  if ( scalar @_ == 0 ) {
	    return _REF_VALUE_;
	  } elsif ( scalar @_ == 1 ) {
	    return _REF_VALUE_->{ shift() };
	  } else {
	    while ( scalar @_ ) {
	      my ($index, $value) = splice @_, 0, 2;
	      _REF_VALUE_->{ $index } = $value;
	    }
	    return _REF_VALUE_;
	  }
	},
      'get' => q{ _HASH_GET_ },
      'set' => q{ _HASH_SET_ },
      'push' => q{ 
	  # If called with a hash ref, act as if contents of hash were passed
	  # local @_ = %{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );
	  @_ = %{ $_[0] } if ( scalar @_ == 1 and ref $_[0] eq 'HASH' );

	  _HASH_PUSH_ 
	},

      'keys' => q{ keys %{_GET_VALUE_} },
      'values' => q{ values %{_GET_VALUE_} },
      'unique_values' => q{ 
	    values %{ { map { $_=>$_ } values %{_GET_VALUE_} } } 
	},
      'delete' => q{ scalar @_ <= 1 ? delete @{ _REF_VALUE_ }{ $_[0] } 
			      : map { delete @{ _REF_VALUE_ }{ $_ } } (@_) },
      'exists' => q{
	  return 0 unless defined _GET_VALUE_;
	  foreach (@_) { return 0 unless exists ( _REF_VALUE_->{$_} ) }
	  return 1;
	},
      'tally' => q{ map { ++ _REF_VALUE_->{$_} } @_ },
      'clear' => q{ %{ _REF_VALUE_ } = () },
      'ref' => q{ _REF_VALUE_ },
    },
  }
}

########################################################################

=head2 tiedhash Accessor

A variant of Generic:hash which initializes the hash by tieing it to a caller-specified package.

See the documentation on C<Generic:hash> for interfaces and behaviors.

B<Parameters>: The following parameters I<must> be provided:

=over 4

=item tie

I<Required>. The name of the class to tie to.
I<Make sure you have C<use>d the required class>.

=item args

I<Required>. Additional arguments for the tie, as an array ref.

=back 

Example:

  use Class::MakeMethods
    tie_hash => [ hits => { tie => q/Tie::RefHash/, args => [] } ];

  use Class::MakeMethods
    tie_hash => [ [qw(hits errors)] => { tie => q/Tie::RefHash/, args => [] } ];

  use Class::MakeMethods
    tie_hash => [ { name => hits, tie => q/Tie::RefHash/, args => [] } ];

=cut

sub tiedhash {
  {
    '-import' => { 'Template::Generic:hash' => '*' },
    'modifier' => {
      '-all' => [ q{
	  if ( ! defined _GET_VALUE_ ) {
	    %{ _REF_VALUE_ } = ();
	    tie %{ _REF_VALUE_ }, _ATTR_REQUIRED_{tie}, @{ _ATTR_{args} };
	  }
	  *
	} ],
    },
  }
}

########################################################################

=head2 hash_of_arrays Accessor

Creates accessor methods for manipulating hashes of array-refs.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides get behavior for I<*>, and I<*>_I<verb> methods for the other behaviors below.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get

Returns all the values for all the given keys, in order.  If no keys are
given, returns all the values (in an unspecified key order).

The result is returned as an arrayref in scalar context.  This arrayref
is I<not> part of the data structure; messing with it will not affect
the contents directly (even if a single key was provided as argument.)

If any argument is provided which is an arrayref, then the members of
that array are used as keys.  Thus, the trivial empty-key case may be
utilized with an argument of [].

=item keys

Returns the keys of the hash.  As an arrayref in scalar context.

=item exists

Takes a list of keys, and returns whether all of the key exists in the hash
(i.e., the C<and> of whether the individual keys exist).

=item delete

Takes a list, deletes each key from the hash.

=item push

Takes a key, and some values.  Pushes the values onto the list denoted
by the key.  If the first argument is an arrayref, then each element of
that arrayref is treated as a key and the elements pushed onto each
appropriate list.

=item pop

Takes a list of keys, and pops each one.  Returns the list of popped
elements.  undef is returned in the list for each key that is has an
empty list.

=item unshift

Like push, only the from the other end of the lists.

=item shift

Like pop, only the from the other end of the lists.

=item splice

Takes a key, offset, length, and a values list.  Splices the list named
by the key.  Anything from the offset argument (inclusive) may be
omitted.  See L<perlfunc/splice>.

=item clear

Takes a list of keys.  Resets each named list to empty (but does not
delete the keys.)

=item count

Takes a list of keys.  Returns the sum of the number of elements for
each named list.

=item index

Takes a key, and a list of indices.  Returns a list of each item at the
corresponding index in the list of the given key.  Uses undef for
indices beyond range.

=item remove

Takes a key, and a list of indices.  Removes each corresponding item
from the named list.  The indices are effectively looked up at the point
of call -- thus removing indices 3, 1 from list (a, b, c, d) will
remove (d) and (b).

=item sift

Takes a key, and a set of named arguments, which may be a list or a hash
ref.  Removes list members based on a grep-like approach.

=over 4

=item   filter

The filter function used (as a coderef).  Is passed two arguments, the
value compared against, and the value in the list that is potential for
grepping out.  If returns true, the value is removed.  Default is C<sub { $_[0] == $_[1] }>.

=item   keys

The list keys to sift through (as an arrayref).  Unknown keys are
ignored.  Default: all the known keys.

=item   values

The values to sift out (as an arrayref).  Default: C<[undef]>

=back

=back

=cut

sub hash_of_arrays {
  {
    '-import' => {  'Template::Generic:hash' => '*' },
    'interface' => {
      default => { 
	'*'=>'get', 
	map( ('*_'.$_ => $_ ), qw(keys exists delete pop push shift unshift splice clear count index remove sift last set )),
      },
    },
    'behavior' => {
      'get' => q{
	  my @Result;
	    
	  if ( ! scalar @_ ) {
	    @Result = map @$_, values %{_VALUE_};
	    } elsif ( scalar @_ == 1 and ref ($_[0]) eq 'ARRAY' ) {
	    @Result = map @$_, @{_VALUE_}{@{$_[0]}};
	  } else {
	    my @keys = map { ref ($_) eq 'ARRAY' ? @$_ : $_ }
			grep exists _VALUE_{$_}, @_;
	    @Result = map @$_, @{_VALUE_}{@keys};
	  }
	    
	  return wantarray ? @Result : \@Result;
	},
      'pop' => q{
	  map { pop @{_VALUE_->{$_}} } @_
	},
      'last' => q{
	  map { _VALUE_->{$_}->[-1] } @_
	},
      'push' => q{
	  for ( ( ref ($_[0]) eq 'ARRAY' ? @{shift()} : shift() ) ) {
	    push @{_VALUE_->{$_}}, @_;
	  }
	},
      'shift' => q{
	  map { shift @{_VALUE_->{$_}} } @_
	},
      'unshift' => q{
	  for ( ( ref ($_[0]) eq 'ARRAY' ? @{shift()} : shift() ) ) {
	    unshift @{_VALUE_->{$_}}, @_;
	  }
	},
      'splice' => q{
	  my $key = shift;
	  splice @{ _VALUE_->{$key} }, shift, shift, @_;
	},
      'clear' => q{
	  foreach (@_) { _VALUE_->{$_} = []; }
	},
      'count' => q{
	  my $Result = 0;
	  foreach (@_) {
	    # Avoid autovivifying additional entries.
	    $Result += exists _VALUE_->{$_} ? scalar @{_VALUE_->{$_}} : 0;
	  }
	  return $Result;
	},
      'index' => q{
	  my $key_r = shift;
	  
	  my @Result;
	  my $key;
	  foreach $key ( ( ref ($key_r) eq 'ARRAY' ? @$key_r : $key_r ) ) {
	    my $ary = _VALUE_->{$key};
	    for (@_) {
	      push @Result, ( @{$ary} > $_ ) ? $ary->[$_] : undef;
	    }
	  }
	  return wantarray ? @Result : \@Result;
	},
      'set' => q{
	  my $key_r = shift;
	  
	  croak "_ATTR_{name} expects a key and then index => value pairs.\n"
		if @_ % 2;
	  while ( scalar @_ ) {
	    my $pos = shift;
	    _VALUE_->{$key_r}->[ $pos ] = shift();
	  }
	  return;
	},
      'remove' => q{
	  my $key_r = shift;
	  
	  my $key;
	  foreach $key ( ( ref ($key_r) eq 'ARRAY' ? @$key_r : $key_r ) ) {
	    my $ary = _VALUE_->{$key};
	    foreach ( sort {$b<=>$a} grep $_ < @$ary, @_ ) {
	      splice (@$ary, $_, 1);
	    }
	  }
	  return;
	},
      'sift' => q{
	my %args = ( scalar @_ == 1 and ref $_[0] eq 'HASH' ) ? %{$_[0]} : @_;
	my $hash = _VALUE_;
	my $filter_sr = $args{'filter'}  || sub { $_[0] == $_[1] };
	my $keys_ar   = $args{'keys'} || [ keys %$hash ];
	my $values_ar = $args{'values'}  || [undef];
	
	# This is harder than it looks; reverse means we want to grep out only
	# if *none* of the values matches.  I guess an evaled block, or closure
	# or somesuch is called for.
	#       my $reverse   = $args{'reverse'} || 0;

	my ($key, $i, $value);
	KEY: foreach $key (@$keys_ar) {
	  next KEY unless exists $hash->{$key};
	  INDEX: for ($i = $#{$hash->{$key}}; $i >= 0; $i--) {
	    foreach $value (@$values_ar) {
	      if ( $filter_sr->($value, $hash->{$key}[$i]) ) {
		splice @{$hash->{$key}}, $i, 1;
		next INDEX;
	      }
	    }
	  }
	}
	return;
      },
    },
  }
}

########################################################################

=head2 object Accessor

Creates accessor methods for manipulating references to objects.

In addition to creating a method to get and set the object reference,
the meta-method can also define forwarded methods that automatically
pass calls onto the object stored in that slot; see the description of the  'delegate' parameter below.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides get_set behavior for I<*>, clear behavior for 'delete_*',
and forwarding methods for any values in the method's 'delegate'
or 'soft_delegate' parameters.

=item get_and_set

Provides named get method, set_I<x> and clear_I<x> methods.

=item get_init_and_set

Provides named get_init method, set_I<x> and clear_I<x> methods.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get_set

The get_set method, if called with a reference to an object of the
given class as the first argument, stores it.

If called with any other arguments, creates and stores a new object, passing the arguemnts to the new() method for the object.

If called without arguments, returns the current value, which may be undefined if one has not been stored yet.

=item get_set_init

The get_set_init method, if called with a reference to an object of the
given class as the first argument, stores it.

If the slot is not filled yet it creates an object by calling the given
new method of the given class. Any arguments passed to the get_set_init
method are passed on to new. 

In all cases the object now stored is returned.

=item get_init

If the instance is empty, creates and stores a new one. Returns the instance. 

=item get

Returns the current value, which may be undefined if one has not been stored yet.

=item set

If called with a reference to an object of the given class as the first argument, stores it.

If called with any other arguments, creates and stores a new object, passing the arguments to the new() method.

If called without arguments, creates and stores a new object, without any arguments to the new() method.

=item clear

Removes the reference value. 

=item I<forwarding>

If a 'delegate' or 'soft_delegate' parameter is provided, methods
with those names are created that are forwarded directly to the
object in the slot, as described below.

=back

B<Parameters>: The following parameters are supported:

=over 4

=item class

I<Required>. The type of object that will be stored.

=item new_method

The name of the method to call on the above class to create a new instance. Defaults to 'new'.

=item delegate

The methods to forward to the object. Can contain a method name,
a string of space-spearated method names, or an array of method
names. This type of method will croak if it is called when the
target object is not defined.

=item soft_delegate

The methods to forward to the object, if it is present. Can contain
a method name, a string of space-spearated method names, or an
array of method names. This type of method will return nothing if
it is called when the target object is not defined.

=back

=cut

sub object {
  {
    '-import' => { 
      # 'Template::Generic:generic' => '*',
    },
    'interface' => {
      default => { '*'=>'get_set', 'clear_*'=>'clear' },
      get_set_init => { '*'=>'get_set_init', 'clear_*'=>'clear' },
      get_and_set => {'*'=>'get', 'set_*'=>'set', 'clear_*'=>'clear' },
      get_init_and_set => { '*'=>'get_init','set_*'=>'set','clear_*'=>'clear' },
      init_and_get  => { '*'=>'init_and_get', -params=>{ init_method=>'init_*' } },
    },
    'params' => { 
      new_method => 'new' 
    },
    'code_expr' => {
      '_CALL_NEW_AND_STORE_' => q{
	my $new_method = _ATTR_REQUIRED_{new_method};
	my $class = _ATTR_REQUIRED_{'class'};
	_SET_VALUE_{ $class->$new_method(@_) };
      },
    },
    'behavior' => {
      '-import' => { 
	'Template::Generic:scalar' => [ qw( get clear ) ],
      },
      'get_set' => q{
	  if ( scalar @_ ) { 
	    if (ref $_[0] and UNIVERSAL::isa($_[0], _ATTR_REQUIRED_{'class'})) { 
	      _SET_VALUE_{ shift };
	    } else {
	      _CALL_NEW_AND_STORE_
	    }
	  } else {
	    _VALUE_;
	  }
	},
      'set' => q{
	  if ( ! defined $_[0] ) {
	    _SET_VALUE_{ undef };
	  } elsif (ref $_[0] and UNIVERSAL::isa($_[0], _ATTR_REQUIRED_{'class'})) { 
	    _SET_VALUE_{ shift };
	  } else {
	    _CALL_NEW_AND_STORE_
	  }
	},
      'get_init' => q{
	  if ( ! defined _VALUE_ ) {
	    _CALL_NEW_AND_STORE_
	  }
	  _VALUE_;
	},
      'init_and_get' => q{
	  if ( ! defined _VALUE_ ) {
	    my $init_method = _ATTR_REQUIRED_{'init_method'};
	    _SET_VALUE_{ _SELF_->$init_method( @_ ) };
	  } else {
	    _BEHAVIOR_{get}
	  }
	},
      'get_set_init' => q{
	  if (ref $_[0] and UNIVERSAL::isa($_[0], _ATTR_REQUIRED_{'class'})) { 
	    _SET_VALUE_{ shift };
	  } elsif ( ! defined _VALUE_ ) {
	    _CALL_NEW_AND_STORE_
	  }
	  _VALUE_;
	},
      '-subs' => sub { 
	  {
	    'delegate' => sub { my($m_info, $name) = @_; sub { 
	      my $m_name = $m_info->{'name'};
	      my $obj = (shift)->$m_name() 
		or Carp::croak("Can't forward $name because $m_name is empty");
	      $obj->$name(@_) 
	    } },
	    'soft_delegate' => sub { my($m_info, $name) = @_; sub { 
	      my $m_name = $m_info->{'name'};
	      my $obj = (shift)->$m_name() or return;
	      $obj->$name(@_) 
	    } },
	  }
	},
    },
  }
}

########################################################################

=head2 instance Accessor

Creates methods to handle an instance of the calling class.

PROFILES

=over 4

=item default

Provides named get method, and I<verb>_I<x> set, new, and clear methods.

=item -implicit_new

Provides named get_init method, and I<verb>_I<x> set, and clear methods.

=item -x_verb

Provides named get method, and I<x>_I<verb> set, new, and clear methods.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get

Returns the value of the instance parameter, which may be undefined if one has not been stored yet.

=item get_init

If the instance is empty, creates and stores a new one. Returns the instance. 

=item set

Takes a single argument and sets the instance to that value.

=item new

Creates and stores a new instance.

=item clear

Sets the instance parameter to undef.

=back

B<Parameters>: The following parameters are supported:

=over 4

=item instance

Holds the instance reference. Defaults to undef

=item new_method

The name of the method to call when creating a new instance. Defaults to 'new'.

=back

=cut

sub instance {
  {
    '-import' => { 
      'Template::Generic:object' => '*',
    },
    'interface' => {
      default => 'get_set',
    },
    'code_expr' => {
      '_CALL_NEW_AND_STORE_' => q{
	my $new_method = _ATTR_REQUIRED_{new_method};
	_SET_VALUE_{ (_SELF_)->$new_method(@_) };
      },
    },
  }
}

########################################################################

=head2 array_of_objects Accessor

Creates accessor methods for manipulating references to arrays of object references.

Operates like C<Generic:array>, but prior to adding any item to
the array, it first checks to see if it is an instance of the
designated class, and if not passes it as an argument to that
class's new method and stores the result instead.

Forwarded methods return a list of the results returned
by C<map>ing the method over each object in the array.

See the documentation on C<Generic:array> for interfaces and behaviors.

B<Parameters>: The following parameters are supported:

=over 4

=item class

I<Required>. The type of object that will be stored.

=item delegate

The methods to forward to the object. Can contain a method name, a string of space-spearated method names, or an array of method names.

=item new_method

The name of the method to call on the above class to create a new instance. Defaults to 'new'.

=back

=cut

sub array_of_objects {
  {
    '-import' => { 
      'Template::Generic:array' => '*',
    },
    'params' => {
	new_method => 'new',
      },
    'modifier' => {
      '-all get_set' => q{ _BLESS_ARGS_ * },
      '-all get_push' => q{ _BLESS_ARGS_ * },
      '-all set' => q{ _BLESS_ARGS_ * },
      '-all push' => q{ _BLESS_ARGS_ * },
      '-all unshift' => q{ _BLESS_ARGS_ * },
      # The below two methods are kinda broken, because the new values
      # don't get auto-blessed properly...
      '-all splice' => q{ * },
      '-all set_items' => q{ * },
    },
    'code_expr' => {
      '_BLESS_ARGS_' => q{
	  my $new_method = _ATTR_REQUIRED_{'new_method'};
	  @_ = map {
	    (ref $_ and UNIVERSAL::isa($_, _ATTR_REQUIRED_{class})) ? $_ 
			  : _ATTR_{'class'}->$new_method($_)
	  } @_;
	},
    },
    'behavior' => {
      '-subs' => sub { 
	  {
	    'delegate' => sub { my($m_info, $name) = @_; sub { 
	      my $m_name = $m_info->{'name'};
		map { $_->$name(@_) } (shift)->$m_name() 
	    } },
	  }
	},
    },
  }
}

########################################################################

=head2 code Accessor

Creates accessor methods for manipulating references to subroutines.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides the call_set functionality.

=item method

Provides the call_method functionality.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item call_set 

If called with one argument which is a CODE reference, it installs that
code in the slot. Otherwise it runs the code stored in the slot with
whatever arguments (including none) were passed in.

=item call_method 

Just like B<call_set>, except the code is called like a method, with $self
as its first argument. Basically, you are creating a method which can be
different for each object. 

=back

=cut

sub code {
  {
    '-import' => { 
      # 'Template::Generic:generic' => '*',
    },
    'interface' => {
      default => 'call_set',
      call_set => 'call_set',
      method => 'call_method',
    },
    'behavior' => {
      '-import' => { 
	'Template::Generic:scalar' => [ qw( get_set get set clear ) ],
      },
      'call_set' => q{
	  if ( scalar @_ == 1 and ref($_[0]) eq 'CODE') {
	    _SET_VALUE_{ shift }; # Set the subroutine reference
	  } else {
	    &{ _VALUE_ }( @_ ); # Run the subroutine on the given arguments
	  }
	},
      'call_method' => q{
	  if ( scalar @_ == 1 and ref($_[0]) eq 'CODE') {
	    _SET_VALUE_{ shift };	# Set the subroutine reference
	  } else {
	    &{ _VALUE_ }( _SELF_, @_ ); # Run the subroutine on self and args
	  }
	},
    },
  }
}


########################################################################

=head2 code_or_scalar Accessor

Creates accessor methods for manipulating either strings or references to subroutines.

You can store any scalar value; code refs are executed when you retrieve the value, while other scalars are returned as-is.

B<Interfaces>: The following calling interfaces are available.

=over 4

=item default

Provides the call_set functionality.

=item method

Provides the call_method functionality.

=item eiffel

Provides the named get_method, and a helper set_* method.

=back

B<Behaviors>: The following types of accessor methods are available.

=over 4

=item get_set_call 

If called with an argument, either a CODE reference or some other scalar, it installs that code in the slot. Otherwise, if the current value  runs the code stored in the slot with
whatever arguments (including none) were passed in.

=item get_set_method 

Just like B<call_set>, except the code is called like a method, with $self
as its first argument. Basically, you are creating a method which can be
different for each object. 

=back

=cut

sub code_or_scalar {
  {
    '-import' => { 'Template::Generic:scalar' => '*' },
    'interface' => {
      default => 'get_set_call',
      get_set => 'get_set_call',
      eiffel => { '*'=>'get_method', 'set_*'=>'set' },
      method => 'get_set_method',
    },
    'params' => {
    },
    'behavior' => {
      'get_call' => q{ 
	  my $value = _GET_VALUE_;
	  ( ref($value) eq 'CODE' ) ? &$value( @_ ) : $value
	},
      'get_method' => q{ 
	  my $value = _GET_VALUE_;
	  ( ref($value) eq 'CODE' ) ? &$value( _SELF_, @_ ) : $value
	},
      'get_set_call' => q{
	  if ( scalar @_ == 1 ) {
	    _BEHAVIOR_{set}
	  } else {
	    _BEHAVIOR_{get_call}
	  }
	},
      'get_set_method' => q{
	  if ( scalar @_ == 1 ) {
	    _BEHAVIOR_{set}
	  } else {
	    _BEHAVIOR_{get_call}
	  }
	},
    },
  }
}


########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for information about this family of subclasses.

=cut

1;
