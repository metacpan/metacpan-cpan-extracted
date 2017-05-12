#!usr/bin/perl -w

use Chart::Composite;

print "1..1\n";

$g = Chart::Composite->new( 750, 600 );

$g->add_dataset( 1,   2,   3 );
$g->add_dataset( 10,  20,  30 );
$g->add_dataset( 15,  25,  32 );
$g->add_dataset( 7,   24,  23 );
$g->add_dataset( 0.1, 0.5, 0.9 );

$g->set(
    'title'          => 'Composite Chart Test 2',
    'composite_info' => [ [ 'Bars', [ 1, 2 ] ], [ 'LinesPoints', [ 3, 4 ] ] ],
    'include_zero'   => 'true',
);

$g->png("samples/composite_4.png");

print "ok 1\n";

exit(0);
