use strict;
use Algorithm::Metric::Chessboard::Wormhole;
use Test::More tests => 1;

my $wormhole =
    Algorithm::Metric::Chessboard::Wormhole->new(
                                                  x => 5,
                                                  y => 30,
                                                  id => "Warp Gate",
                                                );
isa_ok( $wormhole, "Algorithm::Metric::Chessboard::Wormhole" );
