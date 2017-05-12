#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::API;
my $api; BEGIN { $api = Apache2::ASP::API->new }

ok( $api, 'got an API object' );
isa_ok( $api, 'Apache2::ASP::API' );

can_ok( $api, 'context' );
can_ok( $api, 'config' );

ok(
  my $context = $api->context,
  '$api->context'
);
isa_ok( $context, 'Apache2::ASP::HTTPContext' );
ok(
  my $config = $api->config,
  '$api->config'
);
isa_ok( $config, 'Apache2::ASP::Config' );

