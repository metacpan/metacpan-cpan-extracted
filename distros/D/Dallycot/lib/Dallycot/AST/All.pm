package Dallycot::AST::All;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Return true iff all expressions evaluate true

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST::LoopBase';

sub new {
  my ( $class, @exprs ) = @_;

  $class = ref $class || $class;
  return bless \@exprs => $class;
}

sub to_rdf {
  my($self, $model) = @_;

  #
  # node -> expression_set -> [ ... ]
  #
  return $model -> apply(
    $model -> meta_uri('loc:all-true'),
    [ @$self ],
    {}
  );
}

sub simplify {
  my ($self) = @_;

  return bless [ map { $_->simplify } @$self ] => __PACKAGE__;
}

sub process_loop {
  my ( $self, $engine, $d, @expressions ) = @_;

  if ( !@expressions ) {
    $d->resolve( $engine->TRUE );
  }
  else {
    $engine->execute( shift @expressions, ['Boolean'] )->done(
      sub {
        if ( $_[0]->value ) {
          $self->process_loop( $engine, $d, @expressions );
        }
        else {
          $d->resolve( $engine->FALSE );
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
