package Dallycot::AST::LoopBase;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Base class for operations that loop over a series of expressions

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $self->process_loop( $engine, $d, @$self );

  return $d->promise;
}

sub process_loop {
  my ( $self, $engine, $d ) = @_;

  $d->reject( "Loop body is undefined for " . ref($self) . "." );

  return;
}

1;
