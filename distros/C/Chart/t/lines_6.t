#!/usr/bin/perl -w

use Chart::Lines;
print "1..1\n";

$g = Chart::Lines->new();
$g->add_dataset( 'foo', 'bar', 'junk', 'ding', 'bat' );
$g->add_dataset( -4,    3,     -4,     -5,     -2 );
$g->add_dataset( 2,     10,    -3,     8,      3 );
$g->add_dataset( -10,   2,     4,      -3,     -3 );
$g->add_dataset( 7,     -5,    -3,     4,      7 );

%hash = (
    'legend_labels'       => [ '1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter' ],
    'y_axes'              => 'both',
    'title'               => 'Lines Demo',
    'grid_lines'          => 'true',
    'grid_lines'          => 'true',
    'legend'              => 'left',
    'legend_example_size' => 20,
    'colors'              => {
        'text'       => 'blue',
        'misc'       => 'blue',
        'background' => 'grey',
        'grid_lines' => 'light_blue',
        'dataset0'   => [ 220, 0, 0 ],
        'dataset1'   => [ 200, 0, 100 ],
        'dataset2'   => [ 150, 50, 175 ],
        'dataset3'   => [ 170, 0, 255 ],
    },
);

$g->set(%hash);

$g->png("samples/lines_6.png");

print "ok 1\n";

exit(0);

