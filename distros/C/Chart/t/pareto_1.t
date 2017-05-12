#!/usr/bin/perl -w

use Chart::Pareto;

print "1..1\n";

$g = Chart::Pareto->new( 450, 400 );
$g->add_dataset( 'Mo', 'Tue', 'We', 'Th', 'Fr', 'Sa', 'Su' );
$g->add_dataset( 2500, 1000,  250,  700,  100,  610,  20 );

%hash = (
    'colors' => {
        'dataset0'     => 'green',
        'dataset1'     => 'red',
        'x_label'      => 'red',
        'y_grid_lines' => 'white',
        'title'        => 'blue',
    },
    'title'              => 'Sold Tickets for Beethovens 9th\n ',
    'integer_ticks_only' => 'true',
    'skip_int_ticks'     => 250,
    'sort'               => 'true',
    'max_val'            => 5500,
    'y_grid_lines'       => 'true',
    'y_label'            => 'Sold Tickets',
    'x_label'            => '! sold out in the first week !',
    'spaced_bars'        => 'false',

    'legend' => 'none',
);

$g->set(%hash);
$g->png("samples/pareto_1.png");

print "ok 1\n";

exit(0);

