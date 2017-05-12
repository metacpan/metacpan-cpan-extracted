use Test::More tests => 16;
use strict;
use warnings;

use ANSI::Heatmap;

my $map = ANSI::Heatmap->new;
$map->set(0,0,1);
$map->set(1,1,1);

is_deeply( $map->data, [[1,0], [0,1]], 'set' );
is( $map->get(0,0), 1 );
is( $map->get(0,1), 0 );
is( $map->get(1,0), 0 );
is( $map->get(1,1), 1 );
is( $map->get(200,0), 0 );

is( $map->to_string, "\e[48;5;196m \e[0m\e[48;5;16m \e[0m\n\e[48;5;16m \e[0m\e[48;5;196m \e[0m\n" );
is( "$map", $map->to_string );

$map->inc(0,0);
is( $map->get(0,0), 2 );
is_deeply( $map->data, [[1,0], [0,0.5]], 'inc' );

$map->set(0,3,1);
is( $map->get(0,3), 1 );
is( $map->get(1,3), 0 );
is_deeply( $map->data, [[1,0], [0,.5], [0,0], [.5,0]], 'extend y' );

$map->set(3,0,1);
is( $map->get(3,0), 1 );
is( $map->get(3,1), 0 );
is_deeply( $map->data, [[1,0,0,.5], [0,.5,0,0], [0,0,0,0], [.5,0,0,0]], 'extend x' );

