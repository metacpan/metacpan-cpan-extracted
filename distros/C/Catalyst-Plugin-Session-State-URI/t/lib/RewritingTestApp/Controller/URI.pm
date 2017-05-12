#!/usr/bin/perl

package RewritingTestApp::Controller::URI;

use strict;
use warnings;

use Test::More; # love singletons (sometimes)

use base qw/Catalyst::Controller/;

sub first_request : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 1;
    $c->config->{session}{rewrite_redirect} = 1;

    ok( !$c->session_is_valid, "no session" );

    $c->session->{counter} = 1;

    $c->forward("add_some_html");
}

sub second_request : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 1;
    $c->config->{session}{rewrite_redirect} = 1;

    ok( $c->session_is_valid, "session exists" );

    is( ++$c->session->{counter}, 2, "counter is OK" );

    $c->forward("add_some_html");
}


sub third_request : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 1;
    $c->config->{session}{rewrite_redirect} = 1;

    ok( $c->session_is_valid, "session exists" );

    is( ++$c->session->{counter}, 3, "counter is OK" );

    $c->forward("add_some_html");
}

sub add_some_html : Private {
    my ( $self, $c ) = @_;

    # no using uri_for, because it's overloaded

    my $counter = $c->session->{counter};

    $c->response->content_type("text/html");
    $c->response->body( <<HTML );
<html>
    <head>
        <title>I like Moose</title>
    </head>
    <body>

        counter: $counter

        <a href="/second_request">second</a>
        <a href="/third_request">third</a>
    </body>
</html>
HTML
}

sub text_request : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 1;
    $c->config->{session}{rewrite_redirect} = 1;

    $c->session->{counter} = 42;
    $c->forward("add_some_html");

    $c->response->content_type("text/plain") if $c->request->param("plain");
}

sub redirect : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 1;
    $c->config->{session}{rewrite_redirect} = 1;

    $c->session->{counter} = 43;

    $c->response->status(302);
    $c->response->location( '/whatever' );
}

sub only_rewrite_redirect : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 0;
    $c->config->{session}{rewrite_redirect} = 1;

    $c->session->{counter} = 43;

    $c->response->status(302);
    $c->response->location( '/whatever' );
}

sub dont_rewrite_redirect : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 0;
    $c->config->{session}{rewrite_redirect} = 0;

    $c->session->{counter} = 43;

    $c->response->status(302);
    $c->response->location( '/whatever' );
}

sub only_rewrite_body : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 1;
    $c->config->{session}{rewrite_redirect} = 0;

    $c->session->{counter} = 43;

    $c->forward("add_some_html");
}

sub dont_rewrite_body : Global {
    my ( $self, $c ) = @_;

    $c->config->{session}{rewrite_body} = 0;
    $c->config->{session}{rewrite_redirect} = 0;

    $c->session->{counter} = 43;

    $c->forward("add_some_html");
}

__PACKAGE__;

__END__
