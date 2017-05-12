#!/usr/bin/perl -w
#
# Testprogram for lines
# Math expressions 1/x
#
#======================================================================

use strict;
use Chart::Lines;

print "1..1\n";

my @x_values  = ();    # x axis
my @y1_values = ();    # 1/x for x<0
my @y2_values = ();    # 1/x for x>0

my $graphic;
my $min_x = -5;
my $max_x = 5;
my $min_y = -10;
my $max_y = 10;

my $x;
my $y;

#------------------------------------------------------------------------------------
# Start
#------------------------------------------------------------------------------------

$x = $min_x;
for ( my $x_idx = 0 ; $x < $max_x ; $x_idx++ )
{
    $x = $min_x + $x_idx * 0.1;
    $x_values[$x_idx] = $x;
}

for ( my $x_idx = 0 ; $x_idx <= $#x_values ; $x_idx++ )
{
    if ( $x_values[$x_idx] < 0 )
    {
        $y1_values[$x_idx] = 1 / $x_values[$x_idx];
        $y2_values[$x_idx] = $max_y + 10;
    }
    elsif ( $x_values[$x_idx] > 0 )
    {
        $y1_values[$x_idx] = $min_y - 10;
        $y2_values[$x_idx] = 1 / $x_values[$x_idx];
    }
    else
    {
        $y2_values[$x_idx] = $max_y + 10;
        $y1_values[$x_idx] = $min_y - 10;
    }
}

#------------------------------------------------------------------------------------
# Make it
#------------------------------------------------------------------------------------

$graphic = Chart::Lines->new( 750, 600 );
$graphic->set( 'brush_size' => 2 );

$graphic->add_dataset(@x_values);

$graphic->add_dataset(@y1_values);
$graphic->add_dataset(@y2_values);

$graphic->set( 'min_val' => $min_y );
$graphic->set( 'max_val' => $max_y );

#$graphic -> set ('y_ticks' => 11 );
$graphic->set( 'x_ticks'      => 'vertical' );
$graphic->set( 'skip_x_ticks' => 10 );

$graphic->set( 'grey_background' => 'true' );
$graphic->set( 'graph_border'    => 18 );
$graphic->set( 'title'           => "1/x" );
$graphic->set( 'y_grid_lines'    => 'true' );
$graphic->set( 'x_grid_lines'    => 'true' );
$graphic->set( 'x_ticks'         => 'vertical' );
$graphic->set( 'legend'          => 'none' );
$graphic->set( 'x_label'         => 'x' );
$graphic->set( 'y_label'         => 'f = 1/x' );

if ( $graphic->can('gif') )
{
    my $picture_file = "samples/Math_1_over_x.gif";
    $graphic->gif($picture_file);
}
if ( $graphic->can('png') )
{
    my $picture_file = "samples/Math_1_over_x.png";
    $graphic->png($picture_file);
}

print "ok 1\n";

exit(0);

