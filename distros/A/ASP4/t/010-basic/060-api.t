#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }
ok( $api, 'got api' );

like
  $api->ua->get('/useragent/hello-world.asp')->content, qr/Hello, World\!/,
  "ua.get(...) works"
;


is $api->ua->get('/handlers/dev.simple')->content => q(Hello from 'dev::simple'),
  'GET /handlers/dev.simple works';

