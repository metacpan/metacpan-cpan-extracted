#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More;

BEGIN {
    eval {
		require Test::WWW::Mechanize::Catalyst;
    } or plan 'skip_all' => "Test::WWW::Mechanize::Catalyst required";
    plan tests => 14;
}

use Test::WWW::Mechanize::Catalyst 'ACLTestApp2';

my $m = Test::WWW::Mechanize::Catalyst->new;

my $u = "http://localhost";

$m->get_ok( "$u/foo", "get foo" );
$m->content_contains( "", "access to end forbidden" );

$m->get_ok( "$u/bar", "get bar" );
$m->content_contains( "bar", "access to end forbidden" );

ACLTestApp2->acl_allow_root_internals;

$m->get_ok( "$u/foo", "get foo" );
$m->content_contains( "denied handled", "denied, handled" );

$m->get_ok( "$u/bar", "get bar" );
$m->content_contains( "allowed bar", "allowed" );

$m->get_ok( "$u/gorch", "get gorch" );
$m->content_contains( "denied handled gorch", "denied but overridden by handler" );

$m->get_ok( "$u/gorch/wozzle", "get gorch" );
$m->content_contains( "frozjob=wozzle", "overriden acces has params intact" );
is( $m->res->header( 'X-Catalyst-ACL-Param-Action' ), 'gorch', '$action param to access_denied' );
like( $m->res->header( 'X-Catalyst-ACL-Param-Error' ), qr{Access to gorch denied by rule}, '$error param to access_denied' );
