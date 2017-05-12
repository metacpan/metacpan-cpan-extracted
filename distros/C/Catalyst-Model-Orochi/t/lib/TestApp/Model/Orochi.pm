package TestApp::Model::Orochi;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Orochi';

__PACKAGE__->meta->make_immutable();

1;
