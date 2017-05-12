package Dallycot::AST::Lambda;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Create a lambda value with a closure environment

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

use Readonly;

Readonly my $EXPRESSION             => 0;
Readonly my $BINDINGS               => 1;
Readonly my $BINDINGS_WITH_DEFAULTS => 2;
Readonly my $OPTIONS                => 3;

sub new {
  my ( $self, $expr, $bindings, $bindings_with_defaults, $options ) = @_;

  my $class = ref $self || $self;
  $bindings               ||= [];
  $bindings_with_defaults ||= [];
  $options                ||= {};

  return bless [ $expr, $bindings, $bindings_with_defaults, $options ] => $class;
}

sub to_rdf {
  my($self, $model) = @_;

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:Algorithm');
  $model -> add_expression($bnode, $self -> [$EXPRESSION]);
  $model -> add_list(
    $bnode, 'loc:bindings',
    (map { $self -> _binding_rdf($model, $_) } @{$self->[$BINDINGS]}),
    (map { $self -> _binding_rdf($model, @$_) } @{$self->[$BINDINGS_WITH_DEFAULTS]})
  );
  foreach my $opt(keys %{$self->[$OPTIONS]}) {
    $model -> add_option(
      $bnode,
      $opt,
      $self->[$OPTIONS]->{$opt}->to_rdf($model)
    );
  }
  return $bnode;
}

sub _binding_rdf {
  my($self, $model, $label, $expr) = @_;

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:Binding');
  $model -> add_label($bnode, $label);
  if(defined $expr) {
    $model -> add_expression($bnode, $expr);
  }
  return $bnode;
}

sub child_nodes {
  my ($self) = @_;
  return $self->[$EXPRESSION],
    ( map { $_->[1] } @{ $self->[$BINDINGS_WITH_DEFAULTS] || [] } ),
    ( values %{ $self->[$OPTIONS] || {} } );
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve( $engine->make_lambda(@$self) );

  return $d->promise;
}

1;
