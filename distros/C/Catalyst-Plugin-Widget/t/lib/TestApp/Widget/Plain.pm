package TestApp::Widget::Plain;

use Moose;

extends 'Catalyst::Plugin::Widget::Base';

has value => ( is => 'rw' );

sub render { shift->value }


__PACKAGE__->meta->make_immutable;

1;

