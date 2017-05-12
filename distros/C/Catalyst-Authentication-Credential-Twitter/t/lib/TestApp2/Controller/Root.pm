package TestApp2::Controller::Root;

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

1;
