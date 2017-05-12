package Class::MakeMethods::Template::PackageVar;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.0;
use Carp;

=head1 NAME

Class::MakeMethods::Template::PackageVar - Static methods with global variables

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::PackageVar (
    scalar          => [ 'foo' ]
  );
  
  package main;

  MyObject->foo('bar')
  print MyObject->foo();

  $MyObject::foo = 'bazillion';
  print MyObject->foo();

=head1 DESCRIPTION

These meta-methods provide access to package (class global) variables.
These are essentially the same as the Static meta-methods, except
that they use a global variable in the declaring package to store
their values.

B<Common Parameters>: The following parameters are defined for PackageVar meta-methods.

=over 4

=item variable

The name of the variable to store the value in. Defaults to the same name as the method.

=back

=cut

sub generic {
  {
    '-import' => { 
      'Template::Generic:generic' => '*' 
    },
    'params' => { 
      'variable' => '*' 
    },
    'modifier' => {
      '-all' => [ q{ no strict; * } ],
    },
    'code_expr' => {
      '_VALUE_' => '${_ATTR_{target_class}."::"._ATTR_{variable}}',
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

########################################################################

sub array {
  {
    '-import' => { 
      'Template::Generic:array' => '*',
    },
    'modifier' => {
      '-all' => q{ no strict; _ENSURE_REF_VALUE_; * },
    },
    'code_expr' => {
      '_ENSURE_REF_VALUE_' => q{ 
	_REF_VALUE_ or @{_ATTR_{target_class}."::"._ATTR_{variable}} = (); 
      },
      '_VALUE_' => '\@{_ATTR_{target_class}."::"._ATTR_{variable}}',
    },
  } 
}

########################################################################

sub hash {
  {
    '-import' => { 
      'Template::Generic:hash' => '*',
    },
    'modifier' => {
      '-all' => q{ no strict; _ENSURE_REF_VALUE_; * },
    },
    'code_expr' => {
      '_ENSURE_REF_VALUE_' => q{ 
	_REF_VALUE_ or %{_ATTR_{target_class}."::"._ATTR_{variable}} = (); 
      },
      '_VALUE_' => '\%{_ATTR_{target_class}."::"._ATTR_{variable}}',
    },
  } 
}

########################################################################

=head2 PackageVar:vars

This rewrite rule converts package variable names into PackageVar methods of the equivalent data type.

Here's an example declaration:

  package MyClass;
  
  use Class::MakeMethods::Template::PackageVar (
    vars => '$DEBUG %Index'
  );

MyClass now has methods that get and set the contents of its $MyClass::DEBUG and %MyClass::Index package variables:

  MyClass->DEBUG( 1 );
  MyClass->Index( 'foo' => 'bar' );

=cut

sub vars { 
  my $mm_class = shift;
  my @rewrite = map [ "Template::PackageVar:$_" ], qw( scalar array hash );
  my %rewrite = ( '$' => 0, '@' => 1, '%' => 2 );
  while (@_) {
    my $name = shift;
    my $data = shift;
    $data =~ s/\A(.)//;
    push @{ $rewrite[ $rewrite{ $1 } ] }, { 'name'=>$name, 'variable'=>$data };
  }
  return @rewrite;
}


1;
