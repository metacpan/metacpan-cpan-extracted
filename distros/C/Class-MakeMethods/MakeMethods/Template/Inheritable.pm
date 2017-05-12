=head1 NAME

Class::MakeMethods::Template::Inheritable - Overridable data

=head1 SYNOPSIS

  package MyClass;

  use Class::MakeMethods( 'Template::Inheritable:scalar' => 'foo' );
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

=head1 DESCRIPTION

The MakeMethods subclass provides accessor methods that search an inheritance tree to find a value. This allows you to set a shared or default value for a given class, and optionally override it in a subclass.

=cut

########################################################################

package Class::MakeMethods::Template::Inheritable;

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
	my @_INC_search = ( _SELF_, _SELF_CLASS_ ); 
	while ( scalar @_INC_search ) {
	  _VALUE_CLASS_ = shift @_INC_search;
	  last if ( exists _ATTR_{data}->{_VALUE_CLASS_} );
	  no strict 'refs';
	  unshift @_INC_search, @{"_VALUE_CLASS_\::ISA"} if ! ref _VALUE_CLASS_;
	}
      },
      '_VALUE_' => '_ATTR_{data}->{_VALUE_CLASS_}',
      '_GET_VALUE_' => q{ _ATTR_{data}->{_VALUE_CLASS_} },
      '_SET_VALUE_{}' => q{ do { my $data = *; defined($data) ? ( _VALUE_CLASS_ = _SELF_ and _ATTR_{data}->{_SELF_} = $data ) : ( delete _ATTR_{data}->{_SELF_} and undef ) } },
    },
  }
}

########################################################################

=head2 Standard Methods

The following methods from Generic should be supported:

  scalar
  string
  string_index (?)
  number
  boolean (?)
  bits (?)
  array (?)
  hash (?)
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
      '-all' => q{ _INIT_VALUE_CLASS_; _ENSURE_REF_VALUE_; * },
    },
    'code_expr' => {
      '_ENSURE_REF_VALUE_' => q{ _VALUE_ ||= []; },
      '_REF_VALUE_' => '(\@{_ATTR_{data}->{_VALUE_CLASS_}})',
    },
  } 
}

sub hash {
  {
    '-import' => { 
      'Template::Generic:hash' => '*',
    },
    'modifier' => {
      '-all' => q{ _INIT_VALUE_CLASS_; _ENSURE_REF_VALUE_; * },
    },
    'code_expr' => {
      '_ENSURE_REF_VALUE_' => q{ _VALUE_ ||= {}; },
      '_REF_VALUE_' => '(\%{_ATTR_{data}->{_VALUE_CLASS_}})',
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
