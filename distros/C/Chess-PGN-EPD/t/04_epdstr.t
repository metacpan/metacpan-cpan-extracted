#!/usr/bin/perl
# 04_epdstr.t - test epdstr
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::EPD qw ( epdstr );
use Test::More tests => 2;

ok(1);    # load failure check...

my $position = 'rnbqkb1r/ppp1pppp/5n2/3P4/8/8/PPPP1PPP/RNBQKBNR w KQkq -';
my $result =
    "\\begin{diagram}\n"
  . "\\board\n"
  . "{rnbqkb r}\n"
  . "{ppp pppp}\n"
  . "{ * * n *}\n"
  . "{* *P* * }\n"
  . "{ * * * *}\n"
  . "{* * * * }\n"
  . "{PPPP PPP}\n"
  . "{RNBQKBNR}\n"
  . "\\end{diagram}";

is( join( "\n", epdstr( epd => $position, type => 'latex' ) ), $result, 'Check epdstr' );
