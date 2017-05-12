#!/usr/bin/perl -w

use Chart::StackedBars;

print "1..1\n";

$g = Chart::StackedBars->new( 600, 400 );
$g->add_dataset( 'foo', 'bar', 'junk', 'taco', 'kcufasidog' );
$g->add_dataset( 3,     4,     9,      10,     11 );
$g->add_dataset( 8,     6,     1,      12,     1 );
$g->add_dataset( 5,     7,     2,      13,     4 );

$g->set(
    'title'           => 'Stacked Bar Chart',
    'legend'          => 'left',
    'grey_background' => 'false',
);

$g->png("samples/stackedbars.png");

print "ok 1\n";

exit(0);
