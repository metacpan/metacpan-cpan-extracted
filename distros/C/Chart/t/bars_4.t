#!/usr/bin/perl -w

# The Integral of the mathematical function 1/x

use strict;
use Chart::Bars;

print "1..1\n";

my @x_values = ();    # x axis
my @y_values = ();

my $graphic;
my $picture_file = "samples/bars_4.png";
my $min_y        = -5;                     # max. y-values
my $max_y        = 5;

my $x;
my $y;

#------------------------------------------------------------------------------------
# Start
#------------------------------------------------------------------------------------

#calculate the values
for ( my $x = -5 ; $x <= 5 ; ( $x = $x + 0.0005 ) )
{
    push( @x_values, $x );
    if ( $x != 0 )
    {    # division by zero!
        $y = 1 / $x;

        if ( $y > $max_y )
        {
            push( @y_values, $max_y );
        }
        elsif ( $y < $min_y )
        {
            push( @y_values, $min_y );
        }
        else
        {
            push( @y_values, $y );
        }
    }
    else
    {
        push( @y_values, 0 );
    }
}

#------------------------------------------------------------------------------------
# Make it
#------------------------------------------------------------------------------------

$graphic = Chart::Bars->new( 600, 600 );

$graphic->add_dataset(@x_values);
$graphic->add_dataset(@y_values);

$graphic->set( 'min_val'      => $min_y );
$graphic->set( 'max_val'      => $max_y );
$graphic->set( 'min_y_ticks'  => 20 );
$graphic->set( 'skip_x_ticks' => 1000 );
$graphic->set( 'graph_border' => 18 );
$graphic->set( 'title'        => "The Integral of 1/x" );
$graphic->set( 'grid_lines'   => 'true' );
$graphic->set( 'x_ticks'      => 'vertical' );
$graphic->set( 'legend'       => 'none' );
$graphic->set( 'y_label'      => 'f = 1 / x' );
$graphic->set( 'xy_plot'      => 'true' );

# use a special function to convert the y values to something special
$graphic->set( 'f_y_tick' => \&formatter );
$graphic->set( 'f_x_tick' => \&formatter );

$graphic->png($picture_file);

sub formatter
{
    my $y_value = shift;
    my $label = sprintf "%1.2f", $y_value;
    if ( $label == '-0.00' )
    {
        $label = '0';
    }

    return $label;
}
print "ok 1\n";

exit(0);
