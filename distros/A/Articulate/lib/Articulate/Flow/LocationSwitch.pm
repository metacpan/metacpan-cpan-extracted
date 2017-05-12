package Articulate::Flow::LocationSwitch;
use strict;
use warnings;
use Moo;
with 'Articulate::Role::Flow';
use Articulate::Syntax
  qw (new_location_specification instantiate instantiate_array);

=head1 NAME

Articulate::Flow::LocationSwitch - case switching for location

=head1 CONFIGURATION

  - class: Articulate::Flow::LocationSwitch
    args:
      where:
        '/assets/*/*/*':
          - Enrich::Asset
      otherwise:
        - Enrich::Content

=head1 DESCRIPTION

This provides a convenient interface to a common branching pattern.
When performing actions like C<enrich> and C<augment>, a developer will
typically want to make some processes dependant on the location of the
content being stored.

Rather than having to write a 'black box' provider every time, this
class provides a standard way of doing it.

=head1 METHODS

=head3 enrich

    $self->enrich( $item, $request );
    $self->process_method( enrich => $item, $request );

=head3 augment

    $self->augment( $item, $request );
    $self->process_method( augment => $item, $request );

=head3 process_method

  $self->process_method( $verb, $item, $request );

Goes through each of the keys of C<< $self->where >>; if the location
of C<$item> matches location specification given (see
L<Articulate::LocationSpecification>), then instantiates the value of
that key and performs the same verb on the arguments.

If none of the where clauses matched, the otherwise provider, if one is
specified, will be used.

=cut

has where => (
  is      => 'rw',
  default => sub { {} },
  coerce  => sub {
    my $orig = shift // {};
    foreach my $type ( keys %$orig ) {
      $orig->{$type} = instantiate_array( $orig->{$type} );
    }
    return $orig;
  },
);

has otherwise => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub {
    instantiate_array(@_);
  },
);

sub process_method {
  my $self     = shift;
  my $method   = shift;
  my $item     = shift;
  my $location = $item->location;
  if ( defined $location ) {
    foreach my $locspec_string ( keys %{ $self->where } ) {
      my $location_specification = new_location_specification $locspec_string;
      if ( $location_specification->matches($location) ) {
        return $self->_delegate(
          $method => $self->where->{$locspec_string},
          [ $item, @_ ]
        );
      }
    }
  }
  if ( defined $self->otherwise ) {
    return $self->_delegate( $method => $self->otherwise, [ $item, @_ ] );
  }
  return $item;
}

1;
