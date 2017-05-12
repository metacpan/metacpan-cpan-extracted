#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib "t/lib";

use ok "Test::WWW::Mechanize::Catalyst" => "ContTestApp";

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok("http://localhost/needslogin?x=bar&y=baz", "get initial uri");
$m->content_like( my $login_re = qr/^login required: (.*)$/, "login required" );

my ( $login_url ) = ($m->content =~ $login_re);
like( $login_url, qr{^http://.*?/login/.+}, "login url looks OK");

$m->get_ok( "$login_url?user=gorch", "get login uri" );
$m->content_like( my $values_re = qr/user: gorch, values: (.*)/, "param from login request");

my ( $values ) = ( $m->content =~ $values_re );
ok( length($values), "got some values");

my @values = split(", ", $values);
is( @values, 3, "three values");

is( $values[0], "foo", "value from stash");
is( $values[1], "bar", "value from param, stashed");
is( $values[2], "baz", "value from param, unstashed");


$m->get_ok("http://localhost/needslogin?x=ding&y=bat", "get initial uri with active session");
$m->content_is( "user: gorch, values: foo, ding, bat", "single request when already logged in");
