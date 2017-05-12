#!/usr/bin/perl -w

use Chart::Pareto;

print "1..1\n";

$g = Chart::Pareto->new( 450, 400 );
$g->add_dataset( 'Mo', 'Tue', 'We', 'Th', 'Fr', 'Sa', 'Su' );
$g->add_dataset( 3000, 1600,  1500, 400,  100,  20,   5 );

%hash = (
    'colors' => {
        'dataset0'     => 'green',
        'dataset1'     => 'red',
        'x_label'      => 'red',
        'y_grid_lines' => 'white',
        'title'        => 'blue',
    },
    'title'              => 'Pareto Chart ',
    'integer_ticks_only' => 'true',
    'precision'          => 0,
    'skip_int_ticks'     => 400,
    'sort'               => 'true',

    # 'max_val' => 6800,
    'y_grid_lines' => 'true',
    'spaced_bars'  => 'false',

    'legend' => 'none',
);

$g->set(%hash);
$g->png("samples/pareto_3.png");

print "ok 1\n";

exit(0);

