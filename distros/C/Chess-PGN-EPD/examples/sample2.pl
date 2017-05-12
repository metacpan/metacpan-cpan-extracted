#!/usr/bin/perl
# sample2.pl - an example of Chess::PGN::EPD usage...
#
use warnings;
use strict;
use Chess::PGN::EPD qw( epdstr );

my $position = 'rnbqkb1r/ppp1pppp/5n2/3P4/8/8/PPPP1PPP/RNBQKBNR w KQkq -';
print join( "\n", epdstr( epd => $position, type => 'latex' ) );
