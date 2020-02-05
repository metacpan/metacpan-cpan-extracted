#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::Peek qw( DGrow DDump );

my $x = "";
is (length ($x), 0,		"Initial length = 0");
my %dd = DDump $x;
ok ($dd{LEN} <= 16);
my $len = 10240;
ok (my $l = DGrow ($x, $len),	"Set to $len");
is (length ($x), 0,		"Variable content");
ok ($l >= $len,			"returned LEN >= $len");
my $limit = 4 * $len;
ok ($l <= $limit,		"returned LEN <= $limit");
   %dd = DDump $x;
ok ($dd{LEN} >= $len,		"LEN in variable >= $len");
ok ($dd{LEN} <= $limit,		"LEN in variable <= limit");
ok ($l = DGrow (\$x, $limit),	"Set to $limit");
ok ($l >= $limit,		"LEN in variable >= $limit");
($len, $limit) = ($limit, 4 * $limit);
ok ($l <= $limit,		"LEN in variable <= $limit");
   %dd = DDump $x;
ok ($dd{LEN} >= $len,		"LEN in variable >= $len");
ok ($dd{LEN} <= $limit,		"LEN in variable <= $limit");
is (DGrow ($x, 20), $l,		"Don't shrink");

done_testing;

1;
