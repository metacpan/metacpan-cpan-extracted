#!/usr/bin/perl -w
#
# Testprogram for f_x_ticks
#
#======================================================================

use strict;
use Chart::LinesPoints;

print "1..1\n";

my @x_values      = ();    # real x values
my @y_values      = ();    # real y values
my @x_plot_values = ();    # x values for plot
my @y_plot_values = ();    # y values for plot

my $graphic;
my $min_x = -15;           # random start
my $max_x = 10;            # random stop
my $min_y;
my $max_y;

my $x;
my $y;

#------------------------------------------------------------------------------------
# Start
#------------------------------------------------------------------------------------

$x = $min_x;
for ( my $idx = 0 ; $x <= $max_x ; $idx += 0.1 )
{
    $x = $min_x + $idx;
    $x_values[$idx] = $x;
    $y_values[$idx] = cos( ( $x - $min_x ) );
}

undef $min_y;
undef $max_y;
for ( my $idx = 0 ; $idx <= $#x_values ; $idx++ )
{
    $x_plot_values[$idx] = $x_values[$idx] + $min_x;
    $y_plot_values[$idx] = $y_values[$idx];
    if ( !defined($min_y) )
    {
        $min_y = $y_values[$idx];
    }
    else
    {
        $min_y = ( $min_y < $y_values[$idx] ) ? $min_y : $y_values[$idx];
    }
    if ( !defined($max_y) )
    {
        $max_y = $y_values[$idx];
    }
    else
    {
        $max_y = ( $max_y > $y_values[$idx] ) ? $max_y : $y_values[$idx];
    }
}

#------------------------------------------------------------------------------------
# Make it
#------------------------------------------------------------------------------------

$graphic = Chart::LinesPoints->new( 750, 600 );
$graphic->set( 'brush_size' => 2 );

$graphic->add_dataset(@x_plot_values);

$graphic->add_dataset(@y_plot_values);

$graphic->set( 'min_val' => $min_y );
$graphic->set( 'max_val' => $max_y );

#$graphic -> set ('y_ticks' => 11 );

#$graphic -> set ('skip_x_ticks' => 100);
$graphic->set( 'pt_size'         => 2 );
$graphic->set( 'grey_background' => 'true' );
$graphic->set( 'graph_border'    => 18 );
$graphic->set( 'title'           => "f_tick example for x and y values" );
$graphic->set( 'y_grid_lines'    => 'false' );
$graphic->set( 'x_grid_lines'    => 'false' );
$graphic->set( 'x_ticks'         => 'vertical' );
$graphic->set( 'legend'          => 'none' );
$graphic->set( 'x_label'         => 'some x-values' );
$graphic->set( 'y_label'         => 'f = cos(g(x))' );

# use a special function to convert the x values to HH:MM:SS
$graphic->set( 'f_x_tick' => \&convert_to_real_x );

if ( $graphic->can('png') )
{
    my $picture_file = "samples/f_ticks_1.png";
    $graphic->png($picture_file);
}

print "ok 1\n";

exit(0);

sub convert_to_real_x
{
    my $plot_x = shift;

    my $result = sprintf "%6.1f", $plot_x - $min_x;
    return ($result);
}

