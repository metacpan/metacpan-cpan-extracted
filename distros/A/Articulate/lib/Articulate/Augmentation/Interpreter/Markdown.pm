package Articulate::Augmentation::Interpreter::Markdown;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';
use Articulate::Syntax qw (instantiate);
use Text::Markdown;

=head1 NAME

Articulate::Augmentation::Interpreter::Markdown - convert markdown to HTML

=head1 METHODS

=head3 augment

Converts markdown in the content of the response into HTML.

=cut

=head1 ATTRIBUTES

=head3 markdown_parser

The parser which will be used. This is instantiated and defaults to L<Text::Markdown> - but note that L<Text::Markdown> expects a plain hash, not a reference, so it will need to be configured as an array.

=cut

has markdown_parser => (
  is      => 'rw',
  lazy    => 1,
  default => sub {
    'Text::Markdown';
  },
  coerce => sub {
    instantiate( $_[0] );
  },
);

sub augment {
  my $self = shift;
  my $item = shift;
  $item->content( $self->markdown_parser->markdown( $item->content ) );
  return $item;
}

1;
