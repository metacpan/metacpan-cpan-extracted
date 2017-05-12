#!/usr/bin/perl -w

use strict;
use warnings 'all';
use ASP4::API;
use Test::More tests => 5;
my $api; BEGIN { $api = ASP4::API->new }

ok( $api, "Got api");

my $res = $api->ua->get("/seo/123/");

ok( $res->is_success, "request is successful" );

is( $res->content => 'Hello - SEO
', "Got the content we were expecting");

$res = $api->ua->get("/seo2/abc/");

ok( $res->is_success, "/seo2/abc/ was successful" );
is(
  $res->content => 'SEO Handler - OK!', "Got the correct content"
);




