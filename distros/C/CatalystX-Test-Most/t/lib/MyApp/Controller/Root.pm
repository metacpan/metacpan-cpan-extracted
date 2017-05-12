package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;
BEGIN { extends "Catalyst::Controller" }

__PACKAGE__->config(namespace => "");

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->body("OHAI");
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( "Page not found" );
    $c->response->status(404);
}

sub end : ActionClass("RenderView") {}

__PACKAGE__->meta->make_immutable;

1;
