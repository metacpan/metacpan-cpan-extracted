package Articulate::Routes::TransparentPreviews;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Routes';
use Articulate::Syntax::Routes;
use Articulate::Service;

post '/zone/:zone_id/preview' => sub {
  my ( $self, $request ) = @_;
  my $zone_id    = $request->params->{'zone_id'};
  my $article_id = $request->params->{'article_id'};
  return $self->process_request(
    error => {
      simple_message => 'Parameter article_id is required'
    }
  ) unless defined $article_id and $article_id ne '';
  my $content = $request->params->{'content'};
  $self->process_request(
    preview => {
      location => "zone/$zone_id/article/$article_id",
      content  => $content,
    }
  );
};

1;
