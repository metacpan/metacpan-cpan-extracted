#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::MedianSelect::XS qw(median);
use Test::More tests => 6;

my @nums = (21, 6, 2, 9, 5, 1, 14, 7, 12, 3, 19);
my @desc = (
    'list',
    'list reference',
    'list (algorithm "bubble")',
    'list reference (algorithm "bubble")',
    'list (algorithm "quick")',
    'list reference (algorithm "quick")'
);

is(median(@nums),                              7, $desc[0]);
is(median(\@nums),                             7, $desc[1]);
is(median(@nums,   { algorithm => 'bubble' }), 7, $desc[2]);
is(median(\@nums,  { algorithm => 'bubble' }), 7, $desc[3]);
is(median(@nums,   { algorithm => 'quick'  }), 7, $desc[4]);
is(median(\@nums,  { algorithm => 'quick'  }), 7, $desc[5]);
