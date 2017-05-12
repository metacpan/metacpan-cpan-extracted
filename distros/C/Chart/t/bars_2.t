#!/usr/bin/perl -w

use Chart::Bars;

print "1..1\n";

$g = Chart::Bars->new( 600, 500 );

$g->add_dataset( 'Berlin', 'Paris', 'Rome', 'London', 'Munich' );
$g->add_dataset( 14,       5,       4,      5,        11 );
$g->add_dataset( 12,       4,       6,      7,        12 );
$g->add_dataset( 18,       2,       3,      3,        9 );
$g->add_dataset( 17,       5,       7,      6,        6 );
$g->add_dataset( 15,       3,       4,      5,        11 );
$g->add_dataset( 11,       6,       5,      6,        12 );
$g->add_dataset( 12,       1,       4,      5,        15 );
$g->add_dataset( 10,       4,       6,      8,        10 );
$g->add_dataset( 14,       5,       4,      5,        11 );
$g->add_dataset( 12,       4,       6,      6,        12 );
$g->add_dataset( 18,       2,       3,      3,        9 );
$g->add_dataset( 17,       5,       7,      2,        6 );

%hash = (
    'title'         => 'Sold Cars in 2001',
    'x_label'       => 'City',
    'y_label'       => 'Number of Cars',
    'legend'        => 'bottom',
    'legend_labels' => [
        'January', 'February', 'March',     'April',   'May',      'June',
        'July',    'August',   'September', 'October', 'November', 'December'
    ],
    'grid_lines'   => 'true',
    'include_zero' => 'true',
    'max_val'      => '20',
    'colors'       => {
        'title'      => 'red',
        'x_label'    => 'blue',
        'y_label'    => 'blue',
        'background' => 'grey',
        'text'       => 'blue',
    },

);

$g->set(%hash);

$g->png("samples/bars_2.png");

print "ok 1\n";

exit(0);

