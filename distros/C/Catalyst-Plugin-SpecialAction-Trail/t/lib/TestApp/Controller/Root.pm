package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
};

__PACKAGE__->config->{'namespace'} = '';

sub trail : Private {
  my ($self, $c) = @_;

  return $c->trail_retval;
}

__PACKAGE__->meta->make_immutable;

1;
