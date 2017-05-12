#!/usr/bin/perl
# sample1.pl - an example of Chess::PGN::EPD usage...
#
use warnings;
use strict;
use Chess::PGN::Parse;
use Chess::PGN::EPD qw( epdlist );

if ( $ARGV[0] ) {
    my $pgn = new Chess::PGN::Parse( $ARGV[0] )
      or die "Can't open $ARGV[0]: $!\n";
    while ( $pgn->read_game() ) {
        $pgn->parse_game();
        print join( "\n", epdlist( @{ $pgn->moves() } ) ), "\n\n";
    }
}
