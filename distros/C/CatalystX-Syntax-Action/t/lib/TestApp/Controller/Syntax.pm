package TestApp::Controller::Syntax;

use Moose;
use namespace::autoclean;
use syntax 'catalyst_action';

BEGIN {
  extends 'Catalyst::Controller';
}

action root : Chained('/') PathPrefix CaptureArgs(0) {}

  action root_0 : Chained('root') PathPart('') Args(0) {
    $ctx->response->body('syntax_root_0');
  }

  action root_1 : Chained('root') PathPart('')  Args(1)  {
    $ctx->response->body('syntax_root_1');
  }

  action root_foo_1 : Chained('root') PathPart('foo')  Args(1) {
    $ctx->response->body('syntax_root_foo_1');
  }

__PACKAGE__->meta->make_immutable;

