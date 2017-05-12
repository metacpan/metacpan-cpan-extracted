#!/usr/bin/perl -w

use Chart::Composite;

print "1..1\n";

$g = Chart::Composite->new();

$g->add_dataset( 'foo', 'bar', 'junk', 'whee' );
$g->add_dataset( 3,     4,     9,      10 );
$g->add_dataset( 8,     6,     1,      11 );
$g->add_dataset( 5,     7,     2,      12 );
$g->add_dataset( 2,     5,     7,      2 );

$g->set( 'legend' => 'left' );
$g->set(
    'title'          => 'Composite Chart',
    'composite_info' => [ [ 'Bars', [ 1, 2 ] ], [ 'LinesPoints', [ 3, 4 ] ] ]
);

$g->set( 'y_label' => 'y label 1', 'y_label2' => 'y label 2' );
$g->set(
    'colors' => {
        'y_label'   => [ 0,   0,   255 ],
        y_label2    => [ 0,   255, 0 ],
        'dataset0'  => [ 0,   127, 0 ],
        'dataset1'  => [ 0,   0,   127 ],
        'dataset8', => [ 0,   255, 0 ],
        'dataset9'  => [ 255, 0,   0 ]
    }
);
$g->set( 'brush_size2' => 1 );
$g->png("samples/composite.png");

print "ok 1\n";

exit(0);

