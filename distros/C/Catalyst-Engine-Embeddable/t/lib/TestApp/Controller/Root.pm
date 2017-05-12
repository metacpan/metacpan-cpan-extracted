package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body( 'Hello' );
}

sub foo : Local {
    my ( $self, $c ) = @_;
    $c->res->body('Hello World!');
}

sub bar : Local {
    my ( $self, $c ) = @_;
    $c->res->body('Hello '.$c->req->param('who').'!');
}

sub mkuri : Local {
    my ( $self, $c ) = @_;
    $c->res->body($c->uri_for('/path/to/somewhere'));
}

sub mkuriwithpath : Local {
    my ( $self, $c ) = @_;
    $c->res->body($c->uri_for('/path/to/somewhere', { baz => 'qux' }));
}

sub eatit : Local {
    my ( $self, $c ) = @_;
    die 'DIAF';
}

1;
