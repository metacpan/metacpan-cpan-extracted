#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval {
        require Test::WWW::Mechanize::Catalyst;
        Test::WWW::Mechanize::Catalyst->VERSION(0.51);
    }
    or plan skip_all =>
        'Test::WWW::Mechanize::Catalyst >= 0.51 is required for this test';
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua1 = Test::WWW::Mechanize::Catalyst->new;
my $ua2 = Test::WWW::Mechanize::Catalyst->new;

$_->get_ok( "http://localhost/page", "initial get" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

$ua1->get_ok( "http://localhost/login", "log ua1 in" );
$ua1->content_contains( "logged in", "ua1 logged in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "please login",      "ua2 not logged in" );

$ua2->get_ok( "http://localhost/login", "get main page" );
$ua2->content_contains( "logged in", "log ua2 in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "you are logged in", "ua2 logged in" );

my ( $u1_expires ) = ($ua1->content =~ /(\d+)$/);
my ( $u2_expires ) = ($ua2->content =~ /(\d+)$/);

sleep 1;

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "you are logged in", "ua2 logged in" );

my ( $u1_expires_updated ) = ($ua1->content =~ /(\d+)$/);
my ( $u2_expires_updated ) = ($ua2->content =~ /(\d+)$/);

cmp_ok( $u1_expires, "<", $u1_expires_updated, "expiry time updated");
cmp_ok( $u2_expires, "<", $u2_expires_updated, "expiry time updated");

$ua2->get_ok( "http://localhost/logout", "log ua2 out" );
$ua2->content_like( qr/logged out/, "ua2 logged out" );
$ua2->content_like( qr/after 2 request/,
    "ua2 made 2 requests for page in the session" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "please login",      "ua2 not logged in" );

$ua1->get_ok( "http://localhost/logout", "log ua1 out" );
$ua1->content_like( qr/logged out/, "ua1 logged out" );
$ua1->content_like( qr/after 4 requests/,
    "ua1 made 4 request for page in the session" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

my $ua3 = Test::WWW::Mechanize::Catalyst->new;
$ua3->get_ok( "http://localhost/login", "log ua3 in" );
$ua3->get_ok( "http://localhost/dump_these_loads_session");
$ua3->content_contains('NOT');

my $ua4 = Test::WWW::Mechanize::Catalyst->new;
$ua4->get_ok( "http://localhost/page", "initial get" );
$ua4->content_contains( "please login", "ua4 not logged in" );

$ua4->get_ok( "http://localhost/login", "log ua4 in" );
$ua4->content_contains( "logged in", "ua4 logged in" );


$ua4->get( "http://localhost/page", "get page" );
my ( $ua4_expires1 ) = ($ua4->content =~ /(\d+)$/);
$ua4->get( "http://localhost/page", "get page" );
my ( $ua4_expires2 ) = ($ua4->content =~ /(\d+)$/);
is( $ua4_expires1, $ua4_expires2, 'expires has not changed' );

$ua4->get( "http://localhost/change_session_expires", "get page" );
$ua4->get( "http://localhost/page", "get page" );
my ( $ua4_expires3 ) = ($ua4->content =~ /(\d+)$/);
ok( $ua4_expires3 > ( $ua4_expires1 + 30000000), 'expires has been extended' );

diag("Testing against Catalyst $Catalyst::VERSION");
diag("Testing Catalyst::Plugin::Session $Catalyst::Plugin::Session::VERSION");

done_testing;
