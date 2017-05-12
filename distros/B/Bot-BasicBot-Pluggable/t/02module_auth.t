#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 27;
use Test::Bot::BasicBot::Pluggable;

my $bot = Test::Bot::BasicBot::Pluggable->new();

ok( my $auth = $bot->load('Auth'), "created auth module" );

is(
    $bot->tell_private("!auth"),
    "Usage: !auth <username> <password>",
    "auth without arguments"
);
is(
    $bot->tell_private("!adduser"),
    "Usage: !adduser <username> <password>",
    "adduser without arguments"
);
is(
    $bot->tell_private("!deluser"),
    "Usage: !deluser <username>",
    "deluser without arguments"
);
is(
    $bot->tell_private("!adduser foo bar"),
    "You need to authenticate.",
    "adding users without authentication"
);
is(
    $bot->tell_private("!deluser foo"),
    "You need to authenticate.",
    "deleting users without authentication"
);

ok( !$auth->authed('test_user'),              "test_user not authed yet" );
ok( $bot->tell_private("!auth admin muppet"), "sent bad login" );
ok( !$auth->authed('test_user'),              "test_user not authed yet" );
ok( $bot->tell_private("!auth admin julia"),  "sent good login" );
ok( $auth->authed('test_user'),               "test_user authed now" );

ok( $bot->tell_private("!adduser test_user test_user"),
    "added test_user user" );
ok( $bot->tell_private("!auth test_user fred"), "not logged in as test_user" );
ok( !$auth->authed('test_user'),                "not still authed" );
ok( $bot->tell_private("!auth test_user test_user"), "logged in as test_user" );
ok( $auth->authed('test_user'),                      "still authed" );

ok( $bot->tell_private("!deluser admin"),    "deleted admin user" );
ok( $bot->tell_private("!auth admin julia"), "tried login" );
ok( !$auth->authed('test_user'),             "not authed" );

ok( $bot->tell_private("!auth test_user test_user"), "logged in as test_user" );
ok( $bot->tell_private("!password test_user dave"),    "changed password" );
ok( $bot->tell_private("!auth test_user dave"),      "tried login" );
ok( $auth->authed('test_user'),                      "authed" );

is( $bot->tell_private("auth test_user dave"),
    "", "ignore commands without leading !" );
is( $bot->tell_indirect("!auth test_user dave"), "", "ignore public commands" );

is( $bot->tell_private("!users"), "Users: test_user.", "listing of users" );

like(
    $bot->tell_direct("help Auth"),
qr/Authenticator for admin-level commands. Usage:.+/,
    'checking help text'
);
