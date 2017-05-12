#!/usr/bin/perl -w
use strict;

use lib qw( ./lib/ );
use Acme::Yoda;
use Test::More tests => 16;


ok(my $yoda = Acme::Yoda->new(),           'Create Yoda object');
isa_ok($yoda,'Acme::Yoda',                 '... object ');
my $sentence   = 'I am ok';
my $translated = 'Ok I am';
ok(my $rtn = $yoda->yoda($sentence),       '... translate');
is($rtn,$translated,                       '... does translation match');
ok(my $back = $yoda->deyoda($rtn),         '... translate back');
is($back,$sentence,                        '... does the de-translation match');
$sentence   = 'Can I get a what-what';
$translated = 'I get a what-what?';
ok($rtn = $yoda->yoda($sentence),       '... translate question');
is($rtn,$translated,                       '... does translation match');
ok($back = $yoda->deyoda($rtn),         '... translate back');
is($back,$sentence,                        '... does the de-translation match');
$sentence   = 'I am your father';
$translated = 'Your father I am';
ok(my $yoda_2 = Acme::Yoda->new(sentence => $sentence),           
                                           'Create Yoda object with args');
isa_ok($yoda_2,'Acme::Yoda',               '... object ');
ok(my $rtn_2 = $yoda_2->yoda(),            '... translate');
is($rtn_2,$translated,                     '... does translation match');
ok(my $back_2 = $yoda_2->deyoda($rtn_2),     '... translate back');
is($back_2,$sentence,                      '... does the de-translation match');


