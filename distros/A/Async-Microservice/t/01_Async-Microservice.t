#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::Most;
use Test::WWW::Mechanize;

use FindBin qw($Bin);
use Path::Class qw(file);
use lib file($Bin, 'tlib')->stringify;

use_ok('Async::Microservice::HelloWorld')     or die;
use_ok('Test::Async::Microservice::HelloWorld') or die;

my $asmi_time_srv = Test::Async::Microservice::HelloWorld->start;
my $service_url   = $asmi_time_srv->url;
my $mech          = Test::WWW::Mechanize->new();

subtest '/hcheck' => sub {
    $mech->get_ok($service_url . 'hcheck', 'get hcheck')
        or diag($mech->content);
    $mech->content_like(qr/API-Version:/, 'hcheck content')
        or diag($mech->content);
};

subtest '/static' => sub {
    $mech->get_ok($service_url . 'static/async-microservice-time_openapi.yaml',
        'get OpenAPI config');
};

subtest 'OpenAPI' => sub {
    $mech->get_ok($service_url);
    $mech->content_contains('<div id="swagger-ui">', 'OpenAPI documentation in /');
    $mech->get_ok($service_url.'edit');
    $mech->content_contains('<div id="swagger-editor">', 'OpenAPI editor in /edit');
};

done_testing();
