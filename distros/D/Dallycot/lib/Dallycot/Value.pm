package Dallycot::Value;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Abstract type representing a value

use strict;
use warnings;

use utf8;
use Carp qw(croak);

use Module::Pluggable
  require     => 1,
  sub_name    => '_types',
  search_path => 'Dallycot::Value';

use Promises qw(deferred);

our @TYPES;

sub types {
  return @TYPES = @TYPES || shift->_types;
}

__PACKAGE__->types;

sub is_lambda {return}

sub is_defined {return}

sub is_empty { return 1 }

sub check_for_common_mistakes {
  return ();
}

sub as_text {
  my ($self) = @_;
  return $self->to_string;
}

sub type {
  my ($self) = @_;

  return Dallycot::Value::Set->new(
    Dallycot::Value::URI->new( 'http://www.dallycot.net/ns/types/1.0/' . $self->_type ) );
}

sub _type {
  my ($class) = @_;

  $class = ref $class || $class;

  my $type = substr( $class, CORE::length(__PACKAGE__) + 2 );
  $type =~ s/::/-/;
  return $type;
}

sub simplify {
  my ($self) = @_;

  return $self;
}

sub to_json {
  my ($self) = @_;

  croak "to_json not defined for " . ( blessed($self) || $self );
}

sub to_string {
  my ($self) = @_;

  croak "to_string not defined for " . ( blessed($self) || $self );
}

sub child_nodes { return () }

sub identifiers { return () }

sub calculate_length {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve( $engine->ZERO );

  return $d->promise;
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve($self);

  return $d->promise;
}

1;
