use strict;
use Algorithm::Metric::Chessboard::Journey;
use Algorithm::Metric::Chessboard::Wormhole;
use Test::More tests => 1;

my $wormhole_a =
    Algorithm::Metric::Chessboard::Wormhole->new( x => 3, y => 9 );
my $wormhole_b =
    Algorithm::Metric::Chessboard::Wormhole->new( x => 40, y => 70 );
my $journey =
    Algorithm::Metric::Chessboard::Journey->new(
        start    => [ 3, 10 ],
        end      => [ 45, 78 ],
        via      => [ $wormhole_a, $wormhole_b ],
        distance => 10,
                                                );
isa_ok( $journey, "Algorithm::Metric::Chessboard::Journey" );
