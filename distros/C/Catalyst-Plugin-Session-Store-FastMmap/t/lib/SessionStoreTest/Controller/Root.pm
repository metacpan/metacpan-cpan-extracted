#!/usr/bin/perl

package SessionStoreTest::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';

sub store_scalar : Global {
    my ( $self, $c ) = @_;

    $c->res->body( $c->session->{'scalar'} = 456 );
}

sub get_scalar : Global {
    my ( $self, $c ) = @_;

    $c->res->body( $c->session->{'scalar'} );
}

1;

