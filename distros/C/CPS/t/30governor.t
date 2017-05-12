#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use CPS qw( gkwhile gkforeach );
use CPS::Governor::Simple;

my $gov = CPS::Governor::Simple->new;

my $count = 0;
gkwhile( $gov, sub { ++$count < 5 ? $_[0]->() : $_[1]->() }, sub {} );

is( $count, 5, '$count is 5 after gkwhile' );

$count = 0;
gkforeach( $gov, [ 1 .. 5 ], sub { ++$count; $_[1]->() }, sub {} );

is( $count, 5, '$count is 5 after gkforeach' );
