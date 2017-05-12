#!/usr/bin/perl -w

use Chart::Pie;
use strict;
my $g;

print "1..1\n";

$g = Chart::Pie->new( 530, 330 );

$g->add_dataset( 'Harry', 'Sally', 'Eve', 'Mark', 'John', 'Susan', 'Alex', 'Tony', 'Kimberly', 'Theresa' );
$g->add_dataset( 12,      20,      12,    15,     8,      9,       22,     14,     8,          13 );

$g->set( 'title'               => 'Pie Demo' );
$g->set( 'label_values'        => 'none' );
$g->set( 'legend_label_values' => 'percent' );
$g->set( 'grey_background'     => 'false' );
$g->set( 'colors'              => { 'title' => 'red' } );
$g->set( 'legend_lines'        => 'true' );

$g->png("samples/pie_2.png");
print "ok 1\n";

exit(0);

