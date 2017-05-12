#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api = ASP4::API->new();


my $res = $api->ua->get("/include-missing.asp");

ok( $res->is_success, "res.is_success" );
like $res->content, qr/Before\s+After/, "res.content looks right";


