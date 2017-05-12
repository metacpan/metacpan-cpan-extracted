#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst };
    plan skip_all =>
      "This test requires Test::WWW::Mechanize::Catalyst in order to run"
      if $@;
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.40 required' if $Test::WWW::Mechanize::Catalyst::VERSION < 0.40;
    plan 'no_plan';
}

use Test::WWW::Mechanize::Catalyst qw/CookieTestApp/;

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok( "http://localhost/stream", "get page" );
$m->content_contains( "hit number 1", "session data created" );

my $expired;
$m->cookie_jar->scan( sub { $expired = $_[8]; } );

$m->get_ok( "http://localhost/page", "get page" );
$m->content_contains( "hit number 2", "session data restored" );

$m->get_ok( "http://localhost/stream", "get stream" );
$m->content_contains( "hit number 3", "session data restored" );

sleep 1;

$m->get_ok( "http://localhost/stream", "get page" );
$m->content_contains( "hit number 4", "session data restored" );

my $updated_expired;
$m->cookie_jar->scan( sub { $updated_expired = $_[8]; } );
cmp_ok( $expired, "<", $updated_expired, "cookie expiration was extended" );

$expired = $m->cookie_jar->scan( sub { $expired = $_[8] } );
$m->get_ok( "http://localhost/page", "get page again");
$m->content_contains( "hit number 5", "session data restored (blah)" );

sleep 1;

$m->get_ok( "http://localhost/stream", "get stream" );
$m->content_contains( "hit number 6", "session data restored" );

$m->cookie_jar->scan( sub { $updated_expired = $_[8]; } );
cmp_ok( $expired, "<", $updated_expired, "streaming also extends cookie" );

$m->get_ok( "http://localhost/deleteme", "get page" );
$m->content_is( 1, 'session id changed' );

$m->get_ok( "https://localhost/page", "get page over HTTPS - init session");
$m->content_contains( "hit number 1", "first hit" );
$m->get_ok( "http://localhost/page", "get page again over HTTP");
$m->content_contains( "hit number 1", "first hit again - cookie not sent" );
$m->get_ok( "https://localhost/page", "get page over HTTPS");
$m->content_contains( "hit number 2", "second hit" );
