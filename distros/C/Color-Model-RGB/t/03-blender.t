#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

use Color::Model::RGB qw(:all);

note("--- Blendings\n");
set_format('%02x%02x%02x',1);

my $W = R + G + B;

my $col1 = blend_half($W, O);
ok($col1->hexstr() eq '808080', "blend_half()");

my $col2 = blend_plus($col1,  R);
ok($col2->hexstr() eq 'ff8080', "blend_plus()");

my $col3 = blend_minus($W, G);
ok($col3->hexstr() eq 'ff00ff', "blend_minus()");

my $col4 = blend_alpha($W, 0.25, B, 0.75);
ok($col4->hexstr() eq '4040ff', "blend_alpha()");


