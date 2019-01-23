package MyApp::Controller::Root;

use Moose;
use MooseX::MethodAttributes;
use Test::Most;

extends 'Catalyst::Controller';

sub test :Path(test) Args(0) {
  my ($self, $c) = @_;
  my $foo = $c->model('Foo');

  # Make sure configloader overlay is working
  is $foo->{bar}, 'baz';
  is ref($foo), 'MyApp::Dummy2';

  $c->response->body('test');
}

__PACKAGE__->config(namespace=>'');
__PACKAGE__->meta->make_immutable;
