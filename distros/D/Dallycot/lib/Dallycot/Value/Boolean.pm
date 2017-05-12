package Dallycot::Value::Boolean;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: True or False

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use Promises qw(deferred);

use Readonly;

Readonly my $TRUE  => bless [ !!1 ] => __PACKAGE__;
Readonly my $FALSE => bless [ !!0 ] => __PACKAGE__;

sub new {
  my ( $class, $f ) = @_;

  return $f ? $TRUE : $FALSE;
}

sub to_rdf {
  my( $self, $model ) = @_;

  return RDF::Trine::Node::Literal->new(
    $self->[0] ? 'true' : 'false',
    '',
    $model -> meta_uri('xsd:boolean')
  );
}

sub as_text {
  my ($self) = @_;

  if ( $self->[0] ) {
    return 'true';
  }
  else {
    return 'false';
  }
}

sub id {
  if ( shift->value ) {
    return "true^^Boolean";
  }
  else {
    return "false^^Boolean";
  }
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return $engine->ONE;
}

sub is_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value == $other->value );

  return $d;
}

sub is_less {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value < $other->value );

  return $d;
}

sub is_less_or_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value <= $other->value );

  return $d;
}

sub is_greater {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value > $other->value );

  return $d->promise;
}

sub is_greater_or_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value >= $other->value );

  return $d;
}

1;
