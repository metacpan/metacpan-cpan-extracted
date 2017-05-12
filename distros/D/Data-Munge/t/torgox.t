#!perl
use warnings;
use strict;

use Test::More tests => 8;

use Data::Munge qw(list2re replace);

my $orig = '[acabbdcacab]';

my $re1 = list2re 'a', 'b';
my $good1 = '[XYcXYXYXYdcXYcXYXY]';
is replace($orig, $re1, 'XY', 'g'), $good1;
$_ = $orig;
s/$re1/XY/g;
is $_, $good1;

my $re2 = list2re 'a';
my $good2 = '[XYcXYbbdcXYcXYb]';
is replace($orig, $re2, 'XY', 'g'), $good2;
$_ = $orig;
s/$re2/XY/g;
is $_, $good2;

my $re3 = list2re;
my $good3 = $orig;
is replace($orig, $re3, 'XY', 'g'), $good3;
$_ = $orig;
s/$re3/XY/g;
is $_, $good3;

my $re4 = list2re '';
my $good4 = 'XY[XYaXYcXYaXYbXYbXYdXYcXYaXYcXYaXYbXY]XY';
is replace($orig, $re4, 'XY', 'g'), $good4;
$_ = $orig;
s/$re4/XY/g;
is $_, $good4;
