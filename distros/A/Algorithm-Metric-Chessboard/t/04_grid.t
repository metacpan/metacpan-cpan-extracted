use strict;
use Algorithm::Metric::Chessboard;
use Algorithm::Metric::Chessboard::Wormhole;
use Test::More tests => 4;

my $grid = Algorithm::Metric::Chessboard->new(
                                   x_range   => [ 0, 99 ],
                                   y_range   => [ 0, 89 ],
                                             );
isa_ok( $grid, "Algorithm::Metric::Chessboard" );
is_deeply( $grid->x_range, [ 0, 99 ], "...x_range set correctly" );
is_deeply( $grid->y_range, [ 0, 89 ], "...y_range set correctly" );

my $wormhole =
    Algorithm::Metric::Chessboard::Wormhole->new(
                                                  x => 5,
                                                  y => 30,
                                                  id => "Warp Gate",
                                                );
$grid = Algorithm::Metric::Chessboard->new(
                                   x_range   => [ 0, 99 ],
                                   y_range   => [ 0, 99 ],
                                   wormholes => [ $wormhole ],
                                          );
isa_ok( $grid, "Algorithm::Metric::Chessboard" );
