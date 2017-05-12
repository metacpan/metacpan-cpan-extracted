package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

__PACKAGE__->config(
  namespace    => '',
  action_roles => ['QueryParameter'],
);

sub no_query : Path('foo') {
  my ($self, $ctx) = @_;
  $ctx->response->body('no_query');
}

sub page : Path('foo') QueryParam('page') {
  my ($self, $ctx) = @_;
  $ctx->response->body('page');
}

sub row : Path('foo') QueryParam('row') {
  my ($self, $ctx) = @_;
  $ctx->response->body('row');
}

sub page_and_row : Path('foo') QueryParam('page') QueryParam('row') {
  my ($self, $ctx) = @_;
  $ctx->response->body('page_and_row');
}

sub optional_bar :Path('bar') QueryParam('?bar') {
  my ($self, $ctx) = @_;
  $ctx->response->body('optional_bar');
}

sub has_default : Path('has_default') QueryParam(default=foobar) {
  my ($self, $ctx) = @_;
  my $d = $ctx->req->query_parameters->{default};
  $ctx->response->body("has_default: $d");
}

sub optional_num :Path('num') QueryParam('?num:>10') {
  my ($self, $ctx) = @_;
  $ctx->response->body('optional_num');
}



__PACKAGE__->meta->make_immutable;

1;
