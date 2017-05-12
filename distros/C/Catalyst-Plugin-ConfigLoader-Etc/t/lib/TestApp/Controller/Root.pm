#!/usr/bin/perl

package TestApp::Controller::Root;
use base 'Catalyst::Controller';
use Data::Dump qw/dump/;
use Test::More;

__PACKAGE__->config->{namespace} = '';

sub default : Private {
    my ($self, $c) = @_;
    $c->res->body(dump($c->config));
}

sub foo : Local {
    my ($self, $c, $varname) = @_;
    my $result = $c->config->{$varname};
    if (ref $result) {
        $result = dump($result);
    }
    $c->res->body($result);
}

sub root : Chained('/') PathPart('') CaptureArgs(0) {
}

sub base : Chained('root') CaptureArgs(0) PathPart('') {
}

sub test : Chained('base') CaptureArgs(0) {
}

sub scalar : Chained('test') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body( $c->config->{scalar} );
}

sub array : Chained('test') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body( dump($c->config->{array}) );
}

sub hash : Chained('test') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body( dump($c->config->{hash}) );
}

1;
