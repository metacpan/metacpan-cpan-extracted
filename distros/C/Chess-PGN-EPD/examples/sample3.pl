#!/usr/bin/perl
# sample3.pl - an example of Chess::PGN::EPD usage...
#
use strict;
use warnings;
use diagnostics;
use Chess::PGN::Parse;
use Chess::PGN::EPD qw( epdlist epdcode );

if ( $ARGV[0] ) {
    my $pgn = new Chess::PGN::Parse( $ARGV[0] )
      or die "Can't open $ARGV[0]: $!\n";
    while ( $pgn->read_game() ) {
        my @epd;

        $pgn->parse_game();
        @epd = reverse epdlist( @{ $pgn->moves() } );
        print '[ECO,"',     epdcode( 'ECO',     \@epd ), "\"]\n";
        print '[NIC,"',     epdcode( 'NIC',     \@epd ), "\"]\n";
        print '[Opening,"', epdcode( 'Opening', \@epd ), "\"]\n";
    }
}
