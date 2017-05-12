package Dallycot::AST::Assign;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Store result of expression in environment

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub to_string {
  my ($self) = @_;

  return $self->[0] . " := " . $self->[1]->to_string;
}

sub is_declarative { return 1 }

sub identifier {
  my ($self) = @_;

  return $self->[0];
}

sub simplify {
  my ($self) = @_;

  return bless [ $self -> [0], $self -> [1] -> simplify ] => __PACKAGE__;
}

sub to_rdf {
  my($self, $model) = @_;

  my $bnode = $self->[1]->to_rdf($model);

  $model -> add_symbol($self->[0], $bnode);

  return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  my $registry = Dallycot::Registry->instance;

  if ( $registry->has_assignment( '', $self->[0] ) ) {
    $d = $registry->get_assignment( '', $self->[0] );
    if ( $d->is_resolved ) {
      $d = deferred;
      $d->reject('Core definitions may not be redefined.');
      return $d->promise;
    }
  }
  elsif ( $engine->has_assignment( $self->[0] ) ) {
    $d = $engine->get_assignment( $self->[0] );
    if ( $d->is_resolved ) {
      $d = deferred;
      $d->reject( 'Unable to redefine ' . $self->[0] );
      return $d->promise;
    }
  }
  else {
    $d = $engine->add_assignment( $self->[0] );
  }

  $engine->execute( $self->[1] )->done(
    sub {
      my ($result) = @_;
      my $worked = eval {
        $engine->add_assignment( $self->[0], $result );
        1;
      };
      if ($@) {
        $d->reject($@);
      }
      elsif ( !$worked ) {
        $d->reject( "Unable to assign to " . $self->[0] );
      }
      else {
        $d->resolve($result);
      }
    },
    sub {
      $d->reject(@_);
    }
  );

  return $d->promise;
}

1;
