#!/usr/bin/perl

package DynamicExpiryApp::Controller::Foo;

use strict;
use warnings;

use base qw/Catalyst::Controller/;

sub counter : Local {
    my ( $self, $c ) = @_;
    $c->res->body( ++$c->session->{counter} );
}

sub remember_me : Local {
    my ( $self, $c ) = @_;
    $c->session_time_to_live( 60 * 60 * 24 * 365 ); # a year
    $c->forward("counter");
}

__PACKAGE__;

