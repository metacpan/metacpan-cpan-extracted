package Dallycot::AST::StrictlyIncreasing;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Test that all values are in strictly increasing order

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST::ComparisonBase';

sub to_string {
  my ($self) = @_;

  return join( " < ", map { $_->to_string } @{$self} );
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:all-strictly-increasing'),
    [ @$self ]
  );
  # my $bnode = $model->bnode;
  # $model -> add_type($bnode, 'loc:StrictlyIncreasing');
  #
  # $model -> add_list($bnode, 'loc:expressions',
  # map { $_ -> to_rdf($model) } @$self
  # );
  # return $bnode;
}

sub compare {
  my ( $self, $engine, $left_value, $right_value ) = @_;

  return $left_value->is_less( $engine, $right_value );
}

1;
