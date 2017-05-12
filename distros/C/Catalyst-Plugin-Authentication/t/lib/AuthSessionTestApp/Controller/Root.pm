package AuthSessionTestApp::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace => '');

use Test::More;
use Test::Exception;

use Digest::MD5 qw/md5/;

sub moose : Local {
    my ( $self, $c ) = @_;

    ok(!$c->sessionid, "no session id yet");
    ok(!$c->user_exists, "no user exists");
    ok(!$c->user, "no user yet");
    ok($c->login( "foo", "s3cr3t" ), "can login with clear");
    is( $c->user, $AuthSessionTestApp::users->{foo}, "user object is in proper place");
}

sub elk : Local {
    my ( $self, $c ) = @_;

    ok( $c->sessionid, "session ID was restored" );
    ok( $c->user_exists, "user exists" );
    ok( $c->user, "a user was also restored");
    is_deeply( $c->user, $AuthSessionTestApp::users->{foo}, "restored user is the right one (deep test - store might change identity)" );

    # Rename the user!
    $AuthSessionTestApp::users->{bar} = delete $AuthSessionTestApp::users->{foo};
}

sub yak : Local {
    my ( $self, $c ) = @_;
    ok( $c->sessionid, "session ID was restored after user renamed" );
    ok( $c->user_exists, "user appears to exist" );
    ok( !$c->user, "user was not restored");
    ok(scalar(@{ $c->error }), 'Error recorded');
    ok( !$c->user_exists, "user no longer appears to exist" );
}

sub goat : Local {
    my ( $self, $c ) = @_;
    ok($c->login( "bar", "s3cr3t" ), "can login with clear (new username)");
    is( $c->user, $AuthSessionTestApp::users->{bar}, "user object is in proper place");
    $c->logout;
}

sub fluffy_bunny : Local {
    my ( $self, $c ) = @_;

    ok( $c->session_is_valid, "session ID is restored after logout");
    ok( !$c->user, "no user was restored after logout");

    $c->delete_session("bah");
}

sub possum : Local {
    my ( $self, $c ) = @_;

    ok( !$c->session_is_valid, "no session ID was restored");
    $c->session->{definitely_not_a_user} = "moose";

}

sub butterfly : Local {
    my ( $self, $c ) = @_;

    ok( $c->session_is_valid, "valid session" );
    ok( !$c->user_exists, "but no user exists" );
    ok( !$c->user, "no user object either" );
}

1;

