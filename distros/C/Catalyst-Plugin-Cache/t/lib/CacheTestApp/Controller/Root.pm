#!/usr/bin/perl

package CacheTestApp::Controller::Root;
use base qw/Catalyst::Controller/;

use strict;
use warnings;

__PACKAGE__->config( namespace => "" );

sub foo : Local {
    my ( $self, $c ) = @_;

    $c->cache->set( foo => "Foo" );
}

sub bar : Local {
    my ( $self, $c ) = @_;

    $c->res->body( $c->cache->get( "foo" ) || "not found" );
}

__PACKAGE__;

__END__
