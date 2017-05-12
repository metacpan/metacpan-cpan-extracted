package PerUserTestApp::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace => '');

sub add_item : Local {
    my ( $self, $c, $item ) = @_;

    $c->user_session->{items}{$item} = 1;
}

sub show_items : Local {
    my ( $self, $c, $item ) = @_;

    $c->res->body(
        join( ", ", sort keys %{ $c->user_session->{items} ||= {} } ) );
}

sub auth_login : Local Args() {
    my ( $self, $c, $name ) = @_;
    $c->set_authenticated( $c->get_user($name) );
}

sub auth_logout : Local {
    my ( $self, $c ) = @_;

    $c->logout;
}

1;
