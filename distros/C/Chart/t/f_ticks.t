#!/usr/bin/perl -w
#
# Testprogram for lines
# converting seconds since 0 o'clock to HH:MM:SS on x
# converting -1 .. +1 to -100 ... +100 on y
#
#======================================================================

use strict;
use Chart::Points;

print "1..1\n";

my @x_values = ();    # x axis
my @y_values = ();

my $graphic;
my $min_x = 600;      # random start
my $max_x = 86400;    # number of seconds of a day
my $min_y;
my $max_y;

my $x;
my $y;

#------------------------------------------------------------------------------------
# Start
#------------------------------------------------------------------------------------

$x = $min_x;
for ( my $x_idx = 0 ; $x < $max_x ; $x_idx++ )
{
    $x = $min_x + $x_idx * 23;
    $x_values[$x_idx] = $x;
    $y_values[$x_idx] = cos( ( $x - $min_x ) / 3000 );
}

#------------------------------------------------------------------------------------
# Make it
#------------------------------------------------------------------------------------

$graphic = Chart::Points->new( 750, 600 );
$graphic->set( 'brush_size' => 2 );

$graphic->add_dataset(@x_values);

$graphic->add_dataset(@y_values);

$graphic->set( 'min_val' => $min_y );
$graphic->set( 'max_val' => $max_y );

#$graphic -> set ('y_ticks' => 11 );

$graphic->set( 'skip_x_ticks'    => 100 );
$graphic->set( 'pt_size'         => 2 );
$graphic->set( 'grey_background' => 'true' );
$graphic->set( 'graph_border'    => 18 );
$graphic->set( 'title'           => "f_tick example for x and y values" );
$graphic->set( 'y_grid_lines'    => 'false' );
$graphic->set( 'x_grid_lines'    => 'false' );
$graphic->set( 'x_ticks'         => 'vertical' );
$graphic->set( 'legend'          => 'none' );
$graphic->set( 'x_label'         => 'Time of the day' );
$graphic->set( 'y_label'         => 'f = sin(x)' );

# use a special function to convert the x values to HH:MM:SS
$graphic->set( 'f_x_tick' => \&seconds_to_hour_minute );

# use a special function to convert the y values to something special
$graphic->set( 'f_y_tick' => \&formatter );

if ( $graphic->can('gif') )
{
    my $picture_file = "samples/f_ticks.gif";
    $graphic->gif($picture_file);
}
if ( $graphic->can('png') )
{
    my $picture_file = "samples/f_ticks.png";
    $graphic->png($picture_file);
}

print "ok 1\n";

exit(0);

sub seconds_to_hour_minute
{
    my $seconds = shift;

    my $hour   = int( $seconds / 3600 );
    my $minute = int( ( $seconds - $hour * 3600 ) / 60 );
    my $sec    = $seconds - $hour * 3600 - $minute * 60;

    sprintf "%02d:%02d:%02d", $hour, $minute, $sec;
}

sub formatter
{
    my $y_value = shift;

    sprintf "%02d", int( $y_value * 10 );
}
