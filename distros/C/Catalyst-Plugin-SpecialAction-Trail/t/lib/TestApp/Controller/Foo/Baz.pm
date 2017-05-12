package TestApp::Controller::Foo::Baz;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

with 'Catalyst::TraitFor::Controller::SpecialAction::Trail';

sub quux : Local { }

sub trail : Private {
  my ($self, $c) = @_;

  return $c->trail_retval;
}

__PACKAGE__->meta->make_immutable;

1;
