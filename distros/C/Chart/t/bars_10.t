#!/usr/bin/perl -w

use Chart::Bars;

print "1..1\n";

$g = Chart::Bars->new( 600, 500 );

$g->add_dataset( 'Berlin', 'Paris', 'Rome', 'London', 'Munich' );

$g->add_dataset( 0, 0, 0, 0, 0 );
$g->add_dataset( 0, 0, 0, 0, 0 );
$g->add_dataset( 0, 0, 0, 0, 0 );
$g->add_dataset( 0, 0, 0, 0, 0 );
$g->add_dataset( 0, 0, 0, 0, 0 );
$g->add_dataset( 0, 0, 0, 0, 0 );
$g->add_dataset( 0, 0, 0, 0, 0 );

%hash = (
    'title'        => 'Only a demo chart with zero data',
    'legend'       => 'bottom',
    'grid_lines'   => 'true',
    'include_zero' => 'true',
    'max_val'      => '20',
    'min_val'      => '-20',
    'colors'       => {
        'title'      => 'red',
        'x_label'    => 'blue',
        'y_label'    => 'blue',
        'background' => 'grey',
        'text'       => 'blue',
    },

);

$g->set(%hash);

$g->png("samples/bars_10.png");

print "ok 1\n";

exit(0);

