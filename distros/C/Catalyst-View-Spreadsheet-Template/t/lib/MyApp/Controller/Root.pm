package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
