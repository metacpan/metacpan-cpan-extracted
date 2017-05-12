#!/usr/bin/perl -w

use Chart::HorizontalBars;

print "1..1\n";

$g = Chart::HorizontalBars->new( 600, 500 );

$g->add_dataset(
    'January', 'February', 'March',     'April',   'May',      'June',
    'July',    'August',   'September', 'October', 'November', 'December'
);
$g->add_dataset( 14, 12, 18, 17, 15, 11, 12, 10, 14, 12, 18, 17 );
$g->add_dataset( 11, 13, 14, 15, 11, 10, 9,  8,  11, 13, 11, 12 );
$g->add_dataset( 4,  8,  7,  4,  5,  4,  6,  4,  6,  10, 7,  4 );
$g->add_dataset( 5,  7,  6,  5,  6,  6,  7,  8,  6,  9,  8,  7 );
$g->add_dataset( 5,  4,  2,  5,  3,  6,  1,  4,  5,  4,  2,  5 );

%hash = (
    'y_axes'             => 'both',
    'title'              => 'Sold Cars in 2001',
    'integer_ticks_only' => 'true',
    'legend'             => 'bottom',
    'y_label'            => 'month',
    'y_label2'           => 'month',
    'x_label'            => 'number of cars',
    'legend_labels'      => [ 'Berlin', 'Munich', 'Rome', 'London', 'Paris' ],
    'min_val'            => 0,
    'max_val'            => 20,
    'grid_lines'         => 'true',
    'colors'             => {
        'title'    => 'red',
        'x_label'  => 'blue',
        'y_label'  => 'blue',
        'y_label2' => 'blue',
        'dataset4' => 'yellow'
    },
);

$g->set(%hash);

$g->png("samples/hbars_1.png");

print "ok 1\n";

exit(0);
