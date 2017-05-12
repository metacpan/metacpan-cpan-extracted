#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More;

BEGIN {
    eval {
		require Test::WWW::Mechanize::Catalyst;
		require Catalyst::Plugin::Authorization::Roles;
		require Catalyst::Plugin::Authentication;
		require Catalyst::Plugin::Session;
		require Catalyst::Plugin::Session::State::Cookie;
    } or plan 'skip_all' => "A bunch of plugins are required for this test... Look in the source if you really care... $@";
    plan tests => 97;
}

use Test::WWW::Mechanize::Catalyst 'ACLTestApp';

my $m = Test::WWW::Mechanize::Catalyst->new;

my $u = "http://localhost";

is_allowed("", "welcome");

is_denied("restricted");
is_denied("lioncage");
is_denied("zoo/elk");
is_denied("zoo/moose");
is_denied("zoo/rabbit");
is_denied("zoo/penguins/emperor");
is_denied("zoo/penguins/tux");
is_denied("zoo/penguins/madagascar");

login(qw/foo bar/);

is_allowed("auth/check", "logged in");

is_denied("restricted");
is_denied("lioncage");
is_allowed("zoo/elk");
is_denied("zoo/moose");
is_denied("zoo/rabbit");
is_allowed("zoo/penguins/emperor");
is_denied("zoo/penguins/tux");
is_allowed("zoo/penguins/madagascar");

is_allowed("auth/logout");

is_denied("restricted");
is_denied("lioncage");
is_denied("zoo/elk");
is_denied("zoo/moose");
is_denied("zoo/rabbit");
is_denied("zoo/penguins/emperor");
is_denied("zoo/penguins/tux");
is_denied("zoo/penguins/madagascar");

login(qw/gorch moose/);

is_allowed("zoo/elk");
is_denied("zoo/moose");
is_allowed("zoo/rabbit");
is_denied("lioncage");
is_denied("restricted");
is_allowed("zoo/penguins/emperor");
is_allowed("zoo/penguins/tux");
is_allowed("zoo/penguins/madagascar");

login(qw/quxx ding/);

is_allowed("zoo/elk");
is_allowed("zoo/moose");
is_denied("zoo/rabbit");
is_allowed("lioncage");
is_denied("restricted");
is_allowed("zoo/penguins/emperor");
is_denied("zoo/penguins/tux");
is_allowed("zoo/penguins/madagascar");

sub login {
	my ( $l, $p ) = @_;
	is_allowed("auth/login?login=$l&password=$p", "login successful");
}

sub is_denied {
	my $path = shift;
	local $Test::Builder::Level = 2;
	$m->get_ok("$u/$path", "get '$path'");
	$m->content_is("denied", "access to '$path' is denied");
}

sub is_allowed {
	my ( $path, $contains ) = @_;
	$path ||= "";
	$m->get_ok("$u/$path", "get '$path'");
	$m->content_contains( $contains, "'$path' contains '$contains'") if $contains;
	$m->content_like(qr/allowed$/, "access to '$path' is allowed");
}

