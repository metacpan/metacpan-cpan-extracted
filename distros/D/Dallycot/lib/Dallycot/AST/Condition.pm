package Dallycot::AST::Condition;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Select an expression based on guards

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST::LoopBase';

sub to_rdf {
  my($self, $model) = @_;

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:GuardedSequence');
  $model -> add_list($bnode, 'loc:expressions',
    map {
      $self->_case_to_rdf($model, $_)
    } @$self
  );

  return $bnode;
}

sub _case_to_rdf {
  my($self, $model, $cond) = @_;

  my $expr = $cond->[1]->to_rdf($model);
  if(defined $cond->[0]) {
    $expr = $model -> add_connection(
      $expr,
      'loc:guard',
      $cond->[0]->to_rdf($model)
    );
  }
  return $expr;
}

sub child_nodes {
  my ($self) = @_;

  return grep {defined} map { @{$_} } @{$self};
}

sub process_loop {
  my ( $self, $engine, $d, $condition, @expressions ) = @_;

  if ($condition) {
    if ( defined $condition->[0] ) {
      $engine->execute( $condition->[0], ['Boolean'] )->done(
        sub {
          my ($flag) = @_;
          if ( $flag->value ) {
            $engine->execute( $condition->[1] )->done(
              sub {
                $d->resolve(@_);
              },
              sub {
                $d->reject(@_);
              }
            );
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
    else {
      $engine->execute( $condition->[1] )->done(
        sub {
          $d->resolve(@_);
        },
        sub {
          $d->reject(@_);
        }
      );
    }
  }
  else {
    $d->resolve( $engine->UNDEFINED );
  }

  return;
}

1;
