package Articulate::Augmentation;
use strict;
use warnings;

use Moo;

with 'Articulate::Role::Component';

use Articulate::Syntax qw(instantiate_array);

=head1 NAME

Articulate::Augmentaton - add bells and whistles to your response

=head1 DESCRIPTION

  use Articulate::Augmentation;
  $response = augmentation->augment($response);

This will pass the response to a series of augmentation objects, each of which has the opportunity to alter the response according to their own rules, for instance, to retrieve additional related content (e.g. article comments).

Note: the response passed in is not cloned so this will typically mutate the response.

=head1 ATTRIBUTES

=head3 augmentations

An array of the augmentation classes which will be used.

=cut

has augmentations => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) }
);

=head1 METHODS

=head3 augment

Passes the response object to a series of augmentation objects, and returns the response after each has done their bit.

=cut

sub augment {
  my $self = shift;
  my $item = shift;
  foreach my $aug ( @{ $self->augmentations } ) {
    $item = $aug->augment($item);
  }
  return $item;
}

1;
