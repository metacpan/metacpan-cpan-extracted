#!/usr/bin/perl -w

use Chart::Bars;
use strict;

print "1..1\n";

my ( @data, @labels, %hash, $g, $hits );

# create an array of labels
for ( 1 .. 49 )
{
    push( @labels, $_ );
}

# create an array of data
for ( 1 .. 49 )
{
    srand( time() / $_ );
    $hits = int( rand(100) + 401 );
    push( @data, $hits );
}

$g = Chart::Bars->new( 700, 300 );
$g->add_dataset(@labels);
$g->add_dataset(@data);

%hash = (
    'legend'       => 'none',
    'precision'    => 0,
    'x_ticks'      => 'vertical',
    'title'        => 'Lottozahlenverteilung',
    'y_label'      => 'Häufigkeit',
    'y_grid_lines' => 'true',

);

$g->set(%hash);
$g->png("samples/bars_5.png");
print "ok 1\n";

exit(0);

