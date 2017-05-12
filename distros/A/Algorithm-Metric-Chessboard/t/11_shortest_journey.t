use strict;
use Algorithm::Metric::Chessboard;
use Algorithm::Metric::Chessboard::Wormhole;
use Test::More tests => 4;

my @wormholes = (
    Algorithm::Metric::Chessboard::Wormhole->new( x => 3, y => 9, id => "a" ),
    Algorithm::Metric::Chessboard::Wormhole->new( x => 40, y => 70, id => "b"),
);

my $grid = Algorithm::Metric::Chessboard->new(
                                               x_range   => [ 0, 99 ],
                                               y_range   => [ 0, 99 ],
                                               wormholes => \@wormholes,
                                             );

my $journey = $grid->shortest_journey(
                                       start    => [ 3, 10 ],
                                       end      => [ 45, 78 ],
                                     );
isa_ok( $journey, "Algorithm::Metric::Chessboard::Journey" );
is( $journey->distance, 9, "right distance" );
my @via = $journey->via;
@via = sort map { $_->id } @via;
is_deeply( \@via, [ "a", "b" ], "right via" );

$grid = Algorithm::Metric::Chessboard->new(
                                            x_range       => [ 0, 99 ],
                                            y_range       => [ 0, 99 ],
                                            wormholes     => \@wormholes,
                                            wormhole_cost => 3,
                                          );
$journey = $grid->shortest_journey(
                                    start    => [ 3, 10 ],
                                    end      => [ 45, 78 ],
                                  );
is( $journey->distance, 12, "right distance with wormhole cost" );
