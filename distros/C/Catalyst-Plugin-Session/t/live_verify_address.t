#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval {
        require Test::WWW::Mechanize::PSGI;
        #Test::WWW::Mechanize::Catalyst->VERSION(0.51);
    }
    or plan skip_all =>
        'Test::WWW::Mechanize::PSGI is required for this test';

    eval { require Catalyst::Plugin::Authentication; 1 }
      or plan skip_all => "Catalyst::Plugin::Authentication is required for this test";

    plan tests => 12;
}

use lib "t/lib";
use Test::WWW::Mechanize::PSGI;
use SessionTestApp;
my $ua = Test::WWW::Mechanize::PSGI->new(
  app => SessionTestApp->psgi_app(@_),
  cookie_jar => {}
);

# Test without delete __address
local $ENV{REMOTE_ADDR} = "192.168.1.1";

$ua->get_ok( "http://localhost/login" );
$ua->content_contains('logged in');

$ua->get_ok( "http://localhost/set_session_variable/logged/in" );
$ua->content_contains('session variable set');


# Change Client
use Plack::Builder;
my $app = SessionTestApp->psgi_app(@_);
my $ua2 = Test::WWW::Mechanize::PSGI->new(
    app => $app,
    cookie_jar => {}
);
$ua2->get_ok( "http://localhost/get_session_variable/logged");
$ua2->content_contains('VAR_logged=n.a.');

# Inital Client
local $ENV{REMOTE_ADDR} = "192.168.1.1";

$ua->get_ok( "http://localhost/login_without_address" );
$ua->content_contains('logged in (without address)');

$ua->get_ok( "http://localhost/set_session_variable/logged/in" );
$ua->content_contains('session variable set');

# Change Client
local $ENV{REMOTE_ADDR} = "192.168.1.2";

$ua->get_ok( "http://localhost/get_session_variable/logged" );
$ua->content_contains('VAR_logged=in');



