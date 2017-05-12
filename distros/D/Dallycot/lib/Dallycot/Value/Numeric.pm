package Dallycot::Value::Numeric;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: An arbitrary precision numeric value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use Promises qw(deferred);

sub new {
  my ( $class, $value ) = @_;

  $class = ref $class || $class;

  return bless [ ref($value) ? $value : Math::BigRat->new($value) ] => $class;
}

sub to_rdf {
  my($self, $model) = @_;

  if($self->[0]->is_int) {
    return $model -> integer($self -> [0] -> bstr);
  }
  elsif($self -> [0] -> is_nan) {
    my $bnode = $model->bnode;
    $model -> add_type($bnode, 'loc:NotANumber');
    return $bnode;
  }
  elsif($self -> [0] -> is_inf) {
    my $bnode = $model -> bnode;
    $model -> add_type($bnode, 'loc:PositiveInfinity');
    return $bnode;
  }
  elsif($self -> [0] -> is_inf('-')) {
    my $bnode = $model -> bnode;
    $model -> add_type($bnode, 'loc:NegativeInifinity');
    return $bnode;
  }
  else {
    my $bnode = $model -> bnode;
    $model -> add_type($bnode, 'loc:Rational');
    my($n, $d) = $self -> [0] -> parts;
    $model -> add_connection($bnode, 'loc:denominator',
      $model -> integer($d -> bstr)
    );
    $model -> add_connection($bnode, 'loc:numerator',
      $model -> integer($n->bstr)
    );
    return $bnode;
  }
}

sub id {
  my ($self) = @_;
  return $self->[0]->bstr . "^^Numeric";
}

sub is_defined { return 1 }

sub is_empty {return}

sub as_text {
  my ($self) = @_;

  return $self->[0]->bstr;
}

sub value {
  my ($self) = @_;
  return $self->[0];
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return $self->new( $self->[0]->copy->bfloor->length );
}

sub is_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value == $other->value );

  return $d->promise;
}

sub is_less {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value < $other->value );

  return $d->promise;
}

sub is_less_or_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $self->value <= $other->value );

  return $d->promise;
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

  return $d->promise;
}

sub negated {
  my($self) = @_;

  return $self->new( - $self->[0] );
}

sub successor {
  my ($self) = @_;

  my $d = deferred;

  $d->resolve( $self->new( $self->[0]->copy->binc ) );

  return $d->promise;
}

sub predecessor {
  my ($self) = @_;

  my $d = deferred;

  $d->resolve( $self->new( $self->[0]->copy->bdec ) );

  return $d->promise;
}

1;
