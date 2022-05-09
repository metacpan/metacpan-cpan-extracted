package MyApp::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub get :Path(get) Args(0) {
  my ($self, $c) = @_;
  $c->res->body($c->csrf_token);
}

sub test :Path(test) Args(0) {
  my ($self, $c) = @_;
  $c->res->body('ok');
}

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
