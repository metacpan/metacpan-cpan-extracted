#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Memory::Cycle;

use_ok('Apache2::ASP::Test::UserAgent');
use_ok('Apache2::ASP::ConfigLoader');


my $ua = Apache2::ASP::Test::UserAgent->new(
  config => Apache2::ASP::ConfigLoader->load(),
);

for( 1...10 )
{
  my $res = $ua->get('/index.asp?somevar=someval');
  ok( $res->content );
}


memory_cycle_ok( $ua->{context} );


