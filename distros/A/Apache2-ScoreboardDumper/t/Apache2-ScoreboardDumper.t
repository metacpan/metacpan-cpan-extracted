#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Apache2::ScoreboardDumper' );
    can_ok( 'Apache2::ScoreboardDumper', ( qw( handler dump_scoreboard ) ) );
}


