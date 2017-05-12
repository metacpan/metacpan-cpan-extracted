package Dallycot::AST::Expr;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A no-op placeholder

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub to_json {
  return +{ a => 'Expr' };
}

sub to_string { return "" }

sub to_rdf {

}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve( $engine->UNDEFINED );

  return $d->promise;
}

1;
