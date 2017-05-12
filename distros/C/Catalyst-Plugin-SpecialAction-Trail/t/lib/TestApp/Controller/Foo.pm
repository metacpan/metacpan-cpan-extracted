package TestApp::Controller::Foo;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

sub quux : Local { }

sub trail : Private {
  my ($self, $c) = @_;

  return $c->trail_retval;
}

__PACKAGE__->meta->make_immutable;

1;
