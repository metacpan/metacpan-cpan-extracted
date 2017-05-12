#! /usr/bin/perl
# $Id: 06_tied.t,v 1.1.1.1 2007/04/11 15:15:54 dk Exp $

use strict;
use warnings;

use Test::More tests => 4;

use Array::Slice qw(:all);

package A;

my @b = 1..8;

sub FETCH	{ $b[$_[1]] }
sub FETCHSIZE	{ 20 } 
sub TIEARRAY	{ bless {}, $_[0] } 

package main;

my @a;
tie @a, 'A';

my ( $x, $y, $z) = slice @a;
ok( $x == 1 && $y == 2 && $z == 3, 'all defined');

reset @a;
( $x, $y, $z) = slice @a;
ok( $x == 1 && $y == 2 && $z == 3, 'reset');

my ( $w, undef, $t) = slice @a;
ok( $w == 4 && $t == 6, 'not all defined');

( $x, $y, $z) = slice @a;
ok( $x == 7 && $y == 8 && not(defined $z), 'end not defined');

