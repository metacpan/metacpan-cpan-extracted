#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use lib grep { -d } qw(./lib ../lib ./t/lib);
use Test::Easy qw(deep_ok);

use Array::Sticky;

my @target;
tie @target, 'Array::Sticky', head => [2], body => [3..7], tail => [8..9];

# the head of the array is locked at [2]
unshift @target, 1;
deep_ok( \@target, [(2), (1, 3..7), (8..9)] ); # the parens are for visual grouping

# the tail is locked at [8, 9]
push @target, 10..12;
deep_ok( \@target, [(2), (1, 3..7, 10..12), (8..9)] );

# shifting leaves the head alone
my @shifted = map { shift(@target) } 0..2;
deep_ok( \@shifted, [1, 3, 4] );
deep_ok( \@target, [(2), (5..7, 10..12), (8..9)] );

# popping leaves the tail alone
my @popped = map { pop(@target) } 0..2;
deep_ok( \@popped, [12, 11, 10] );
deep_ok( \@target, [(2), (5..7), (8..9)] );

# splice acts only on the body too
splice @target, 0, 0, (3..4);
deep_ok( \@target, [(2), (3..7), (8..9)] );

# splice into the body
splice @target, 2, 0, 'a'..'f';
deep_ok( \@target, [(2), (3..4, 'a'..'f', 5..7), (8..9)] );

# splicing into the head actually goes into the body
splice @target, 0, 0, 'gallop-outlaying';
deep_ok( \@target, [(2), ('gallop-outlaying', 3..4, 'a'..'f', 5..7), (8..9)] );

# splicing into the tail goes into the body as well
splice @target, scalar @target, 0, 'MasterCard-pontificating';
deep_ok( \@target, [(2), ('gallop-outlaying', 3..4, 'a'..'f', 5..7, 'MasterCard-pontificating'), (8..9)] );
