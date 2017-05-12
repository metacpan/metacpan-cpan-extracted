#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestAppRel" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get basic template, no Metadata
$mech->get_ok('/autocrud/helloworld', 'Get Hello World page');
is($mech->ct, 'text/html', 'Hello World page content type');
$mech->content_contains('Hello, World!', 'Hello World page content');

$mech->content_contains('http://extjs.cachefly.net/',
    "pages are using the ExtJS CacheFly links");

# mimic that the webserver is running behind a reverse proxy that proxies from
# HTTPS to HTTP
$mech->default_header('X-Forwarded-For' => '127.0.0.1');
$mech->default_header('X-Forwarded-Host' => 'localhost');
$mech->default_header('X-Forwarded-Port' => 443);

# get basic template, no Metadata
$mech->get_ok('/autocrud/helloworld', 'Get Hello World page (HTTPS)');
is($mech->ct, 'text/html', 'Hello World page content type (HTTPS)');
$mech->content_contains('Hello, World!', 'Hello World page content (HTTPS)');

$mech->content_contains('https://extjs.cachefly.net/',
    "pages are using the ExtJS CacheFly links (HTTPS)");

# warn $mech->content;
__END__
