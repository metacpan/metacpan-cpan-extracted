#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
no warnings 'syntax';
use lib 'lib';
use Test::More tests => 10;

use Data::Alias;

sub refs { [map "".\$_, @_] }

@_ = ();

is alias(unshift @_), 0;
is alias(unshift @_, our $x), 1;
is_deeply &refs, refs($x);

is alias(unshift @_, our ($y, $z)), 3;
is_deeply &refs, refs($y, $z, $x);

is alias(unshift @_), 3;
is alias(unshift @_, $x), 4;
is_deeply &refs, refs($x, $y, $z, $x);

is alias(unshift @_, $y, $z), 6;
is_deeply &refs, refs($y, $z, $x, $y, $z, $x);

# vim: ft=perl
