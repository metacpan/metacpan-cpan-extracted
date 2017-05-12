#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';

my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get("/include-at-end.asp");

like $res->content, qr/Main page content/;


