package TestApp::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::HTML::Zoom';

__PACKAGE__->meta->make_immutable;
