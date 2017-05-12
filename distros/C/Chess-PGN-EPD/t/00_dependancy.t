#!/usr/bin/perl
# 00_dependancy.t -- test for dependancies
use Test::More tests => 2;

BEGIN {
    require_ok Chess::PGN::Moves
        or BAIL_OUT "Can't load needed dependancy Chess::PGN::Moves";
    use_ok(Chess::PGN::EPD);
}
