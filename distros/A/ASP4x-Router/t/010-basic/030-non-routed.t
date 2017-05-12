#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

ok(
  my $res = $api->ua->get("/no-routing/"),
  "Got /no-routing/"
);
is( $res->content => "NOT ROUTED
", "/no-routing/ was not routed" );

ok(
  $res = $api->ua->get("/no-routing/index.asp"),
  "Got /no-routing/index.asp"
);
is( $res->content => "NOT ROUTED
", "/no-routing/index.asp was not routed" );

ok(
  $res = $api->ua->get("/no-routing/another.asp"),
  "Got /no-routing/another.asp"
);
is( $res->content => "ANOTHER NOT ROUTED
", "/no-routing/another.asp was not routed" );


# Create handler:
$res = $api->ua->post("/main/boat/create/");
is( $res->content => "Non-Routed Boat Create Handler", "POST '/main/boat/create/' correct");

