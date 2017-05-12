package Dallycot::AST::Any;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Return true iff any expression evaluates true

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST::LoopBase';

sub simplify {
  my ($self) = @_;

  return bless [ map { $_->simplify } @$self ] => __PACKAGE__;
}

sub to_rdf {
  my($self, $model) = @_;

  #
  # node -> expression_set -> [ ... ]
  #
  return $model -> apply(
    $model -> meta_uri('loc:any-true'),
    [ @$self ],
    {}
  );
  # my $bnode = $model->bnode();
  #
  # $model -> add_type($bnode, 'loc:AnyTrue');
  #
  # foreach my $expr (@$self) {
  #   $model -> add_expression($bnode, $expr);
  # }
  # return $bnode;
}

sub process_loop {
  my ( $self, $engine, $d, @expressions ) = @_;

  if ( !@expressions ) {
    $d->resolve( $engine->FALSE );
  }
  else {
    $engine->execute( shift @expressions, ['Boolean'] )->done(
      sub {
        if ( $_[0]->value ) {
          $d->resolve( $engine->TRUE );
        }
        else {
          $self->process_loop( $engine, $d, @expressions );
        }
      },
      sub {
        $d->reject(@_);
      }
    );
  }

  return;
}

1;
