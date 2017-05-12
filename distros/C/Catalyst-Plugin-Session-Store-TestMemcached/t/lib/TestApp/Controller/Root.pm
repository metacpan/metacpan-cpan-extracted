package TestApp::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub welcome : Path(welcome) {
  my ($self, $ctx) = @_;
  my $count = ++$ctx->session->{count};
  $ctx->session(count => $count);
  $ctx->res->body("Welcome to Catalyst: $count");
}

__PACKAGE__->meta->make_immutable;
