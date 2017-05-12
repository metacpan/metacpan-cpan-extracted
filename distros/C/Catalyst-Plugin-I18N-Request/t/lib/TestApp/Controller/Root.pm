package TestApp::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub maketext : Global {
    my( $self, $c, $key ) = @_;
    $c->res->body( $c->localize( $key ) );
}

sub current_language : Global {
    my ($self, $c) = @_;
    $c->res->body( $c->language );
}

sub current_request_path : Global {
    my ($self, $c) = @_;
    $c->res->body( $c->req->path );
}

sub current_parameter_name : Global {
    my ($self, $c) = @_;
    my $parameters = $c->req->parameters;
    my ($key) = keys %$parameters;
    $c->res->body( $key );
}

sub localized_uri_for : Global {
    my ($self, $c, $path, $parameter) = @_;
    my $uri = $c->uri_for( $path, { $parameter => $parameter } );
    $c->res->body( "$uri" );
}

sub localized_uri_with : Global {
    my ($self, $c, $parameter) = @_;
    my $uri = $c->req->uri_with( { $parameter => $parameter } );
    $c->res->body( "$uri" );
}

1;
