package TestApp::Controller::Conditions;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

__PACKAGE__->config(
  action_roles => ['QueryParameter'],
);

sub root : Chained('/') PathPrefix CaptureArgs(0) {}

  sub is_one : Chained('root') PathPart('') QueryParam("page:==1") Args(0) {
      my ($self, $ctx) = @_;
      $ctx->response->body('is_one');
  }

  sub equal_or_greater_200 : Chained('root') PathPart('') QueryParam("page:>=200") Args(0) {
      my ($self, $ctx) = @_;
      $ctx->response->body('equal_or_greater_200');
  }

  sub more_than_one : Chained('root') PathPart('') QueryParam("page:>1") Args(0) {
      my ($self, $ctx) = @_;
      $ctx->response->body('more_than_one');
  }
  
  sub no_query : Chained('root') PathPart('') Args(0)  {
    my ($self, $ctx) = @_;
    $ctx->response->body('no_query');
  }

__PACKAGE__->meta->make_immutable;

1;
