package Class::MakeMethods::Template::Scalar;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.00;
use Carp;

=head1 NAME

Class::MakeMethods::Template::Scalar - Methods for blessed scalars

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::ExternalData (
    new             => 'new',
    scalar          => 'foo',
  );
  
  package main;

  my $obj = MyObject->new( foo => "Foozle" );
  print $obj->foo();		# Prints Foozle
  $obj->foo("Bamboozle"); 	# Sets $$obj
  print $obj->foo();		# Prints Bamboozle

=head1 DESCRIPTION

Supports the Generic object constructor and accessors meta-method
types, but uses scalar refs as the underlying implementation type,
so only one accessor method can be used effectively.

=cut

sub generic {
  {
    '-import' => { 
      'Template::Generic:generic' => '*' 
    },
    'code_expr' => { 
      _VALUE_ => '(${_SELF_})',
      _EMPTY_NEW_INSTANCE_ => 'bless \( my $scalar = undef ), _SELF_CLASS_',
    },
    'params' => {
    }
  }
}

########################################################################

=head2 Standard Methods

The following methods from Generic are all supported:

  new 
  scalar
  string
  string_index 
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

However, note that due to special nature of this package, all accessor methods reference the same scalar value, so setting a value with one method will overwrite the value retrieved by another.

=cut

1;
