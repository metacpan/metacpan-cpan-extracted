package Dallycot::Context;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Execution context with value mappings and namespaces

use strict;
use warnings;

use utf8;
use Moose;

use namespace::autoclean;

use Array::Utils qw(unique array_minus);
use Scalar::Util qw(blessed);

use MooseX::Types::Moose qw/ArrayRef/;

use Carp qw(croak cluck);

use experimental qw(switch);

use Promises qw(deferred);

#
# Contexts form a chain from the kernel on down
# The context for a statement has no parent, but is copied from the kernel's
#   context. Changes made are copied back to the kernel context info.
# Closures need to copy all of the info into a new context that is marked as
#   a closure.

has namespaces => ( is => 'ro', isa => 'HashRef', default => sub { +{} }, lazy => 1 );

has environment => ( is => 'ro', isa => 'HashRef', default => sub { +{} }, lazy => 1 );

has namespace_search_path => ( is => 'ro', isa => 'ArrayRef', default => sub { [] }, lazy => 1 );

has parent => ( is => 'ro', isa => 'Dallycot::Context', predicate => 'has_parent' );

has is_closure => ( is => 'ro', isa => 'Bool', default => 0 );

sub add_namespace {
  my ( $self, $ns, $href ) = @_;

  if ( ( $self->is_closure || $self->has_parent )
    && defined( $self->namespaces->{$ns} ) )
  {
    croak "Namespaces may not be defined multiple times in a sub-context or closure";
  }
  $self->namespaces->{$ns} = $href;

  return;
}

sub get_namespace {
  my ( $self, $ns ) = @_;

  if ( exists( $self->namespaces->{$ns} ) ) {
    return $self->namespaces->{$ns};
  }
  elsif ( $self->has_parent ) {
    return $self->parent->get_namespace($ns);
  }
}

sub has_namespace {
  my ( $self, $prefix ) = @_;

  return exists( $self->namespaces->{$prefix} )
    || $self->has_parent && $self->parent->has_namespace($prefix);
}

sub add_assignment {
  my ( $self, $identifier, $expr ) = @_;

  if ( ( $self->is_closure || $self->has_parent ) ) {
    my $d = $self->environment->{$identifier};
    if ( $d && $d->is_resolved ) {
      croak "Identifiers may not be redefined in a sub-context or closure";
    }
  }
  if ( defined $expr ) {
    if ( $expr->can('resolve') ) {
      return $self->environment->{$identifier} = $expr;
    }
    else {
      my $d = deferred;
      $d->resolve($expr);
      return $self->environment->{$identifier} = $d;
    }
  }
  else {
    return $self->environment->{$identifier} = deferred;
  }
}

sub get_assignment {
  my ( $self, $identifier ) = @_;

  if ( defined( $self->environment->{$identifier} ) ) {
    return $self->environment->{$identifier};
  }
  elsif ( $self->has_parent ) {
    return $self->parent->get_assignment($identifier);
  }
}

sub has_assignment {
  my ( $self, $identifier ) = @_;

  return exists( $self->environment->{$identifier} )
    || $self->has_parent && $self->parent->has_assignment($identifier);
}

sub get_namespace_search_path {
  my ($self) = @_;

  return $self->namespace_search_path;
}

sub append_namespace_search_path {
  my ( $self, @paths ) = @_;

  return push @{ $self->namespace_search_path }, @paths;
}

sub make_closure {
  my ( $self, $node ) = @_;

  my ( %namespaces, %environment );

  # we only copy the values we can use
  my @stack       = ($node);
  my @identifiers = ();

  while (@stack) {
    $node = shift @stack;
    if ( !ref $node ) {
      cluck "We have a non-ref node! ($node)";
    }

    push @stack, $node->child_nodes;

    my @ids = $node->identifiers;
    if (@ids) {
      my @new_ids = array_minus( @ids, @identifiers );

      #push @stack, grep { ref } map { $self->get_assignment($_) } @new_ids;
      push @identifiers, @new_ids;
    }
  }

  @identifiers = values %{ +{ map { $_ => $_ } @identifiers } };

  for my $identifier (@identifiers) {
    if ( is_ArrayRef($identifier) ) {
      if ( !defined( $namespaces{ $identifier->[0] } ) ) {
        $namespaces{ $identifier->[0] } = $self->get_namespace( $identifier->[0] );
      }
    }
    elsif ( substr( $identifier, 0, 1 ) ne '#' && !defined( $environment{$identifier} ) ) {
      my $value = $self->get_assignment($identifier);
      $environment{$identifier} = $value if blessed $value;
    }
  }

  # making the closure a child/parent allows setting overrides once in the closure code
  return $self->new(
    namespaces            => \%namespaces,
    environment           => \%environment,
    namespace_search_path => [@{$self->namespace_search_path}]
  );
}

__PACKAGE__->meta->make_immutable;

1;
