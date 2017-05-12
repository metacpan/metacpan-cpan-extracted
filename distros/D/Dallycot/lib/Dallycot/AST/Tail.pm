package Dallycot::AST::Tail;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Finds the rest of a collection

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';
use Carp qw(croak);

sub to_string {
  my ($self) = @_;

  return $self->[0]->to_string . '...';
}

sub to_rdf {
  my($self, $model) = @_;

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:Tail');
  $model -> add_expression($bnode, $self -> [0]);
  return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->execute( $self->[0] )->then(
    sub {
      my ($stream) = @_;

      if ( $stream->can('tail') ) {
        return $stream->tail($engine);
      }
      else {
        croak "The tail operator requires a stream-like object.";
      }
    }
  );
}

1;
