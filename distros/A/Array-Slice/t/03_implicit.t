#! /usr/bin/perl
# $Id: 03_implicit.t,v 1.1.1.1 2007/04/11 15:15:54 dk Exp $

use strict;
use warnings;

use Test::More tests => 4;

use Array::Slice qw(:all);

my @a = 1..8;
my ( $x, $y, $z) = slice @a;
ok( $x == 1 && $y == 2 && $z == 3, 'all defined');

my ( $w, undef, $t) = slice @a;
ok( $w == 4 && $t == 6, 'not all defined');

( $x, $y, $z) = slice @a;
ok( $x == 7 && $y == 8 && not(defined $z), 'end not defined');

( $x, $y, $z) = slice @a;
ok( not(defined $x) && not(defined $y) && not(defined $z), 'read past end');
