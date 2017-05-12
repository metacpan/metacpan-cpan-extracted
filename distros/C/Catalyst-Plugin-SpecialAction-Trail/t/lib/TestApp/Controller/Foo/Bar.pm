package TestApp::Controller::Foo::Bar;

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

sub end : Private { }

__PACKAGE__->meta->make_immutable;

1;
