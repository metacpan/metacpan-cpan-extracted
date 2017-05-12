package TestApp::Controller::MatchCaptures;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

__PACKAGE__->config(
  action_roles => ['QueryParameter'],
);

sub root : Chained('/') PathPrefix CaptureArgs(0) {}

  sub page: Chained('root') QueryParam('page') CaptureArgs(0) {}

    sub has_page_q : Chained('page') PathPart('') Args(0)  {
      my ($self, $ctx) = @_;
      $ctx->response->body('has_page');
    }

  sub no_page: Chained('root') QueryParam('!page') PathPart('page') CaptureArgs(0) {}

    sub no_page_q : Chained('no_page') PathPart('') Args(0)  {
      my ($self, $ctx) = @_;
      $ctx->response->body('no_page');
    }


__PACKAGE__->meta->make_immutable;
