package ParamApp::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

sub foo : Path('/resolve_as_component') {
    my ( $self, $c ) = @_;

    $c->res->body( $c->uri_for( '/foo/something' ) );
}

sub bar : Path('/resolve_merged') {
    my ( $self, $c ) = @_;

    $c->res->body( $c->uri_for( '/bar/something' ) );
}


sub baz : Path('/normal') {
    my ( $self, $c ) = @_;

    $c->res->body( $c->uri_for( '/baz/something' ) );
}

sub r1 : Path('/foo/something') {
    my ( $self, $c ) = @_;
    $c->res->body('working');
}
sub r2 : Path('/bar/something') {
    my ( $self, $c ) = @_;
    $c->res->body('working');
}
sub r3 : Path('/baz/something') {
    my ( $self, $c ) = @_;
    $c->res->body('working');
}

1;
