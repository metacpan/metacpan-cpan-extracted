#!/usr/bin/env perl

# in reality this would be in a separate file
package ExampleApp;

# automatically enables "strict", "warnings", "utf8" and perl 5.10 features
use Mojo::Base qw( Mojolicious );

sub startup {
    my ( $self ) = @_;

    $self->plugin( 'tt_renderer' );

    $self->routes->any('/example_form')
        ->to('ExampleController#example_form');
}

# in reality this would be in a separate file
package ExampleApp::ExampleController;

use Mojo::Base 'Mojolicious::Controller';

sub example_form {
    my ( $self ) = @_;

    $self->stash(
        result => $self->param( 'user_input' )
    );

    $self->render( 'example_form' );
}

# in reality this would be in a separate file
package main;

use strict;
use warnings;

use Mojolicious::Commands;

Mojolicious::Commands->start_app( 'ExampleApp' );
