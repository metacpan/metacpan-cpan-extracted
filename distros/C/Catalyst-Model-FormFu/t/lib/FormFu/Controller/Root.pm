package FormFu::Controller::Root;

use strict;
use warnings;

use parent qw(Catalyst::Controller);

__PACKAGE__->config->{namespace} = '';

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end :ActionClass('RenderView') {}

1;
