#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

use Color::Model::RGB qw(:all);

note("--- Bitwide Operator overload\n");
set_format('%02x%02x%02x',1);

my $col1 = W;
my $col2 = $col1 - rgb(0.5,0.5,0.5);
my $col3 = -$col2;
my $col4 = $col2 * 1.5; # 808080 * 1.5
my $col5 = $col4 / 3;

my $col6 = $col1 & $col2;
ok($col6->hexstr() eq '808080',          "bitwise AND with objects ($col6)");
ok(($col6 & 0x70)->hexstr() eq '000000', "bitwise AND with scalar ($col6)");

my $col7 = $col6 | $col5;
ok($col7->hexstr() eq 'c0c0c0',          "bitwise OR with objects ($col7)");
ok(($col7 | 0x0f)->hexstr() eq 'cfcfcf', "bitwise OR with scalar ($col7)");

my $col8 = $col7 ^ $col1;
ok($col8->hexstr() eq '3f3f3f',           "bitwise XOR with objects ($col8)");
ok(($col8 ^ 0xf3 )->hexstr() eq 'cccccc', "bitwise XOR with scalar ($col8)");

my $col9 = ~$col8;
ok($col9->hexstr() eq 'c0c0c0', "bitwise NOT (~$col8 -> $col9)");

my $col10 = $col9 >> 2;
ok($col10->hexstr() eq '303030', "bit rotate ($col10)");

my $col11 = $col10 << 1;
ok($col11->hexstr() eq '606060', "bit shift ($col11)");


my $col12 = $col11 << 2;
ok($col12->hexstr() eq 'ffffff', "bit shift ($col12)");

$Color::Model::RGB::BIT_SHIFT_RIGID = 1;

my $col13 = $col11 << 2;
ok($col13->hexstr() eq '808080', "bit shift ($col13)");


