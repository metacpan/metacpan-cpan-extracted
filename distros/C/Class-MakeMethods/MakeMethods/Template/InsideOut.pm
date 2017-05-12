package Class::MakeMethods::Template::InsideOut;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.0;

my %ClassInfo;
my %Data;

sub generic {
  {
    '-import' => { 
      'Template::Generic:generic' => '*' 
    },
    'code_expr' => { 
      '_VALUE_' => '_ATTR_{data}->{_SELF_}',
    },
    'behavior' => {
      -register => [ sub {
	my $m_info = shift;
	my $class_info = ( $ClassInfo{$m_info->{target_class}} ||= [] );
	return (
	  'DESTROY' => sub { 
	    my $self = shift;
	    foreach ( @$class_info ) { delete $self->{data}->{$self} } 
	    # $self->SUPER::DESTROY( @_ ) 
	  },
	);
      } ],
    }
  }
}

########################################################################

=head1 NAME

Class::MakeMethods::Template::InsideOut - External data

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::InsideOut (
    scalar          => [ 'foo', 'bar' ]
  );
  sub new { ... }
  
  package main;

  my $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" );
  print $obj->foo();		# Prints Foozle
  $obj->bar("Bamboozle"); 	# Sets $obj's bar value

=head1 DESCRIPTION

Supports the Generic object constructor and accessors meta-method
types, but accepts any object as the underlying implementation type,
with member data stored in external indices. 

Each method stores the values associated with various objects in
an hash keyed by the object's stringified identity. Since that hash
is accessible only from the generated closures, it is impossible
for foreign code to manipulate those values except through the
method interface. 

A DESTROY method is installed to remove data for expired objects
from the various hashes. (If the DESTROY method is not called, your
program will not release this data and memory will be wasted.)

B<Common Parameters>: The following parameters are defined for
InsideOut meta-methods.

=over 4

=item data

An auto-vivified reference to a hash to be used to store the values
for each object.

=back

Note that using InsideOut meta-methods causes the installation of
a DESTROY method in the calling class, which deallocates data for
each instance when it is discarded.

NOTE: This needs some more work to properly handle inheritance.

=head2 Standard Methods

The following methods from Generic are all supported:

  scalar
  string
  string_index *
  number 
  boolean
  bits 
  array
  hash
  tiedhash
  hash_of_arrays
  object
  instance
  array_of_objects
  code
  code_or_scalar

See L<Class::MakeMethods::Template::Generic> for the interfaces and behaviors of these method types.

The items marked with a * above are specifically defined in this package, whereas the others are formed automatically by the interaction of this package's generic settings with the code templates provided by the Generic superclass. 

=cut

########################################################################

=head2 boolean_index

  boolean_index => [ qw / foo bar baz / ]

Like InsideOut:boolean, boolean_index creates x, set_x, and clear_x
methods. However, it also defines a class method find_x which returns
a list of the objects which presently have the x-flag set to
true. 

Note that to free items from memory, you must clear these bits!

=cut

sub boolean_index {
  {
    '-import' => { 
      'Template::Generic:boolean' => '*',
    },
    'interface' => {
      default => { 
	  '*'=>'get_set', 'set_*'=>'set_true', 'clear_*'=>'set_false',
	  'find_*'=>'find_true', 
      },
    },
    'behavior' => {
      '-init' => [ sub { 
	my $m_info = $_[0]; 
	defined $m_info->{data} or $m_info->{data} = {};
	return;
      } ],
      'set_true' => q{ _SET_VALUE_{ _SELF_ } },
      'set_false' => q{ delete _VALUE_; 0 },
      'find_true' => q{
	  values %{ _ATTR_{data} };
	},
    },
  }
}

sub string_index {
  {
    '-import' => { 
      'Template::Generic:string_index' => '*',
    },
    'interface' => {
      default => { 
	  '*'=>'get_set', 'set_*'=>'set_true', 'clear_*'=>'set_false',
	  'find_*'=>'find_true', 
      },
    },
    'code_expr' => { 
      _INDEX_HASH_ => '_ATTR_{data}',
      _GET_FROM_INDEX_ => q{ 
	  if (defined ( my $old_v = _GET_VALUE_ ) ) {
	    delete _ATTR_{'data'}{ $old_v };
	  }
	},
      _REMOVE_FROM_INDEX_ => q{ 
	  if (defined ( my $old_v = _GET_FROM_INDEX_ ) ) {
	    delete _ATTR_{'data'}{ $old_v };
	  }
	},
      _ADD_TO_INDEX_{} => q{ 
	  if (defined ( my $new_value = _GET_VALUE_ ) ) {
	    if ( my $old_item = _ATTR_{'data'}{$new_value} ) {
	      # There's already an object stored under that value so we
	      # need to unset it's value.
	      # And maybe issue a warning? Or croak?
	      my $m_name = _ATTR_{'name'};
	      $old_item->$m_name( undef );
	    }
	    
	    # Put ourself in the index under that value
	    _ATTR_{'data'}{ * } = _SELF_;
	  }
	},
    },
    'behavior' => {
      '-init' => [ sub { 
	my $m_info = $_[0]; 
	defined $m_info->{data} or $m_info->{data} = {};
	return;
      } ],
      'get' => q{ 
	  return _GET_FROM_INDEX_; 
	},
      'set' => q{ 
	  my $new_value = shift;
	  _REMOVE_FROM_INDEX_
	  _ADD_TO_INDEX_{ $new_value }
	},
      'clear' => q{
	  _REMOVE_FROM_INDEX_
	},
    },
  }
}

########################################################################

1;
