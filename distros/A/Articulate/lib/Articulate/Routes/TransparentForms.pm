package Articulate::Routes::TransparentForms;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Routes';
use Articulate::Syntax::Routes;
use Articulate::Service;

get '/zone/:zone_id/create' => sub {
  my ( $self, $request ) = @_;
  my $zone_id = $request->params->{'zone_id'};
  $self->service->process_request(
    create_form => {
      location => "zone/$zone_id",
    }
  );
};

post '/zone/:zone_id/create' => sub {
  my ( $self, $request ) = @_;
  my $zone_id    = $request->params->{'zone_id'};
  my $article_id = $request->params->{'article_id'};
  return $self->process_request(
    error => {
      simple_message => 'Parameter article_id is required'
    }
  ) unless defined $article_id and $article_id ne '';
  my $content = $request->params->{'content'};
  $self->service->process_request(
    create => {
      location => "zone/$zone_id/article/$article_id",
      content  => $content,
    }
  );
};

get '/zone/:zone_id/article/:article_id/edit' => sub {
  my ( $self, $request ) = @_;
  my $zone_id    = $request->params->{'zone_id'};
  my $article_id = $request->params->{'article_id'};
  $self->service->process_request(
    edit_form => {
      location => "zone/$zone_id/article/$article_id",
    }
  );
};

1;
