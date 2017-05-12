package Test::App::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
