package TestAppWithGlobalTrail::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN {
  extends 'Catalyst::Controller';
};

__PACKAGE__->config->{'namespace'} = '';

sub trail : Private { 1 }

__PACKAGE__->meta->make_immutable;

1;
