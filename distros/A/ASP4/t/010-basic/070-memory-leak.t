#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;
use Test::Memory::Cycle;

my $api; BEGIN { $api = ASP4::API->new }
ok( $api, 'Got an API' );

$api->ua->get("/useragent/hello-world.asp");


for( 1...100 )
{
  $api->ua->get("/useragent/hello-world.asp");
  memory_cycle_ok( $api->context );
}# end for()


