package TestApp::ViewBase::Foo;
use Moose;
extends 'Catalyst::View';

has something => ( is => 'ro' );

1;
