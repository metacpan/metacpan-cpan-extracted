## @file
# Implementation of Chart::Mountain
#
#  written by david bonner
#  dbonner@cs.bu.edu
#
# maintained by
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#
#  Updated for
#  compatibility with
#  changes to Chart::Base
#  by peter clark
#  ninjaz@webexpress.com
#
# Copyright 1998, 1999 by James F. Miner.
# All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

## @class Chart::Mountain
# @brief Mountain class derived class for Chart to implement mountain type of plots
#
# Some Mountain chart details:
#
#   The effective y data value for a given x point and dataset
#   is the sum of the actual y data values of that dataset and
#   all datasets "below" it (i.e., with higher dataset indexes).
#
#   If the y data value in any dataset is undef or negative for
#   a given x, then all datasets are treated as missing for that x.
#
#   The y minimum is always forced to zero.
#
#   To avoid a dataset area "cutting into" the area of the dataset below
#   it, the y pixel for each dataset point will never be below the y pixel for
#   the same point in the dataset below the dataset.

#   This probably should have a custom legend method, because each
#   dataset is identified by the fill color (and optional pattern)
#   of its area, not just a line color.  So the legend shou a square
#   of the color and pattern for each dataset.

package Chart::Mountain;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::Mountain::ISA     = qw ( Chart::Base );
$Chart::Mountain::VERSION = '2.4.10';

#===================#
#  private methods  #
#===================#

## @fn private array _find_y_range()
# Find minimum and maximum value of y data sets.
#
# @return ( min, max, flag_all_integers )
sub _find_y_range
{
    my $self = shift;

    #   This finds the maximum point-sum over all x points,
    #   where the point-sum is the sum of the dataset values at that point.
    #   If the y value in any dataset is undef for a given x, then all datasets
    #   are treated as missing for that x.

    my $data = $self->{'dataref'};
    my $max  = undef;
    for my $i ( 0 .. $#{ $data->[0] } )
    {
        my $y_sum = $data->[1]->[$i];
        if ( defined $y_sum && $y_sum >= 0 )
        {
            for my $dataset ( @$data[ 2 .. $#$data ] )
            {    # order not important
                my $datum = $dataset->[$i];
                if ( defined $datum && $datum >= 0 )
                {
                    $y_sum += $datum;
                }
                else
                {    # undef or negative, treat all at same x as missing.
                    $y_sum = undef;
                    last;
                }
            }
        }
        if ( defined $y_sum )
        {
            $max = $y_sum unless defined $max && $y_sum <= $max;
        }
    }

    ( 0, $max );
}

## @fn private _draw_data
# draw the data
sub _draw_data
{
    my $self = shift;
    my $data = $self->{'dataref'};

    my @patterns = @{ $self->{'patterns'} || [] };

    # Calculate array of x pixel positions (@x).
    my $x_step =
      ( $self->{'curr_x_max'} - $self->{'curr_x_min'} ) / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
    my $x_min = $self->{'curr_x_min'} + $x_step / 2;
    my $x_max = $self->{'curr_x_max'} - $x_step / 2;
    my @x     = map { $_ * $x_step + $x_min } 0 .. $self->{'num_datapoints'} - 1;
    my ( $t_x_min, $t_x_max, $t_y_min, $t_y_max, $abs_x_max, $abs_y_max );
    my $repair_top_flag = 0;

    # Calculate array of y pixel positions for upper boundary each dataset (@y).

    my $map =
        ( $self->{'max_val'} )
      ? ( $self->{'curr_y_max'} - $self->{'curr_y_min'} ) / $self->{'max_val'}
      : ( $self->{'curr_y_max'} - $self->{'curr_y_min'} ) / 10;

    my $y_max = $self->{'curr_y_max'};    # max pixel point (lower y values)

    my @y;
    for my $j ( 0 .. $#{ $data->[0] } )
    {
        my $sum = 0;
        for my $i ( reverse 1 .. $#{$data} )
        {                                 # bottom to top of chart
            my $datum = $data->[$i][$j];

            #set the repair flag, if the datum is out of the borders of the chart
            if ( defined $datum && $datum > $self->{'max_val'} ) { $repair_top_flag = 1; }

            if ( defined $datum && $datum >= 0 )
            {
                $sum += $datum;
                $y[ $i - 1 ][$j] = $y_max - $map * $sum;
            }
            else
            {                             # missing value, force all to undefined
                foreach my $k ( 1 .. $#{$data} ) { $y[ $k - 1 ][$j] = undef }
                last;
            }
        }
    }

    # Find first and last x where y is defined in the bottom dataset.
    my $x_begin = 0;
    my $x_end   = $self->{'num_datapoints'} - 1;
    while ( $x_begin <= $x_end && !defined $y[-1]->[$x_begin] ) { $x_begin++ }
    while ( $x_begin <= $x_end && !defined $y[-1]->[$x_end] )   { $x_end-- }

    if ( $x_begin > $x_end ) { croak "Internal error: x_begin > x_end ($x_begin > $x_end)"; }

    # For each dataset, generate a polygon for the dataset's area of the chart,
    # and fill the polygon with the dataset's color/pattern.

    my $poly = GD::Polygon->new;
    $poly->addPt( $x[$x_end],   $y_max );    # right end of x axis
    $poly->addPt( $x[$x_begin], $y_max );    # left end of x axis (right-to-left)

    for my $dataset ( reverse 0 .. @y - 1 )
    {
        my $y_ref = $y[$dataset];

        # Append points for this dataset to polygon, direction depends on $dataset % 2.
        my $last_vertex_count = $poly->length;
        if ( ( @y - 1 - $dataset ) % 2 )
        {                                    # right-to-left
            for ( reverse $x_begin .. $x_end )
            {
                $poly->addPt( $x[$_], $y_ref->[$_] ) if defined $y_ref->[$_];
            }
        }
        else
        {                                    # left-to-right
            for ( $x_begin .. $x_end )
            {
                $poly->addPt( $x[$_], $y_ref->[$_] ) if defined $y_ref->[$_];
            }
        }

        # draw the polygon
        my $color = $self->_color_role_to_index( 'dataset' . $dataset );
        if ( $patterns[$dataset] )
        {
            $self->{'gd_obj'}->filledPolygon( $poly, $color ) if $patterns[$dataset]->transparent >= 0;
            $self->{'gd_obj'}->setTile( $patterns[$dataset] );
            $self->{'gd_obj'}->filledPolygon( $poly, gdTiled );
        }
        else
        {
            $self->{'gd_obj'}->filledPolygon( $poly, $color );
        }

        # delete previous dataset's points from the polygon, update $last_vertex_count.
        unless ( $dataset == 0 )
        {    # don't bother do delete points after last area
            while ($last_vertex_count) { $poly->deletePt(0); $last_vertex_count-- }
        }
    }

    # Enclose the plots
    $self->{'gd_obj'}->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'},
        $self->_color_role_to_index('misc') );

    #get the width and the heigth of the complete picture
    ( $abs_x_max, $abs_y_max ) = $self->{'gd_obj'}->getBounds();

    #repair the chart, if the lines are out of the borders of the chart
    if ($repair_top_flag)
    {

        #overwrite the ugly mistakes
        $self->{'gd_obj'}->filledRectangle(
            $self->{'curr_x_min'}, 0, $self->{'curr_x_max'},
            $self->{'curr_y_min'} - 1,
            $self->_color_role_to_index('background')
        );

        #save the actual x and y values
        $t_x_min = $self->{'curr_x_min'};
        $t_x_max = $self->{'curr_x_max'};
        $t_y_min = $self->{'curr_y_min'};
        $t_y_max = $self->{'curr_y_max'};

        #get back to the point, where everything began
        $self->{'curr_x_min'} = 0;
        $self->{'curr_y_min'} = 0;
        $self->{'curr_x_max'} = $abs_x_max;
        $self->{'curr_y_max'} = $abs_y_max;

        #draw the title again
        if ( $self->{'title'} )
        {
            $self->_draw_title();
        }

        #draw the sub title again
        if ( $self->{'sub_title'} )
        {
            $self->_draw_sub_title();
        }

        #draw the top legend again
        if ( $self->{'legend'} =~ /^top$/i )
        {
            $self->_draw_top_legend();
        }

        #reset the actual values
        $self->{'curr_x_min'} = $t_x_min;
        $self->{'curr_x_max'} = $t_x_max;
        $self->{'curr_y_min'} = $t_y_min;
        $self->{'curr_y_max'} = $t_y_max;
    }
}

###############################################################

### Fix a bug in GD::Polygon.
### A patch has been submitted to Lincoln Stein.

require GD;
unless ( defined &GD::Polygon::deletePt )
{
    *GD::Polygon::deletePt = sub {
        my ( $self, $index ) = @_;
        unless ( ( $index >= 0 ) && ( $index < @{ $self->{'points'} } ) )
        {
            warn "Attempt to set an undefined polygon vertex";
            return undef;
        }
        my ($vertex) = splice( @{ $self->{'points'} }, $index, 1 );
        $self->{'length'}--;
        return @$vertex;
      }
}

###############################################################

1;
