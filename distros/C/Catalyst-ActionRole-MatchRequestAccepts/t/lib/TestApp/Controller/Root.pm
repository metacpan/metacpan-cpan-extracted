package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller::ActionRole';
}

__PACKAGE__->config(
  namespace    => '',
  action_roles => ['MatchRequestAccepts'],
);

sub text_html : Path('foo') Accept('text/html') {
  my ($self, $ctx) = @_;
  $ctx->response->body('text_html');
}

sub text_plain_and_html : Path('text_plain_and_html') Accept('text/plain') Accept('text/html') {
  my ($self, $ctx) = @_;
  $ctx->response->body('text_plain_and_html');
}

sub text_plain : Path('foo') Accept('text/plain') {
  my ($self, $ctx) = @_;
  $ctx->response->body('text_plain');
}

sub json : Path('foo') Accept('application/json') {
  my ($self, $ctx) = @_;
  $ctx->response->body('json');
}

sub any_method : Path('baz') {
  my ($self, $ctx) = @_;
  $ctx->response->body('any');
}

__PACKAGE__->meta->make_immutable;

1;
