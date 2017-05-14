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

    plan tests => 12;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new( { agent => 'Initial user_agent'} );
$ua->get_ok( "http://localhost/user_agent", "get initial user_agent" );
$ua->content_contains( "UA=Initial user_agent", "test initial user_agent" );

$ua->get_ok( "http://localhost/page", "initial get main page" );
$ua->content_contains( "please login", "ua not logged in" );

$ua->get_ok( "http://localhost/login", "log ua in" );
$ua->content_contains( "logged in", "ua logged in" );

$ua->get_ok( "http://localhost/page", "get main page" );
$ua->content_contains( "you are logged in", "ua logged in" );

$ua->agent('Changed user_agent');
$ua->get_ok( "http://localhost/user_agent", "get changed user_agent" );
$ua->content_contains( "UA=Changed user_agent", "test changed user_agent" );

$ua->get_ok( "http://localhost/page", "test deleted session" );
$ua->content_contains( "please login", "ua not logged in" );
