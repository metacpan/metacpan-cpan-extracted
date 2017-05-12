#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';

my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get('/page-using-nested-masterpage.asp');
ok( $res->is_success );

unlike $res->content, qr/<asp:(PlaceHolder|PlaceHolderContent)/;

like $res->content, qr/\<h1\>\s+This is inside the nested placeholder\!\s+\<\/h1\>/s;

