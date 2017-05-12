#!/usr/bin/perl

package ContTestApp::Controller::Foo;
use base qw/Catalyst::Controller/;

use strict;
use warnings;

sub counter : Local {
    my ( $self, $c ) = @_;

    my $up   = $c->continue("up");
    my $down = $c->continue("down");

    $c->res->body( join( " ", $c->stash->{counter} ||= 0, $up, $down ) );
}

sub up : Private {
    my ( $self, $c ) = @_;
    $c->stash->{counter}++;
}

sub down : Private {
    my ( $self, $c ) = @_;
    $c->stash->{counter}--;
}

__PACKAGE__;

__END__

