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

    plan tests => 4;
}
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::WWW::Mechanize::Catalyst "SessionValid";

my $ua = Test::WWW::Mechanize::Catalyst->new;

$ua->get_ok( "http://localhost/", "initial get" );
$ua->content_contains( "value set", "page contains expected value" );

sleep 2;

$ua->get_ok( "http://localhost/", "grab the page again, after the session has expired" );
$ua->content_contains( "value set", "page contains expected value" );

