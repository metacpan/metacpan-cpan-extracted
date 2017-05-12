#! /usr/bin/perl
# $Id: 04_reset.t,v 1.1.1.1 2007/04/11 15:15:54 dk Exp $

use strict;
use warnings;

use Test::More tests => 4;

use Array::Slice qw(:all);

my @a = 1..8;

my ( $x, $y, $z) = slice @a;
ok( $x == 1 && $y == 2 && $z == 3, 'all defined');

reset @a;
( $x, $y, $z) = slice @a;
ok( $x == 1 && $y == 2 && $z == 3, 'reset from start');

reset @a, 6;
( $x, $y, $z) = slice @a;
ok( $x == 7 && $y == 8 && not( defined $z), 'reset to past end');

reset @a, -2;
( $x, $y, $z) = slice @a;
ok( $x == 7 && $y == 8 && not( defined $z), 'reset to negative');
