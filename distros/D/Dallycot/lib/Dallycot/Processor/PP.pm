package Dallycot::Processor::PP;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Pure Perl implementation of Processor routines

use utf8;
use Moose;

sub add_cost {
  my ( $self, $delta ) = @_;

  return 0 if $self->ignore_cost;

  return $self->_cost( $self->cost + $delta );
}

sub DEMOLISH {
  my ( $self, $flag ) = @_;

  return if $flag;

  $self->parent->add_cost( $self->cost ) if $self->has_parent;
  return;
}

__PACKAGE__ -> meta -> make_immutable;

1;
