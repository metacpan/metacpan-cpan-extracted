#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';

ok( my $s = __PACKAGE__->SUPER::new() );

my $res1 = eval { $s->ua->get("/") };
my $res2 = $s->ua->get("/index.asp");

is( $res1->content => $res2->content );

my $res3 = $s->ua->get("/cleanup-register.asp");
is( $ENV{CALLED_REGISTER_CLEANUP} => 1 );


