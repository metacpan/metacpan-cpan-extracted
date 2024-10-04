package Example::Controller::Root;

use Moose;
use MooseX::MethodAttributes;


extends 'Catalyst::Controller';

sub hello :Local  {
  my ($self, $c) = @_;
  return $c->view('Hello')->http_ok;
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(namespace => '');
