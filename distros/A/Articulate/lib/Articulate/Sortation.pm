package Articulate::Sortation;
use strict;
use warnings;

use Moo;
use Articulate::Syntax qw(instantiate_array);

use Exporter::Declare;
default_exports qw(sortation);

=head1 NAME

Articulate::Sortation - Sort content items

=head1 DESCRIPTION

  use Articulate::Sortation;
  $request = sortation->sort( [ $item1, $item2 ], {} );

This accepts an array of items. pass the item and the request to a series of Sortation objects.

Sortations should not mutate the items, however there is no technical barrier to them doing so.

=head1 CONFIGURATION

This can be set up to perform default sorts, however it's fully anticipated that you will need to configure sorts on a per-item basis (e.g. the user may request items with a different sort order).

=head1 FUNCTION

=head3 sortation

This is a functional constructor: it returns an Articulate::Sortation object.

=cut

sub sortation {
  return __PACKAGE__->new(@_) if @_;
}

=head1 ATTRIBUTES

=head3 sortations

An array of the Sortation classes which will be used.

=cut

has sortations => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) }
);

=head1 METHODS

=head3 sort

Passes the item and request objects to a series of Sortation objects, and returns the item after each has done their bit.

=cut

sub sort {
  my $self  = shift;
  my $items = shift;
  foreach my $sortation ( @{ $self->sortations } ) {
    $items = $sortation->sort($items);
  }
  return $items;
}

1;
