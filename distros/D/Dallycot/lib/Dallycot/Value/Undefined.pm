package Dallycot::Value::Undefined;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: The Undefined value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use Promises qw(deferred);

our $INSTANCE;

sub new { return $INSTANCE ||= bless [] => __PACKAGE__; }

sub value { }

sub id { return '^^Undefined' }

sub as_text {
  return "(undef)";
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> meta_uri('rdf:nil');
}

sub is_defined {return}

sub is_empty { return 1 }

sub calculate_length {
  my ( $self, $engine ) = @_;

  return $engine->ZERO;
}

sub is_equal {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  if ( $self eq $INSTANCE ) {
    $d->resolve( $engine->TRUE );
  }
  else {
    $d->resolve( $engine->FALSE );
  }

  return $d->promise;
}

*is_less_or_equal    = \&is_equal;
*is_greater_or_equal = \&is_equal;

sub is_less {
  my ( $self, $engine, $other ) = @_;

  my $d = deferred;

  $d->resolve( $engine->FALSE );

  return $d;
}

*is_greater = \&is_less;

1;
