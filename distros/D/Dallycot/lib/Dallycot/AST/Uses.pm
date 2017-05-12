package Dallycot::AST::Uses;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A no-op placeholder

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub to_string { return "" }

sub is_declarative { return 1 }

sub identifier { }

sub as_text {
  my ($self) = @_;

  return "uses <" . $self->[0]->value . ">";
}

sub namespace {
  my ($self) = @_;

  return $self->[0]->value;
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $engine->append_namespace_search_path( $self->[0]->value );

  $d->resolve( $self->[0] );

  return $d->promise;
}

1;
