package TestApp::Controller::Foo;
use Moose;
BEGIN { extends 'Catalyst::Controller' }
no Moose;
__PACKAGE__->meta->make_immutable;
