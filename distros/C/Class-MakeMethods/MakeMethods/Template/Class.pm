package Class::MakeMethods::Template::Class;

use Class::MakeMethods::Template::Generic '-isasubclass';

$VERSION = 1.008;
use strict;
require 5.0;
use Carp;

=head1 NAME

Class::MakeMethods::Template::Class - Associate information with a package

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Template::Class (
    scalar          => [ 'foo' ]
  );
  
  package main;
  
  MyObject->foo('bar')
  print MyObject->foo();

=head1 DESCRIPTION

These meta-methods provide access to class-specific values. They are similar to Static, except that each subclass has separate values.

=cut

sub generic {
  {
    '-import' => { 
      'Template::Generic:generic' => '*' 
    },
    'modifier' => {
    },
    'code_expr' => {
      '_VALUE_' => '_ATTR_{data}->{_SELF_CLASS_}',
    },
  }
}

########################################################################

=head2 Class:scalar

Creates methods to handle a scalar variable in the declaring package.

See the documentation on C<Generic:scalar> for interfaces and behaviors.

=cut

########################################################################

=head2 Class:array

Creates methods to handle a array variable in the declaring package.

See the documentation on C<Generic:array> for interfaces and behaviors.

=cut

sub array {
  {
    '-import' => { 
      'Template::Generic:array' => '*',
    },
    'modifier' => {
      '-all' => q{ _REF_VALUE_ or @{_ATTR_{data}->{_SELF_CLASS_}} = (); * },
    },
    'code_expr' => {
      '_VALUE_' => '\@{_ATTR_{data}->{_SELF_CLASS_}}',
    },
  } 
}

########################################################################

=head2 Class:hash

Creates methods to handle a hash variable in the declaring package.

See the documentation on C<Generic:hash> for interfaces and behaviors.

=cut

sub hash {
  {
    '-import' => { 
      'Template::Generic:hash' => '*',
    },
    'modifier' => {
      '-all' => q{ _REF_VALUE_ or %{_ATTR_{data}->{_SELF_CLASS_}} = (); * },
    },
    'code_expr' => {
      '_VALUE_' => '\%{_ATTR_{data}->{_SELF_CLASS_}}',
    },
  } 
}

1;
