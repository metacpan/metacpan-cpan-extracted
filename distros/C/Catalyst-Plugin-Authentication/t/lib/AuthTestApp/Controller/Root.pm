package AuthTestApp::Controller::Root;
use strict;
use warnings;
use base qw/ Catalyst::Controller /;

__PACKAGE__->config( namespace => '' );

use Test::More;
use Test::Fatal;

use Digest::MD5 qw/md5/;
use Digest::SHA qw/sha1_base64/;

sub number_of_elements { return scalar @_ }

sub moose : Local {
    my ( $self, $c ) = @_;

    is(number_of_elements($c->user), 1, "Array undef");
    is($c->user, undef, "no user, returns undef");
    ok(!$c->user, "no user");
    ok($c->login( "foo", "s3cr3t" ), "can login with clear");
    is( $c->user, $AuthTestApp::users->{foo}, "user object is in proper place");

    ok( !$c->user->roles, "no roles for foo" );
    my @new = qw/foo bar gorch/;
    $c->user->roles( @new );
    is_deeply( [ $c->user->roles ], \@new, "roles set as array");

    $c->logout;
    ok(!$c->user, "no more user, after logout");

    ok($c->login( "bar", "s3cr3t" ), "can login with crypted");
    is( $c->user, $AuthTestApp::users->{bar}, "user object is in proper place");
    $c->logout;

    ok($c->login("gorch", "s3cr3t"), "can login with hashed");
    is( $c->user, $AuthTestApp::users->{gorch}, "user object is in proper place");
    $c->logout;

    ok($c->login("shabaz", "s3cr3t"), "can login with base64 hashed");
    is( $c->user, $AuthTestApp::users->{shabaz}, "user object is in proper place");
    $c->logout;

    ok($c->login("sadeek", "s3cr3t"), "can login with padded base64 hashed");
    is( $c->user, $AuthTestApp::users->{sadeek}, "user object is in proper place");
    $c->logout;

    ok(!$c->login( "bar", "bad pass" ), "can't login with bad password");
    ok(!$c->user, "no user");

    like exception { $c->login( "baz", "foo" ) }, qr/support.*mechanism/, "can't login without any supported mech";

    $c->res->body( "ok" );
}


