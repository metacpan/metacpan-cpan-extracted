package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;
use CatalystX::Syntax::Action;

BEGIN {
  extends 'Catalyst::Controller';
}

__PACKAGE__->config(namespace  => '');

action test : Path('') {
  $ctx->response->body('test');
}

action foo : Path('foo') {
  $ctx->response->body('foo');
}

action root : Chained('/') CaptureArgs(0) {}

  action root_0 : Chained('root') PathPart('') Args(0) {
    $ctx->response->body('root_0');
  }

  action root_1 : Chained('root') PathPart('')  Args(1)  {
    $ctx->response->body('root_1');
  }

  action root_foo_1 : Chained('root') PathPart('foo')  Args(1) {
    $ctx->response->body('root_foo_1');
  }

__PACKAGE__->meta->make_immutable;

