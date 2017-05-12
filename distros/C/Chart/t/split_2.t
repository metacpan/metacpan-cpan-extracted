#!/usr/bin/perl -w

use Chart::Split;
print "1..1\n";

$g = Chart::Split->new( 500, 500 );
$last = 0;

# create arrays of data
for ( 1 .. 4000 )
{
    srand( time() / $_ * 50 );    #intialize the random number generator
    $y1 = ( rand(10) );           #generate the number
    push( @x,  $_ );                    #add the x-values
    push( @y1, $y1 );                   #add the random number
    push( @y2, abs( $y1 - $last ) );    #add the difference to the last number
    $last = $y1;
}

$g->add_dataset(@x);
$g->add_dataset(@y1);
$g->add_dataset(@y2);

%options = (
    'start'          => 0,
    'interval'       => 400,
    'brush_size'     => 1,
    'interval_ticks' => 0,
    'title'          => "Random Numbers Test",
    'legend_labels'  => [ 'random numbers', 'difference' ],
    'x_label'        => "4000 Random Numbers",
    'legend'         => 'bottom',
);
$g->set(%options);
$g->png("samples/split_2.png");
print "ok 1\n";

exit(0);
