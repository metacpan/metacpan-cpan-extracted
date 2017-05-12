package TestAppWithGlobalTrail::Controller::Foo;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
}

sub quux : Local { }

sub trail : Private { 1 }

sub end : Private { }

__PACKAGE__->meta->make_immutable;

1;
