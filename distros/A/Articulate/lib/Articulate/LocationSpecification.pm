package Articulate::LocationSpecification;
use strict;
use warnings;

use Moo;
use Scalar::Util qw(blessed);
use overload '""' => sub { shift->to_file_path }, '@{}' => sub { shift->path };
use Articulate::Location;

use Exporter::Declare;
default_exports qw(new_location_specification);

=head1 NAME

Articulate::LocationSpecification - represent a specification

=cut

=head1 DESCRIPTION

  new_location_specification ['zone', '*', 'article', 'hello-world']
  new_location_specification 'zone/*/article/hello-world' # same thing

An object class which represents a specification - like a 'pattern' or
'glob', and provides methods so that it can be compared with locations.
It is similar to C<Articulate::Location>, and stringifies to the 'file
path' representation.

The main use of this is to determine whether a user has access to a
resource based on rules (e.g.
L<Articulate::Authorisation::LocationBased>).

=cut

=head1 FUNCTIONS

=head3 new_location_specification

C<new_location_specification> is a constructor. It takes either a
string (in the form of a path) or an arrayref. Either will be stored as
an arrayref in the C<path> attribute.

=cut

sub new_location_specification {
  if ( 1 == scalar @_ ) {
    if ( blessed $_[0] and $_[0]->isa('Articulate::LocationSpecification') ) {
      return $_[0];
    }
    elsif ( blessed $_[0] and $_[0]->isa('Articulate::Location') ) {
      my $path = $_[0]->path; # should this logic be in the coerce?
      if (@$path) {
        for my $i ( 1 .. $#$path ) {
          if ( 0 == ( $i % 2 ) ) {
            $path->[$i] = '*';
          }
        }
      }
      return __PACKAGE__->new( { path => $path } );
    }
    elsif ( ref $_[0] eq 'ARRAY' ) {
      return __PACKAGE__->new( { path => $_[0] } );
    }
    elsif ( !defined $_[0] ) {
      return __PACKAGE__->new;
    }
    elsif ( !ref $_[0] ) {
      return __PACKAGE__->new(
        { path => [ grep { $_ ne '' } split /\//, $_[0] ] } );
    }
    elsif ( ref $_[0] eq 'HASH' ) {
      return __PACKAGE__->new( $_[0] );
    }
  }
}

=head1 ATTRIBUTE

=head3 path

An arrayref representing the path to the location specification. This
is used for overloaded array dereferencing.

=cut

has path => (
  is      => 'rw',
  default => sub { []; },
);

=head1 METHODS

=head3 location

  $locspec->location->location # same as $locspec

This method always returns the object itself.

=cut

sub location {
  return shift;
}

=head3 to_file_path

Joins the contents of C<path> on C</> and returns the result. This is
used for overloaded stringification.

=cut

sub to_file_path {
  return join '/', @{ $_[0]->path };
}

sub _step_matches {
  my ( $left, $right ) = @_;
  return 1 if ( $left eq '*' );
  return 1 if ( $right eq '*' );
  return 1 if ( $left eq $right );
  return 0;

}

=head3 matches

  new_location_specification('/zone/*')->matches(new_location('/zone/public')) # true
  new_location_specification('/zone/*')->matches(new_location('/')) # false
  new_location_specification('/zone/*')->matches(new_location('/zone/public/article/hello-world')) # false

Determines if the location given as the first argument matches the
locspec.

=cut

sub matches {
  my $self     = shift;
  my $location = new_location shift;
  return 0 unless $#$self == $#$location;
  return 1 if $#$self == -1; # go no further if both are empty
  for my $i ( 0 .. $#$self ) {
    return 0 unless _step_matches( $self->[$i], $location->[$i] );
  }
  return 1;
}

=head3 matches_ancestor_of

  new_location_specification('/zone/*')->matches_ancestor_of(new_location('/zone/public')) # true
  new_location_specification('/zone/*')->matches_ancestor_of(new_location('/')) # false
  new_location_specification('/zone/*')->matches_ancestor_of(new_location('/zone/public/article/hello-world')) # true

Determines if the location given as the first argument - or any
ancestor thereof - matches the new_location_specification.

=cut

sub matches_ancestor_of {
  my $self     = shift;
  my $location = new_location shift;
  return 0 unless $#$self <= $#$location;
  return 1 if $#$self == -1; # go no further if self is empty
  for my $i ( 0 .. $#$self ) {
    return 0 unless _step_matches( $self->[$i], $location->[$i] );
  }
  return 1;
}

=head3 matches_descendant_of

  new_location_specification('/zone/*')->matches_descendant_of(new_location('/zone/public')) # true
  new_location_specification('/zone/*')->matches_descendant_of(new_location('/')) # true
  new_location_specification('/zone/*')->matches_descendant_of(new_location('/zone/public/article/hello-world')) # false

Determines if the location given as the first argument - or any
descendant thereof - matches the new_location_specification.

=cut

sub matches_descendant_of {
  my $self     = shift;
  my $location = new_location shift;
  return 0 unless $#$self >= $#$location;
  return 1 if $#$location == -1; # go no further if self is empty
  for my $i ( 0 .. $#$location ) {
    return 0 unless _step_matches( $self->[$i], $location->[$i] );
  }
  return 1;
}

=head1 SEE ALSO

=over

=item * L<Articulate::Location>

=item * L<Articulate::Navigation>

=item * L<Articulate::Permission>

=back

=cut

1;
