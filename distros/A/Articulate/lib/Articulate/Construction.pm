package Articulate::Construction;
use strict;
use warnings;

use Moo;
use Articulate::Syntax qw(instantiate_array);
use Articulate::Item;

with 'Articulate::Role::Component';

=head1 NAME

Articulate::Construction - create appropriate content item objects
given location, meta, content.

=cut

=head1 CONFIGURATION

  components:
    construction:
      Articulate::Construction:
        constructors:
        - Articulate::Construction::LocationBased

=head1 ATTRIBUTE

=head3 constructors

A list of classes which can be used to construct items.

=cut

has constructors => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) }
);

=head1 METHODS

=head3 construct

  my $item = $construction->construct( {
    location => $location,
    meta     => $meta,
    content  => $content,
  } );

Iterates through the C<constructors> and asks each to C<construct> an
item with the construction data. If no constructor returns a defined
vaue, then performs C<< Articulate::Item->new( $args ) >>.

Note that of these three pieces of data, it is not guaranteed that all
will be available at the time of construction, particularly on inbound
communication (as opposed to when retrieving from storage). This is
largely dependant on the Service. Location should always be available.
Content is often not available.

=cut

sub construct {
  my $self = shift;
  my $args = shift;
  my $constructed;
  foreach my $constructor ( @{ $self->constructors } ) {
    $constructed = $constructor->construct($args);
    return $constructed if defined $constructed;
  }
  return Articulate::Item->new($args);
}

1;
