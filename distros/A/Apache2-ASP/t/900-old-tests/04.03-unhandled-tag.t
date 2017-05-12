#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';

ok( my $s = __PACKAGE__->SUPER::new() );

my $res = eval {
  $s->ua->get("/coverage/unhandled-tag.asp");
};


#{
#  $^W = 0;
#  like $res->content, qr@Unhandled tag 'unknown\:tag' in '/coverage/unhandled-tag.asp'@;
#}

