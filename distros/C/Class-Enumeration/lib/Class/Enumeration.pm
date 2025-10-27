# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Class::Enumeration;

$Class::Enumeration::VERSION = 'v1.2.0';

use overload
  '""'     => 'to_string',
  '=='     => '_is_identical_to',
  '!='     => sub { !&_is_identical_to }, ## no critic ( ProhibitAmpersandSigils )
  fallback => 0;

use Carp         ();
use Scalar::Util ();

# $self == enum object
# $class == enum class

sub name {
  my ( $self ) = @_;

  $self->{ name }
}

sub ordinal {
  my ( $self ) = @_;

  $self->{ ordinal }
}

sub value_of {
  my ( $class, $name ) = @_;

  my ( $self ) = grep { $_->name eq $name } $class->values;
  defined $self ? $self : Carp::croak "No enum object defined for name '$name', stopped"
}

sub values { ## no critic ( ProhibitBuiltinHomonyms )
  Carp::croak "'values()' method not implemented by child class, stopped"
}

sub names {
  my ( $class ) = @_;

  map { $_->name } $class->values
}

sub to_string {
  my ( $self ) = @_;

  $self->name
}

sub _new { ## no critic ( ProhibitUnusedPrivateSubroutines )
  my ( $class, $ordinal, $name, $attributes ) = @_;

  Carp::croak 'The enum object name cannot be empty, stopped'
    if $name eq '';
  $attributes = {} unless defined $attributes;
  # Will raise a FATAL warning ("Not a HASH reference at ...") if $attribute is
  # not a HASH reference
  for ( keys %$attributes ) {
    Carp::croak "Overriding the implicit '$_' enum object attribute is forbidden, stopped"
      if $_ eq 'ordinal' or $_ eq 'name';
  }

  bless { ordinal => $ordinal, name => $name, %$attributes }, $class
}

sub _is_identical_to {
  my ( $self, $object, $swapFlag ) = @_;

  Scalar::Util::refaddr $self == Scalar::Util::refaddr $object;
}

1
