package ExampleView::D;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
with 'ExampleView';

__PACKAGE__->meta->make_immutable;

