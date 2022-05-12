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

sub in_session :Path(in_session) Args(0) {
  my ($self, $c) = @_;
  $c->res->body($c->single_use_csrf_token);
}


__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;

__END__

sub by_action :Path(by_action) Args() CheckCSRF() {
  my ($self, $c) = @_;

}

  sub by_action_CSRF_EXPIRED {
    my ($self, $c) = @_;
  }

  sub by_action_CSRF_INVALID {
    my ($self, $c) = @_;
  }

