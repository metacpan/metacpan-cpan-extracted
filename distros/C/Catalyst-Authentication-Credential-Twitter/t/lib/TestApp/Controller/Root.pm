package TestApp::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

sub index : Path('/index') {
    my ( $self, $c ) = @_;

    $c->res->body( 'howdie' );
}

sub login : Path('/login') {
    my ($self, $c) = @_;

    my $realm = $c->get_auth_realm('twitter');
    $c->res->body( $realm->credential->authenticate_twitter_url($c) );
}

sub auth :Path('/auth') {
    my ( $self, $c) = @_;

    $c->get_auth_realm('twitter')->credential->authenticate_twitter( $c );

    $c->res->body( 'ok' );

}

sub authenticate :Path('/authenticate') {
    my ( $self, $c ) = @_;

    my $res = $c->authenticate(undef,'twitter');

    $c->res->body( $res->{twitter_user_id} );
}

sub leaking_users :Path('/leaking_users') {
    my ( $self, $c ) = @_;
    $c->res->body($c->get_auth_realm('twitter')->credential->twitter_user($c)->{id});
}

1;
