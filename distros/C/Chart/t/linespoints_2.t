#!/usr/bin/perl -w

use Chart::LinesPoints;
use strict;

print "1..1\n";

my ( @data, @data2, @labels, %hash, $g, $hits );

# create an array of labels
for ( 0 .. 30 )
{
    push( @labels, $_ );
}

# create two arrays of data
for ( 0 .. 30 )
{

    #first array
    $hits = 2 * $_;
    if ( $_ % 2 == 0 )
    {
        $hits = $_;
    }
    push( @data, $hits );

    #second array
    $hits = 40 - $_ + 10 * cos($_);
    push( @data2, $hits );
}

$g = Chart::LinesPoints->new( 600, 300 );
$g->add_dataset(@labels);
$g->add_dataset(@data);
$g->add_dataset(@data2);

%hash = (
    'title'     => 'Lines with Points Demo',
    'y_axes'    => 'both',
    'legend'    => 'none',
    'precision' => 0,
    'xy_plot'   => 'true',
);

$g->set(%hash);
$g->png("samples/linespoints_2.png");
print "ok 1\n";

exit(0);

