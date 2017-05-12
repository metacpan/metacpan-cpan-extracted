package TestApp::Controller::Chained;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller::ActionRole';
}

__PACKAGE__->config(
  action_roles => ['MatchRequestAccepts'],
);

sub root : Chained('/') PathPrefix CaptureArgs(0) {}

  sub text_plain : Chained('root') PathPart('') Accept('text/plain') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->response->body('text_plain');
  }

  sub text_html : Chained('root') PathPart('') Accept('text/html') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->response->body('text_html');
  }
  
  sub json : Chained('root') PathPart('') Accept('application/json') Args(0) {
    my ($self, $ctx) = @_;
    $ctx->response->body('json');
  }

  sub not_accepted : Chained('root') PathPart('') Args {
    my ($self, $ctx) = @_;
    $ctx->response->body('error_not_accepted');
 }

__PACKAGE__->meta->make_immutable;

1;
