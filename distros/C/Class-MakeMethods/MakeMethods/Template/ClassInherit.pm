=head1 NAME

Class::MakeMethods::Template::ClassInherit - Overridable class data

=head1 SYNOPSIS

  package MyClass;

  use Class::MakeMethods( 'Template::ClassInherit:scalar' => 'foo' );
  # We now have an accessor method for an "inheritable" scalar value
  
  package main;
  
  MyClass->foo( 'Foozle' );   # Set a class-wide value
  print MyClass->foo();	      # Retrieve class-wide value
  ...
  
  package MySubClass;
  @ISA = 'MyClass';
  
  print MySubClass->foo();    # Intially same as superclass,
  MySubClass->foo('Foobar');  # but overridable per subclass/

=head1 DESCRIPTION

The MakeMethods subclass provides accessor methods that search an inheritance tree to find a value. This allows you to set a shared or default value for a given class, and optionally override it in a subclass.

=cut

########################################################################

package Class::MakeMethods::Template::ClassInherit;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.0;
use Carp;

sub generic {
  {
    '-import' => { 
      'Template::Generic:generic' => '*' 
    },
    'modifier' => {
      '-all' => [ q{ 
	_INIT_VALUE_CLASS_
	*
      } ],
    },
    'code_expr' => {
      '_VALUE_CLASS_' => '$_value_class',
      '_INIT_VALUE_CLASS_' => q{ 
	my _VALUE_CLASS_;
	for ( my @_INC_search = _SELF_CLASS_; scalar @_INC_search; ) {
	  _VALUE_CLASS_ = shift @_INC_search;
	  last if ( exists _ATTR_{data}->{_VALUE_CLASS_} );
	  no strict 'refs';
	  unshift @_INC_search, @{"_VALUE_CLASS_\::ISA"};
	}
      },
      '_VALUE_' => '_ATTR_{data}->{_VALUE_CLASS_}',
      '_GET_VALUE_' => q{ _ATTR_{data}->{_VALUE_CLASS_} },
      '_SET_VALUE_{}' => q{ ( _VALUE_CLASS_ = _SELF_CLASS_ and _ATTR_{data}->{_VALUE_CLASS_} = * ) },
    },
  }
}

########################################################################

=head2 Standard Methods

The following methods from Generic should all be supported:

  scalar
  string
  string_index (?)
  number 
  boolean
  bits (?)
  array (*)
  hash (*)
  tiedhash (?)
  hash_of_arrays (?)
  object (?)
  instance (?)
  array_of_objects (?)
  code (?)
  code_or_scalar (?)

See L<Class::MakeMethods::Template::Generic> for the interfaces and behaviors of these method types.

The items marked with a * above are specifically defined in this package, whereas the others are formed automatically by the interaction of this package's generic settings with the code templates provided by the Generic superclass. 

The items marked with a ? above have not been tested sufficiently; please inform the author if they do not function as you would expect.

=cut

sub array {
  {
    '-import' => { 
      'Template::Generic:array' => '*',
    },
    'modifier' => {
      '-all' => [ q{ _VALUE_ ||= []; * } ],
    },
    'code_expr' => {
      '_VALUE_' => '\@{_ATTR_{data}->{_SELF_CLASS_}}',
    },
  } 
}

sub hash {
  {
    '-import' => { 
      'Template::Generic:hash' => '*',
    },
    'modifier' => {
      '-all' => [ q{ _VALUE_ ||= {}; * } ],
    },
    'code_expr' => {
      '_VALUE_' => '\%{_ATTR_{data}->{_SELF_CLASS_}}',
    },
  } 
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Template> for more about this family of subclasses.

See L<Class::MakeMethods::Template::Generic> for information about the various accessor interfaces subclassed herein.

If you just need scalar accessors, see L<Class::Data::Inheritable> for a very elegant and efficient implementation.

=cut

########################################################################

1;
