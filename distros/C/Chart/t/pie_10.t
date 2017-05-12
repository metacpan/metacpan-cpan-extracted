#!/usr/bin/perl -w

use Chart::Pie;
use strict;

print "1..1\n";

my $g = Chart::Pie->new( 1000, 1000 );
my @labels = (
    'Pending - 0 - 0.5 hour',
    'Pending - 0.5 - 1 hour',
    'Pending - 1 - 2 hours',
    'Pending - 2 - 5 hours',
    'Pending - 5 - 12 hours',
    'Pending - 12 - 24 hours',
    'Pending - 1 - 2 days',
    'Pending - more than 2 days',
    'Queued  - 0 - 0.5 hour',
    'Queued  - 0.5 - 1 hour',
    'Queued  - 1 - 2 hours',
    'Queued  - 2 - 5 hours',
    'Queued  - 5 - 12 hours',
    'Queued  - 12 - 24 hours',
    'Queued  - 1 - 2 days',
    'Queued  - more than 2 days',
    'Queued  - Future Delivery'
);
$g->add_dataset(@labels);
$g->add_dataset( 40, 5, 12, 2, 4, 15, 20, 31, 1, 25, 40, 40, 40, 1, 0, 2, 20 );

$g->set( 'title'               => 'Pie Demo Chart' );
$g->set( 'label_values'        => 'percent' );
$g->set( 'legend_label_values' => 'value' );
$g->set( 'legend'              => 'right' );
$g->set( 'grey_background'     => 'false' );
$g->set( 'legend_lines'        => 'true' );

$g->png("samples/pie_10.png");
print "ok 1\n";

exit(0);

