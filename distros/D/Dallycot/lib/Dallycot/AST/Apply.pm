package Dallycot::AST::Apply;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Apply bindings to lambda

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Carp qw(croak);
use Promises qw(deferred);
use Readonly;

Readonly my $EXPRESSION => 0;
Readonly my $BINDINGS   => 1;
Readonly my $OPTIONS    => 2;

sub new {
  my ( $class, $expression, $bindings, $options ) = @_;

  $class = ref $class || $class;
  $bindings //= [];
  $options  //= {};
  return bless [ $expression, $bindings, $options ] => $class;
}

sub to_rdf {
  my($self, $model) = @_;

  #
  # node -> expression_set -> [ ... ]
  #
  return $model -> apply(
    $self -> [0],
    $self -> [1],
    $self -> [2]
  )
}

sub simplify {
  my ($self) = @_;

  return bless [
    $self->[$EXPRESSION]->simplify,
    [ map { $_->simplify } @{ $self->[$BINDINGS] } ],
    $self->[$OPTIONS]
  ] => __PACKAGE__;
}

sub child_nodes {
  my ($self) = @_;

  return $self->[$EXPRESSION], @{ $self->[$BINDINGS] || [] }, values %{ $self->[$OPTIONS] || {} };
}

sub to_string {
  my ($self) = @_;

  return
      "("
    . $self->[$EXPRESSION]->to_string . ")("
    . join(
    ", ",
    ( map { $_->to_string } @{ $self->[$BINDINGS] } ),
    ( map { $_ . " -> " . $self->[$OPTIONS]->{$_}->to_string }
      sort keys %{ $self->[$OPTIONS] }
    )
    ) . ")";
}

sub execute {
  my ( $self, $engine ) = @_;

  my $expr = $self->[$EXPRESSION];
  if ( $expr->isa('Dallycot::Value') ) {
    $expr = bless [$expr] => 'Dallycot::AST::Identity';
  }

  return $engine->execute($expr)->then(
    sub {
      my ($lambda) = @_;
      if ( !$lambda ) {
        croak "Undefined value can not be a function.";
      }
      elsif ( $lambda->can('apply') ) {
        my @bindings = @{ $self->[$BINDINGS] };
        if ( @bindings && $bindings[-1]->isa('Dallycot::AST::FullPlaceholder') ) {
          if ( $lambda->min_arity < @bindings ) {

            # we have something like f(..., ___) indicating we *want* a lambda
            # since we don't have room for any placeholders, we'll just create
            # a lambda and return it
            # we need to evaluate any options or bindings first
            pop @bindings;
            return Dallycot::AST::Lambda->new(
              Dallycot::AST::Apply->new( $self->[$EXPRESSION], \@bindings, $self->[$OPTIONS] ) )
              ->execute($engine);
          }
          else {
            pop @bindings;
            push @bindings,
              ( bless [] => 'Dallycot::AST::Placeholder' ) x ( $lambda->min_arity - @bindings );
          }
        }
        return $lambda->apply( $engine, { %{ $self->[$OPTIONS] } }, @bindings );
      }
      else {
        croak "Value of type " . $lambda->type . " can not be used as a function.";
      }
    }
  );
}

1;
