#!/usr/bin/perl -w

use Chart::Points;
use strict;

print "1..1\n";
my $g;

my @x;
my @y;

$x[0] = 0;
$y[0] = 0;
for ( my $i = 9 ; $i < 100 ; $i++ )
{
    $x[$i] = $i;
    $y[$i] = $i * 10;
}
$g = Chart::Points->new;
$g->add_dataset(@x);
$g->add_dataset(@y);

$g->set( 'title'        => 'Points Chart with 100 Points' );
$g->set( 'skip_x_ticks' => 10 );

#$g->set ('skip_int_ticks'=> 10);
$g->png("samples/points_100.png");

print "ok 1\n";

exit(0);

