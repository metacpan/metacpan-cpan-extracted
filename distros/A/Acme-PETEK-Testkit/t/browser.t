#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Test::WWW::Mechanize;

use Apache::TestRequest;
my $url = Apache::TestRequest::module2url('/count');

my $m = Test::WWW::Mechanize->new;
$m->get_ok($url,undef,'load counter page');
cmp_ok($m->value('cur'),'==',0,'value starts at zero');
$m->click('incr1');
ok($m->success,'clicked incr1');
cmp_ok($m->value('cur'),'==',1,'value increased to 1');
