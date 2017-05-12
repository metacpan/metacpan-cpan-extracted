package TestApp::Controller::Chained;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

__PACKAGE__->config(
  action_roles => ['QueryParameter'],
);

sub root : Chained('/') PathPrefix CaptureArgs(0) {}

  sub page_and_row : Chained('root') PathPart('') QueryParam('page') QueryParam('row') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->response->body('page_and_row');
  }

  sub page : Chained('root') PathPart('')  QueryParam('page') Args(0)  {
    my ($self, $ctx) = @_;
    $ctx->response->body('page');
  }

  sub row : Chained('root') PathPart('')  QueryParam('row') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->response->body('row');
  }

  sub no_query : Chained('root') PathPart('') Args(0)  {
    my ($self, $ctx) = @_;
    $ctx->response->body('no_query');
  }

__PACKAGE__->meta->make_immutable;

1;
