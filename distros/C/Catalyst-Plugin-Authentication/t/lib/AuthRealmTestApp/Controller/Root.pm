package AuthRealmTestApp::Controller::Root;
use warnings;
use strict;
use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace => '');

use Test::More;

sub moose : Local {
    my ( $self, $c ) = @_;

    ok(!$c->user, "no user");

    while ( my ($user, $info) = each %$AuthRealmTestApp::members ) {

        ok(
            $c->authenticate(
                { username => $user, password => $info->{password} },
                'members'
            ),
            "user $user authentication"
        );

        # check existing realms
        ok( $c->user_in_realm('members'), "user in members realm");
        ok(!$c->user_in_realm('admins'),  "user not in admins realm");

        # check an invalid realm
        ok(!$c->user_in_realm('foobar'), "user not in foobar realm");

        # check if we've got the right user
        is( $c->user, $info, "user object is in proper place");

        $c->logout;

        # sanity check
        ok(!$c->user, "no more user after logout");

    }

    while ( my ($user, $info) = each %$AuthRealmTestApp::admins ) {

        ok(
            $c->authenticate(
                { username => $user, password => $info->{password} },
                'admins'
            ),
            "user $user authentication"
        );

        # check existing realms
        ok(!$c->user_in_realm('members'), "user not in members realm");
        ok( $c->user_in_realm('admins'),  "user in admins realm");

        # check an invalid realm
        ok(!$c->user_in_realm('foobar'), "user not in foobar realm");

        # check if we've got the right user
        is( $c->user, $info, "user object is in proper place");

        $c->logout;

        # sanity check
        ok(!$c->user, "no more user after logout");

    }

    $c->res->body( "ok" );
}

1;

