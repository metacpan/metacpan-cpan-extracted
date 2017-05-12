package Articulate::Serialisation::Asset;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';

=head1 NAME

Articulate::Serialisation::Asset - return your asset as a file

=head1 METHODS

=head3 serialise

If the meta schema.core.file is true, send the file as a schema.core.content_type.

=cut

sub serialise {
  my $self     = shift;
  my $response = shift;
  my $type     = $response->type;
  if (  $response->data->{$type}
    and ref $response->data->{$type} eq ref {}
    and $response->data->{$type}->{schema}->{core}->{file} )
  {
    my $content_type =
      $response->data->{$type}->{schema}->{core}->{content_type} // $type;
    $self->framework->set_content_type($content_type);
    my $content = $response->data->{$type}->{content} // '';
    return $content;
  }
  return undef;
}

1;
