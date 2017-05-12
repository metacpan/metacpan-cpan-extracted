package Articulate::Serialisation::TemplateToolkit;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';

=head1 NAME

Articulate::Serialisation::TemplateToolkit - put your response into a TT2 template

=head1 METHODS

=head3 serialise

Finds the template corresponding to the response type and processes it, passing in the response data.

=cut

sub serialise {
  my $self     = shift;
  my $response = shift;
  return $self->framework->template_process( $response->type, $response->data );
}

1;
