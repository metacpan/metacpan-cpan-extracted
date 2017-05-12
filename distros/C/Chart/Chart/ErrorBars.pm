## @file
# Implementation of Chart::ErrorBars
#
# written by
# @author david bonner (dbonner@cs.bu.edu)
#
# maintained by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

package Chart::ErrorBars;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::ErrorBars::ISA     = qw(Chart::Base);
$Chart::ErrorBars::VERSION = '2.4.10';

## @class Chart::ErrorBars
# ErrorBars class derived from class Base.
#
# This class provides all functions which are specific to
# pointes having carrying vertical bars which represent
# errors or standard deviations
#

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private _draw_data
# finally get around to plotting the data
#
# Overwrites Base function
#
sub _draw_data
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $x1, $x2, $x3, $y1, $y2, $y3, $mod, $y_error_up, $y_error_down );
    my ( $width, $height, $delta, $map, $delta_num, $zero_offset, $flag );
    my ( $i, $j, $color, $brush );
    my $dataset = 0;
    my $diff;

    # init the imagemap data field if they want it
    if ( $self->true( $self->{'imagemap'} ) )
    {
        $self->{'imagemap_data'} = [];
    }

    # find the delta value between data points, as well
    # as the mapping constant
    $width  = $self->{'curr_x_max'} - $self->{'curr_x_min'};
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $delta  = $width / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
    $diff   = $self->{'max_val'} - $self->{'min_val'};
    $diff   = 1 if $diff == 0;
    $map    = $height / $diff;

    # for a xy-plot, use this delta and maybe an offset for the zero-axes
    if ( $self->true( $self->{'xy_plot'} ) )
    {
        $diff      = $self->{'x_max_val'} - $self->{'x_min_val'};
        $diff      = 1 if $diff == 0;
        $delta_num = $width / $diff;

        if ( $self->{'x_min_val'} <= 0 && $self->{'x_max_val'} >= 0 )
        {
            $zero_offset = abs( $self->{'x_min_val'} ) * abs($delta_num);
        }
        elsif ( $self->{'x_min_val'} > 0 || $self->{'x_max_val'} < 0 )
        {
            $zero_offset = -$self->{'x_min_val'} * $delta_num;
        }
        else
        {
            $zero_offset = 0;
        }
    }

    # get the base x-y values
    if ( $self->false( $self->{'xy_plot'} ) )
    {
        $x1 = $self->{'curr_x_min'} + ( $delta / 2 );
    }
    else
    {
        $x1 = $self->{'curr_x_min'};
    }
    if ( $self->{'min_val'} >= 0 )
    {
        $y1  = $self->{'curr_y_max'};
        $mod = $self->{'min_val'};
    }
    elsif ( $self->{'max_val'} <= 0 )
    {
        $y1  = $self->{'curr_y_min'};
        $mod = $self->{'max_val'};
    }
    else
    {
        $y1 = $self->{'curr_y_min'} + ( $map * $self->{'max_val'} );
        $mod = 0;
        $self->{'gd_obj'}->line( $self->{'curr_x_min'}, $y1, $self->{'curr_x_max'}, $y1, $misccolor );
    }

    # first of all box it off
    $self->{'gd_obj'}
      ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );

    # draw the points
    for $i ( 1 .. $self->{'num_datasets'} )
    {
        if ( $self->false( $self->{'same_error'} ) )
        {

            # get the color for this dataset, and set the brush
            $color = $self->_color_role_to_index( 'dataset' . ($dataset) );    # draw every point for this dataset
            $dataset++ if ( ( $i - 1 ) % 3 == 0 );
            for $j ( 0 .. $self->{'num_datapoints'} )
            {

                #get the brush for points
                $brush = $self->_prepare_brush( $color, 'point' );
                $self->{'gd_obj'}->setBrush($brush);

                # only draw if the current set is really a dataset and no errorset
                if ( ( $i - 1 ) % 3 == 0 )
                {

                    # don't try to draw anything if there's no data
                    if ( defined( $data->[$i][$j] ) )
                    {
                        if ( $self->true( $self->{'xy_plot'} ) )
                        {
                            $x2 = $x1 + $delta_num * $data->[0][$j] + $zero_offset + 1;
                            $x3 = $x2;
                        }
                        else
                        {
                            $x2 = $x1 + ( $delta * $j ) + 1;
                            $x3 = $x2;
                        }
                        $y2           = $y1 - ( ( $data->[$i][$j] - $mod ) * $map );
                        $y3           = $y2;
                        $y_error_up   = $y2 - abs( $data->[ $i + 1 ][$j] ) * $map;
                        $y_error_down = $y2 + abs( $data->[ $i + 2 ][$j] ) * $map;

                        # draw the point only if it is within the chart borders
                        if (   $data->[$i][$j] <= $self->{'max_val'}
                            && $data->[$i][$j] >= $self->{'min_val'} )
                        {
                            $self->{'gd_obj'}->line( $x2, $y2, $x3, $y3, gdBrushed );
                            $flag = 'true';
                        }

                        #reset the brush for lines
                        $brush = $self->_prepare_brush( $color, 'line' );
                        $self->{'gd_obj'}->setBrush($brush);

                        #draw the error bars
                        if ( $self->true($flag) )
                        {

                            # the upper lines
                            $self->{'gd_obj'}->line( $x2,     $y2,         $x3,     $y_error_up, gdBrushed );
                            $self->{'gd_obj'}->line( $x2 - 3, $y_error_up, $x3 + 3, $y_error_up, gdBrushed );

                            # the down lines
                            $self->{'gd_obj'}->line( $x2,     $y2,           $x3,     $y_error_down, gdBrushed );
                            $self->{'gd_obj'}->line( $x2 - 3, $y_error_down, $x3 + 3, $y_error_down, gdBrushed );
                            $flag = 'false';
                        }

                        # store the imagemap data if they asked for it
                        if ( $self->true( $self->{'imagemap'} ) )
                        {
                            $self->{'imagemap_data'}->[$i][$j] = [ $x2, $y2 ];
                        }
                    }
                }
            }
        }
        else
        {

            # get the color for this dataset, and set the brush
            $color = $self->_color_role_to_index( 'dataset' . ($dataset) );    # draw every point for this dataset
            $dataset++ if ( ( $i - 1 ) % 2 == 0 );
            for $j ( 0 .. $self->{'num_datapoints'} )
            {

                #get the brush for points
                $brush = $self->_prepare_brush( $color, 'point' );
                $self->{'gd_obj'}->setBrush($brush);

                # only draw if the current set is really a dataset and no errorset
                if ( ( $i - 1 ) % 2 == 0 )
                {

                    # don't try to draw anything if there's no data
                    if ( defined( $data->[$i][$j] ) )
                    {
                        if ( $self->true( $self->{'xy_plot'} ) )
                        {
                            $x2 = $x1 + $delta_num * $data->[0][$j] + $zero_offset;
                            $x3 = $x2;
                        }
                        else
                        {
                            $x2 = $x1 + ( $delta * $j );
                            $x3 = $x2;
                        }
                        $y2           = $y1 - ( ( $data->[$i][$j] - $mod ) * $map );
                        $y3           = $y2;
                        $y_error_up   = $y2 - abs( $data->[ $i + 1 ][$j] ) * $map;
                        $y_error_down = $y2 + abs( $data->[ $i + 1 ][$j] ) * $map;

                        # draw the point only if it is within the chart borders
                        if (   $data->[$i][$j] <= $self->{'max_val'}
                            && $data->[$i][$j] >= $self->{'min_val'} )
                        {
                            $self->{'gd_obj'}->line( $x2, $y2, $x3, $y3, gdBrushed );
                            $flag = 'true';
                        }

                        #reset the brush for lines
                        $brush = $self->_prepare_brush( $color, 'line' );
                        $self->{'gd_obj'}->setBrush($brush);

                        #draw the error bars
                        if ( $self->true($flag) )
                        {

                            # the upper lines
                            $self->{'gd_obj'}->line( $x2,     $y2,         $x3,     $y_error_up, gdBrushed );
                            $self->{'gd_obj'}->line( $x2 - 3, $y_error_up, $x3 + 3, $y_error_up, gdBrushed );

                            # the down lines
                            $self->{'gd_obj'}->line( $x2,     $y2,           $x3,     $y_error_down, gdBrushed );
                            $self->{'gd_obj'}->line( $x2 - 3, $y_error_down, $x3 + 3, $y_error_down, gdBrushed );
                            $flag = 'false';
                        }

                        # store the imagemap data if they asked for it
                        if ( $self->true( $self->{'imagemap'} ) )
                        {
                            $self->{'imagemap_data'}->[$i][$j] = [ $x2, $y2 ];
                        }
                    }
                }    #end for
            }
        }
    }
    return 1;
}

## @fn private _prepare_brush
#  set the gdBrush object to trick GD into drawing fat lines
#
# Overwrite Base function
#
sub _prepare_brush
{
    my $self  = shift;
    my $color = shift;
    my $type  = shift;
    my ( $radius, @rgb, $brush, $white, $newcolor );

    # get the rgb values for the desired color
    @rgb = $self->{'gd_obj'}->rgb($color);

    # get the appropriate brush size
    if ( $type eq 'line' )
    {
        $radius = $self->{'brush_size'} / 2;
    }
    elsif ( $type eq 'point' )
    {
        $radius = $self->{'pt_size'} / 2;
    }

    # create the new image
    $brush = GD::Image->new( $radius * 2, $radius * 2 );

    # get the colors, make the background transparent
    $white = $brush->colorAllocate( 255, 255, 255 );
    $newcolor = $brush->colorAllocate(@rgb);
    $brush->transparent($white);

    # draw the circle
    $brush->arc( $radius - 1, $radius - 1, $radius, $radius, 0, 360, $newcolor );

    # fill it if we're using lines
    $brush->fill( $radius - 1, $radius - 1, $newcolor );

    # set the new image as the main object's brush
    return $brush;
}

## @fn private int _draw_legend()
# let them know what all the pretty colors mean
# @return status
##  let them know what all the pretty colors mean
sub _draw_legend
{
    my $self = shift;
    my ( $length, $step, $temp, $post_length );
    my $j = 0;

    # check to see if legend type is none..
    if ( $self->{'legend'} =~ /^none$/ )
    {
        return 1;
    }

    #just for later checking and warning
    if ( $#{ $self->{'legend_labels'} } >= 0 )
    {
        $post_length = scalar( @{ $self->{'legend_labels'} } );
    }

    #look if every second or eyery third dataset is a set for data
    if ( $self->false( $self->{'same_error'} ) )
    {
        $step = 3;
    }
    else
    {
        $step = 2;
    }

    # init a field to store the length of the longest legend label
    unless ( $self->{'max_legend_label'} )
    {
        $self->{'max_legend_label'} = 0;
    }

    # fill in the legend labels, find the longest one
    for ( my $i = 1 ; $i < $self->{'num_datasets'} ; $i += $step )
    {
        my $label = $j + 1;
        unless ( $self->{'legend_labels'}[$j] )
        {
            $self->{'legend_labels'}[$j] = "Dataset $label";
        }
        $length = length( $self->{'legend_labels'}[$j] );
        if ( $length > $self->{'max_legend_label'} )
        {
            $self->{'max_legend_label'} = $length;
        }
        $j++;
    }

    #we just have to label the datasets in the legend
    #we'll reset it, to draw the sets
    $temp = $self->{'num_datasets'};
    $self->{'num_datasets'} = $j;

    # check to see if they have as many labels as datasets,
    # warn them if not
    if ( ( $post_length > 0 ) && ( $post_length != $j ) )
    {
        carp "The number of legend labels and datasets doesn\'t match";
    }

    # different legend types
    if ( $self->{'legend'} eq 'bottom' )
    {
        $self->_draw_bottom_legend;
    }
    elsif ( $self->{'legend'} eq 'right' )
    {
        $self->_draw_right_legend;
    }
    elsif ( $self->{'legend'} eq 'left' )
    {
        $self->_draw_left_legend;
    }
    elsif ( $self->{'legend'} eq 'top' )
    {
        $self->_draw_top_legend;
    }
    else
    {
        carp "I can't put a legend there (at " . $self->{'legend'} . ")\n";
    }

    #reset the number of dataset to make sure that everything goes right
    $self->{'num_datasets'} = $temp;

    # and return
    return 1;
}

#find the range of the x scale, don't forget the errors!
sub _find_y_range
{
    my $self = shift;
    my $data = $self->{'dataref'};

    my $max = undef;
    my $min = undef;
    if ( $self->false( $self->{'same_error'} ) )
    {
        for my $i ( 1 .. $self->{'num_datasets'} )
        {
            if ( ( $i - 1 ) % 3 == 0 )
            {
                for my $j ( 0 .. $self->{'num_datapoints'} )
                {
                    if ( defined( $data->[$i][$j] ) && defined( $data->[ $i + 1 ][$j] ) && defined( $data->[ $i + 2 ][$j] ) )
                    {
                        if ( defined $max )
                        {
                            if ( ( $data->[$i][$j] + abs( $data->[ $i + 1 ][$j] ) ) > $max )
                            {
                                $max = $data->[$i][$j] + abs( $data->[ $i + 1 ][$j] );
                            }
                            if ( ( $data->[$i][$j] - abs( $data->[ $i + 2 ][$j] ) ) < $min )
                            {
                                $min = $data->[$i][$j] - abs( $data->[ $i + 2 ][$j] );
                            }
                        }
                        else { $min = $max = $data->[$i][$j]; }
                    }
                }
            }
        }
        return ( $min, $max );
    }
    else
    {
        for my $i ( 1 .. $self->{'num_datasets'} )
        {
            if ( ( $i - 1 ) % 2 == 0 )
            {
                for my $j ( 0 .. $self->{'num_datapoints'} )
                {
                    if ( defined( $data->[$i][$j] ) && defined( $data->[ $i + 1 ][$j] ) )
                    {
                        if ( defined $max )
                        {
                            if ( ( $data->[$i][$j] + $data->[ $i + 1 ][$j] ) > $max )
                            {
                                $max = $data->[$i][$j] + $data->[ $i + 1 ][$j];
                            }
                            if ( ( $data->[$i][$j] - $data->[ $i + 1 ][$j] ) < $min )
                            {
                                $min = $data->[$i][$j] - $data->[ $i + 1 ][$j];
                            }
                        }
                        else { $min = $max = $data->[$i][$j]; }
                    }
                }
            }
        }
        return ( $min, $max );
    }
}
## be a good module and return 1
1;
