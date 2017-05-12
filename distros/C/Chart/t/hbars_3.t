#!/usr/bin/perl -w

use Chart::HorizontalBars;

print "1..1\n";

$g = Chart::HorizontalBars->new( 500, 400 );
$g->add_dataset( 'Foo', 'bar', 'junk', 'ding', 'bat' );
$g->add_dataset( -4,    -3,    -4,     -5,     -2 );
$g->add_dataset( -2,    -10,   -3,     -8,     -3 );

%hash = (
    'y_axes'       => 'right',
    'title'        => 'Horizontal Bars Demo',
    'x_grid_lines' => 'true',
    'x_label'      => 'x-axis',
    'y_label'      => 'y-axis',
    'x_ticks'      => 'staggered',
    'include_zero' => 'true',
    'spaced_bars'  => 'false',
);

$g->set(%hash);

$g->png("samples/hbars_3.png");

print "ok 1\n";

exit(0);
