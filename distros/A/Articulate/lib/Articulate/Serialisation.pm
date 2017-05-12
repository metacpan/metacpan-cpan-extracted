package Articulate::Serialisation;
use strict;
use warnings;

use Moo;

with 'Articulate::Role::Component';

use Articulate::Syntax qw(instantiate_array);

=head1 NAME

Articulate::Serialisation - transform a data structure into user-facing output.

=head1 DESCRIPTION

  use Articulate::Serialisation;
  my $html = serialisation->serialise($response_object);

Go through all the defined serialisers and have them attempt to serialise the response object. The first defined result will be returned. The result be of any data type, although in practice the purpose is to use a string.

Provides a serialisation function which creates an instance of this class.

=head1 FUNCTION

=head3 serialisers

This is an arrayref of serialisers, each of whom should provide serialise functions.

=cut

has serialisers => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) },
);

=head1 FUNCTION

=head3 serialise

  my $html = $serialisation->serialise($response_object);

Sends to each of the C<serialisers> in turn. If any of them return a defined value, returns that value immediately. Otherwise, returns C<undef>.

=cut

sub serialise {
  my $self     = shift;
  my $response = shift;

  # If the user has done templating themselves already, all well and good.
  return $response unless ref $response;
  my $text;
  foreach my $serialiser ( @{ $self->serialisers } ) {
    $serialiser->app( $self->app )
      if $serialiser->can('app'); # or does Articulate::Role::Component?
    return $text if defined( $text = $serialiser->serialise($response) );
  }
  return undef;
}

1;
