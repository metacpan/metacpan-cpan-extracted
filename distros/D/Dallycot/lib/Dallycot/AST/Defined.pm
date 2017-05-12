package Dallycot::AST::Defined;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Test if expression evaluates to a defined value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Scalar::Util qw(blessed);

sub to_string {
  my ($self) = @_;

  return "?(" . ( $self->[0]->to_string ) . ")";
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:not-empty'),
    [ $self->[0] ],
    {}
  );
  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:NotEmpty');
  # $model -> add_expression($self -> [0]);
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->execute( $self->[0] )->then(
    sub {
      my ($result) = @_;
      if ( blessed $result ) {
        return ( $result->is_defined && !$result->is_empty ? $engine->TRUE : $engine->FALSE );
      }
      else {
        return ( $engine->FALSE );
      }
    }
  );
}

1;
