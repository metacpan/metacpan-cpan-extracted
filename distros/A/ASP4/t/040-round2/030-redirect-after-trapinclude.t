#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

ok( my $api = ASP4::API->new, 'got api' );

my $res = $api->ua->get('/handlers/dev.redirect_after_trapinclude');

ok $res->header('location'), "got res.header.location";


