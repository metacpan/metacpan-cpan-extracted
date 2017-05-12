#!/usr/bin/perl -w

use strict;
use Apache::Test qw(ok have_lwp plan);
use Apache::TestRequest qw(GET);

plan tests => 6;

my $r = GET '/count';
ok $r->is_success;
ok $r->content =~ /name="cur" value="(\d*)"/;
ok $1, 0, 'value starts at zero';
$r = GET '/count?incr1=%3E';
ok $r->is_success;
ok $r->content =~ /name="cur" value="(\d*)"/;
ok $1, 1, 'value increased to 1';
