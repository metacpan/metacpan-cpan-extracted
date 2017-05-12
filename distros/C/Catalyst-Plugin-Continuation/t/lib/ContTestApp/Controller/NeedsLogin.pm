#!/usr/bin/perl

package ContTestApp::Controller::NeedsLogin;
use base qw/Catalyst::Controller/;

use strict;
use warnings;

sub default : Private {
    my ( $self, $c ) = @_;

    # demonstrates capture of the stash
    $c->stash->{val_a} = "foo";
    $c->stash->{val_b} = $c->req->param("x");

    $c->forward("child_action");
}

sub child_action : Private {
    my ( $self, $c ) = @_;

    my $user = $c->session->{user};
    $c->detach("login_required") unless $user;

    $c->res->body(
        "user: $user, values: " . join(", ",
            @{$c->stash}{qw/val_a val_b/}, # restored stash
            $c->req->param("y"), # restored params
        )
    );
}

sub login_required : Local {
    my ( $self, $c ) = @_;
    my $cont = $c->caller_continuation;
    $cont->save_in_store;
    $c->res->body("login required: " . $c->uri_for("login", $cont->id)); # pretend this is a form
}

sub login : Local { # pretend this is a <form action="...">
    my ( $self, $c, $cont_id ) = @_;

    # $c->login( .... );
    $c->session->{user} = $c->req->param("user");

    $c->resume_continuation( $cont_id );
}

__PACKAGE__;

__END__


