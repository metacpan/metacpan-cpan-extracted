#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

ok( my $api = ASP4::API->new, 'got api' );


$::cleanup_called = 0;
ok( $api->ua->get('/register-cleanup.asp') );

ok( $::cleanup_called, "Cleanup handler was called" );


