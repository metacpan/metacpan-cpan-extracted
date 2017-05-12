#!/usr/bin/perl -w

use Chart::Bars;
print "1..1\n";
$g = Chart::Bars->new( 500, 500 );

$g->add_dataset( 'Reds', 'Blacks', 'Greens', 'Yellows', 'Browns', 'Others' );
$g->add_dataset( -2.4,   3.4,      1.9,      1.2,       -1.1,     -2.9 );

%hash = (
    'title'           => 'Selection 2002:\nWins and Losses in percent',
    'text_space'      => 5,
    'y_grid_lines'    => 'true',
    'grey_background' => 'false',
    'legend'          => 'none',
    'min_val'         => -4,
    'max_val'         => 4,
    'min_y_ticks'     => 10,
    'y_axes'          => 'both',
    'spaced_bars'     => 'false',
    'colors'          => {
        'background' => [ 230, 255, 230 ],
        'title'      => 'plum',
        'dataset0'   => 'mauve',
    },
);
$g->set(%hash);

$g->png("samples/bars_3.png");

print "ok 1\n";

exit(0);
