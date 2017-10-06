package MyApp::Controller::Loops;

use Moose;
use MooseX::MethodAttributes;
extends 'Catalyst::Controller';

sub display :Path('') {
  my ($self, $c) = @_;
  $c->view('Loops')->http_ok;
}

__PACKAGE__->meta->make_immutable;
