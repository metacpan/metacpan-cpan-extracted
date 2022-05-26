package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) {
  my ($self, $c) = @_;
  $c->stash(stash_var=>'one');
  $c->view(Hello =>
    name => 'John',
  );
} 

  sub test1 :Chained(root) Args(0) {
    my ($self, $c) = @_;
    $c->res->content_type('text/html');
    $c->res->body($c->view->get_rendered);
  }

  sub test2 :Chained(root) Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->view);
  }

  sub test3 :Chained(root) Args(0) {
    my ($self, $c) = @_;
    $c->view->http_ok;
  }


__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
