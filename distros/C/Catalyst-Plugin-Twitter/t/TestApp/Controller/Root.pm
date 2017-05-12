package TestApp::Controller::Root;
use base 'Catalyst::Controller';

use strict;
use warnings;

__PACKAGE__->config->{namespace} = '';

sub index : Private {
    my ( $self, $c ) = @_;
    $c->res->body('root index');
}

sub tweet : Local {
    my ( $self, $c, $status ) = @_;
    $c->tweet( $status || scalar( $c->req->params ) );
    $c->res->body('hello');
}

sub end : Private {
    my ( $self, $c ) = @_;
    return if $c->res->body;    # already have a response
}

1;
