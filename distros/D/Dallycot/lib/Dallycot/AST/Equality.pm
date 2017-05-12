package Dallycot::AST::Equality;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Tests that all expressions evaluate to the same value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST::ComparisonBase';

sub to_string {
  my ($self) = @_;

  return join( " = ", map { $_->to_string } @{$self} );
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:all-equal'),
    [ @$self ]
  );
}

sub compare {
  my ( $self, $engine, $left_value, $right_value ) = @_;

  return $left_value->is_equal( $engine, $right_value );
}

1;
