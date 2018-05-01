package MyApp::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

sub test :Path(test) Args(0) {
  my ($self, $c) = @_;
  $c->serve_file("a.txt");
}

sub static :Path(static) Args {
  my ($self, $c, @args) = @_;
  $c->serve_file('static',@args) || do {
    $c->res->status(404);
    $c->res->body('Not Found!');
  };
}

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
