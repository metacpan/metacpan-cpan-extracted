#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';

my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get("/masters/main.asp");
ok( $res->is_success );


$res = $s->ua->get("/index.asp");
ok( $res->is_success );


