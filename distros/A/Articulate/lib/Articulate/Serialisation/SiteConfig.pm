package Articulate::Serialisation::SiteConfig;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';

=head1 NAME

PlainSpeaking::Serialisation::SiteConfig

=head1 METHODS

=head3 serialise

Adds site data to the response data.

=cut

has site_data => (
  is      => 'rw',
  default => sub { {} }
);

sub serialise {
  my $self     = shift;
  my $response = shift;
  $response->data->{site} = $self->site_data;
  return undef;
}

1;
