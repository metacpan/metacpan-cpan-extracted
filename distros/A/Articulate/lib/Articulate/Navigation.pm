package Articulate::Navigation;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';

use Articulate::Location;
use Articulate::LocationSpecification;

=head1 NAME

Articulate::Navigation - determine valid locations

=head1 SYNOPSIS

  components:
    navigation:
      Articulate::Navigation:
        locations:
          - zone/*
          - zone/*/article/*
          - user/*
          - []

Provides validation for locations.

=head1 ATTRIBUTE

=head3 locations

Any location specifications configured in the locations attribute are
valid locations for deposition and retrieval of items from storage.

=cut

has locations => (
  is      => 'rw',      # rwp?
  default => sub { [] },
  coerce  => sub {
    my $orig = shift;
    my $new  = [];
    foreach my $l ( @{$orig} ) {
      push @$new, new_location_specification $l;
    }
    return $new;
  },
);

# A new_location_specification is like a location except it can contain "*": "/zone/*/article/"

=head1 METHODS

=cut

=head3 valid_location

  do_something if $self->valid_location('zone/public')
  do_something if $self->valid_location($location_object)

Returns the location if valid (matches one of the locspecs in
C<locations>), undef otherwise.

=cut

sub valid_location {
  my $self     = shift;
  my $location = new_location shift;
  foreach my $defined_location ( @{ $self->locations } ) {
    if ( $defined_location->matches($location) ) {
      return $location;
    }
  }
  return undef;
}

=head3 define_locspec

  $self->define_locspec('zone/*')
  $self->define_locspec($location_specification)

Adds a new_location_specification to C<locations>, unless it is already
there

=cut

sub define_locspec {
  my $self     = shift;
  my $location = new_location_specification shift;
  foreach my $defined_location ( @{ $self->locations } ) {
    if ( ( $location eq $defined_location ) ) {
      return undef;
    }
  }
  push @{ $self->locations }, $location;
}

=head3 undefine_locspec

  $self->undefine_locspec('zone/*')
  $self->undefine_locspec($location_specification)

Removes a new_location_specification from C<locations>.

=cut

sub undefine_locspec {
  my $self     = shift;
  my $location = new_location_specification shift;
  my ( $removed, $kept ) = ( [], [] );
  foreach my $defined_location ( @{ $self->locations } ) {
    if ( ( "$location" eq "$defined_location" )
      or $defined_location->matches_descendant_of($location) )
    {
      push @$removed, $location;
    }
    else {
      push @$kept, $location;
    }
  }
  $self->locations($kept);
  return $removed;
}

=head1 SEE ALSO

=over

=item * L<Articulate::Location>

=item * L<Articulate::LocationSpecification>

=back

=cut

1;
