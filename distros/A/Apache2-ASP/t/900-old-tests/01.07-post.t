#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Apache2::ASP::Test::UserAgent');
use_ok('Apache2::ASP::ConfigLoader');


my $ua = Apache2::ASP::Test::UserAgent->new(
  config => Apache2::ASP::ConfigLoader->load(),
);

my $res = $ua->post('/index.asp', [ somevar => 'someval' ]);
#warn $res->content;



