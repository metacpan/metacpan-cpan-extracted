package TestApp::Controller::Configuration;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

__PACKAGE__->config(
  action_roles => ['QueryParameter'],
  action => {
    is_one => { QueryParam => 'page:==1'},
    equal_or_greater_200 => { QueryParam => 'page:>=200'},
    more_than_one => { QueryParam => [['page','>', 1]] },
  },

);

sub root : Chained('/') PathPrefix CaptureArgs(0) {}

  sub is_one : Chained('root') PathPart('') Args(0) {
      my ($self, $ctx) = @_;
      $ctx->response->body('is_one');
  }

  sub equal_or_greater_200 : Chained('root') PathPart('') Args(0) {
      my ($self, $ctx) = @_;
      $ctx->response->body('equal_or_greater_200');
  }

  sub more_than_one : Chained('root') PathPart('') Args(0) {
      my ($self, $ctx) = @_;
      $ctx->response->body('more_than_one');
  }
  
  sub no_query : Chained('root') PathPart('') Args(0)  {
    my ($self, $ctx) = @_;
    $ctx->response->body('no_query');
  }

__PACKAGE__->meta->make_immutable;

1;
