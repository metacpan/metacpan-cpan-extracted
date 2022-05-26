package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub root :Chained(/) PathPart('') CaptureArgs(0) { }

  sub tags :Chained(root) Args(0) {
    my ($self, $c) = @_;
    return $c->view(TagsHello =>
      name => 'John',
    )->http_ok;

  }

  sub test1 :Chained(root) Args(0) {
    my ($self, $c) = @_;
    my $view = $c->view(Hello =>
      name => 'John',
      age => 53
    );
    $c->res->content_type('text/html');
    $c->res->body($view->get_rendered);
  }

  sub test2 :Chained(root) Args(0) {
    my ($self, $c) = @_;
    $c->stash(test=>111);
    my $view = $c->view(Hello =>
      name => 'John',
      age => 53
    );
    $c->forward($view);
  }

  sub test3 :Chained(root) Args(0) {
    my ($self, $c) = @_;
    $c->stash(test=>222);
    my $view = $c->view(Hello =>
      name => 'John',
      age => 53
    );
    $view->http_ok;
  }


__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
