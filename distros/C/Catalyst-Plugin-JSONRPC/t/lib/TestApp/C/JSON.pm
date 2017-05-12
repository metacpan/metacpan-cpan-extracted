package TestApp::C::JSON;

use strict;
use base 'Catalyst::Controller';

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->res->header( 'X-Test-Class' => ref($self) );
}

sub rpc : Global {
    my ( $self, $c ) = @_;
    $c->json_rpc;
}

sub echo : Remote {
    my ( $self, $c, @args ) = @_;
    return join ' ', @args;
}

sub add : Remote {
    my ( $self, $c, $a, $b) = @_;
    return $a + $b;
}

1;
