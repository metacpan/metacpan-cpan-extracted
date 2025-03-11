package MyApp::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Data::Dumper;

extends 'Catalyst::Controller';

sub get :Path(get) Args(0) {
  my ($self, $c) = @_;
  $c->res->body($c->csrf_token);
}

sub test :Path(test) SingleUseCSRF Args(0) {
  my ($self, $c) = @_;
  $c->res->body('ok');
}

sub skip :Path(skip) DisableCSRF Args(0) {
  my ($self, $c) = @_;
  $c->res->body('ok');
}

sub config_test :Path(config_test) Args(0) {
  my ($self, $c) = @_;
  $c->res->body(Dumper({
    default_secret => $c->csrf_default_secret,
    max_age => $c->csrf_max_age,
    token_session_key => $c->csrf_token_session_key,
    token_param_key => $c->csrf_token_param_key,
  }));
}

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;