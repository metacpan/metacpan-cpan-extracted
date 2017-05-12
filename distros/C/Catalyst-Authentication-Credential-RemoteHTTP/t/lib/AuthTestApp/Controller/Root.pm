package AuthTestApp::Controller::Root;
use warnings;
use strict;

use base qw/Catalyst::Controller/;

use Test::More;
use Test::Exception;

__PACKAGE__->config(namespace => '');

sub testnotworking : Path('/testnotworking') {
    my ( $self, $c ) = @_;

    ok( !$c->user, "no user [nowork]" );
    while ( my ( $user, $info ) = each %$AuthTestApp::members ) {
        ok(
            !$c->authenticate(
                { username => $user, password => $info->{password} }, 'members'
            ),
            "user $user authentication [nowork]"
        );
        ok(
            !$c->authenticate(
                { username => $user, password => 'wrong password' }, 'members'
            ),
            "user $user authentication - wrong password [nowork]"
        );
    }
    $c->res->body("ok");
}

sub testworking : Path('/testworking') {
    my ( $self, $c ) = @_;

    ok( !$c->user, "no user [work]" );
    while ( my ( $user, $info ) = each %$AuthTestApp::members ) {
        ok(
            $c->authenticate(
                { username => $user, password => $info->{password} }, 'members'
            ),
            "user $user authentication [work]"
        );
        ok(
            !$c->authenticate(
                { username => $user, password => 'wrong password' }, 'members'
            ),
            "user $user authentication - wrong password [work]"
        );

        $c->logout;

        # sanity check
        ok( !$c->user, "no more user after logout [work]" );

    }
    $c->res->body("ok");
}

1;

