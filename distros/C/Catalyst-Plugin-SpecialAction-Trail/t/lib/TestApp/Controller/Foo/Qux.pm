package TestApp::Controller::Foo::Qux;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

with 'Catalyst::TraitFor::Controller::SpecialAction::Trail';

sub quux : Local { }

sub end : Private { }

__PACKAGE__->meta->make_immutable;

1;
