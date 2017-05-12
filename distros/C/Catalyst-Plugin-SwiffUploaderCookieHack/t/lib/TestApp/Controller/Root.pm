package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub set_session_foo : Local {
  my ($self, $ctx) = @_;
  $ctx->session->{foo} = 'bar';
  $ctx->res->body('<h1>session foo set to bar</h1>');
}

sub check_session_foo : Local {
  my ($self, $ctx) = @_;
  $ctx->res->body(sprintf '<h1>session foo still %s</h1>', $ctx->session->{foo} || '');
}

sub session_id : Local {
  my ($self, $ctx) = @_;
  $ctx->res->body($ctx->sessionid);
}

sub set_session_bazz : Local {
  my ($self, $ctx) = @_;
  $ctx->session->{bazz} = 'quxx';
  $ctx->res->body('<h1>session bazz set to quxx</h1>');
}


sub check_session_bazz : Local {
  my ($self, $ctx) = @_;
  $ctx->res->body(sprintf '<h1>session bazz still %s</h1>', $ctx->session->{bazz} || '');
}

__PACKAGE__->meta->make_immutable;
