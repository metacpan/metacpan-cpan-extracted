#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use URI::Escape;
use Test::More;

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst };
    plan skip_all =>
      "This test requires Test::WWW::Mechanize::Catalyst in order to run"
      if $@;
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.40 required' if $Test::WWW::Mechanize::Catalyst::VERSION < 0.40;
}

use Test::WWW::Mechanize::Catalyst qw/TestApp/;

my $m = Test::WWW::Mechanize::Catalyst->new;

#Number of tests to run. A begin block every 10 will ensure the count is correct
my $tests;
plan tests => $tests;

$m->get_ok( "http://localhost/start_session", "get page" );
my $session = uri_escape($m->content);

$m->get_ok( "http://localhost/page/$session", "get page" );
$m->content_contains( "hit number 2", "session data restored" );

$m->get_ok( "http://localhost/stream/$session", "get stream" );
$m->content_contains( "hit number 3", "session data restored" );

BEGIN { $tests += 5; }

$m->get_ok( "http://localhost/stream/$session", "get page" );
$m->content_contains( "hit number 4", "session data restored" );
$m->get_ok( "http://localhost/deleteme/$session", "get page" );

TODO: {
    local $TODO = "Changing sessions is broken and I've had no success fixing it. Patches welcome";
    $m->content_is( 'PASS' , 'session id changed' );
}
BEGIN { $tests += 4; }
