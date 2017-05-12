package TestApp::Controller::URI;

use strict;
use base 'Catalyst::Controller';
use Carp;
$Carp::Verbose = 1;

sub auto : Private {
    my ( $self, $c ) = @_;
    $c->config->{session}{overload_uri_for} = 0;
    $c->session->{key} = "val";
}

sub index : Private {
    my ( $self, $c ) = @_;
    $c->res->body( $c->uri_for("/foo/bar") );
}

sub arg : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->uri_for("/foo/bar", "arg") );
}

sub param : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->uri_for("/foo/bar", { param => "value" } ) );
}

sub body_param : Local {
    my ( $self, $c ) = @_;
    my $param_scalar = $c->req->body_parameters->{'body_param'};
    $c->res->body( $c->uri_for("/foo/bar", { param => $param_scalar } ) );
}

sub arg_param : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->uri_for("/foo/bar", "arg", { param => "value" } ) );
}

sub sid : Local {
    my ( $self, $c ) = @_;
    $c->config->{session}{overload_uri_for} = 1;
    $c->res->body( $c->uri_for("/foo/bar") );
}

sub sid_arg : Local {
    my ( $self, $c ) = @_;
    $c->config->{session}{overload_uri_for} = 1;
    $c->res->body( $c->uri_for("/foo/bar", "arg") );
}

sub sid_param : Local {
    my ( $self, $c ) = @_;
    $c->config->{session}{overload_uri_for} = 1;
    $c->res->body( $c->uri_for("/foo/bar", { param => "value" } ) );
}

sub sid_arg_param : Local {
    my ( $self, $c ) = @_;
    $c->config->{session}{overload_uri_for} = 1;
    $c->res->body( $c->uri_for("/foo/bar", "arg", { param => "value" } ) );
}

1;
