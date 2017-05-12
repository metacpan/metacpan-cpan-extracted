#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Test::WWW::Mechanize;
use CGI::Application::Server;

{
    package TestServer;
    use base qw/
        Test::HTTP::Server::Simple
        CGI::Application::Server
    /;
}

my $port = $ENV{CGI_APP_SERVER_TEST_PORT} || 40000 + int(rand(10000));

my $server = TestServer->new($port);
$server->entry_points({
    '/static'         => 't/htdocs',
    '/images'         => 't/htdocs',
});
my $url_root = $server->started_ok("start up my web server");

my $mech = Test::WWW::Mechanize->new();

$mech->get_ok($url_root . '/static/index.html', '...got /static/index.html');
$mech->title_is('White Noise!', '... got the right page title w/ static page');

$mech->get_ok($url_root . '/images/index.html', '...got /images/index.html');
$mech->title_is('1000 Words!', '... got the right page title w/ images page');

