package Dallycot::AST::Identity;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Glue node to return an AST upon execution

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub to_string {
  my ($self) = @_;

  return $self->[0]->to_string;
}

sub to_rdf {
  my($self, $model) = @_;

  return $self->[0]->to_rdf($model);
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve( $self->[0] );

  return $d->promise;
}

1;
