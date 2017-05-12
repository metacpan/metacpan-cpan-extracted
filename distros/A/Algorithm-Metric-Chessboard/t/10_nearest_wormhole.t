use strict;
use Algorithm::Metric::Chessboard;
use Algorithm::Metric::Chessboard::Wormhole;
use Test::More tests => 2;

my @wormholes = (
    Algorithm::Metric::Chessboard::Wormhole->new( x => 5, y => 30, id => 1 ),
    Algorithm::Metric::Chessboard::Wormhole->new( x => 98, y => 99, id => 2 ),
);

my $grid = Algorithm::Metric::Chessboard->new(
                                   x_range   => [ 0, 99 ],
                                   y_range   => [ 0, 99 ],
                                   wormholes => \@wormholes,
                                               );

my $wormhole = $grid->nearest_wormhole( x => 26, y => 53 );

isa_ok( $wormhole, "Algorithm::Metric::Chessboard::Wormhole" );
is( $wormhole->id, 1, "the right wormhole" );
