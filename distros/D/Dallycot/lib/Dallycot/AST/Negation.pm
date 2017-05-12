package Dallycot::AST::Negation;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Negate a numeric value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub to_string {
  my ($self) = @_;

  return "-" . $self->[0]->to_string;
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:negate'),
    [ $self->[0] ],
    {}
  );
  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:Negation');
  # $model -> add_expression($self -> [0]);
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->execute( $self->[0], ['Numeric'] )->then(
    sub {
      return $_[0] -> negated;
    }
  );
}

1;
