## @file
# Implementation of Chart::StackedBars
#
# written by
# @author david bonner (dbonner@cs.bu.edu)
#
# maintained by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

## @class Chart::StackedBars
# StackedBars class derived from class Base.
#
# This class provides all functions which are specific to
# stacked bars
package Chart::StackedBars;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::StackedBars::ISA     = qw(Chart::Base);
$Chart::StackedBars::VERSION = '2.4.10';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private _check_data
# override check_data to make sure we don't get datasets with positive
# and negative values mixed
sub _check_data
{
    my $self   = shift;
    my $data   = $self->{'dataref'};
    my $length = 0;
    my ( $i, $j, $posneg );
    my $composite;

    # remember the number of datasets
    if ( defined $self->{'composite_info'} )
    {
        if ( $self->{'composite_info'}[0][0] =~ /^StackedBars$/i )
        {
            $composite = 0;
        }
        if ( $self->{'composite_info'}[1][0] =~ /^StackedBars$/i )
        {
            $composite = 1;
        }

        # $self->{'num_datasets'} = $#{$data};     ###

        $self->{'num_datasets'} = ( $#{ $self->{'composite_info'}[$composite][1] } ) + 1;
    }
    else
    {
        $self->{'num_datasets'} = $#{$data};
    }

    # remember the number of points in the largest dataset
    $self->{'num_datapoints'} = 0;
    for ( 0 .. $self->{'num_datasets'} )
    {
        if ( scalar( @{ $data->[$_] } ) > $self->{'num_datapoints'} )
        {
            $self->{'num_datapoints'} = scalar( @{ $data->[$_] } );
        }
    }

    # make sure the datasets don't mix pos and neg values
    for $i ( 0 .. $self->{'num_datapoints'} - 1 )
    {
        $posneg = '';
        for $j ( 1 .. $self->{'num_datasets'} )
        {
            if ( $data->[$j][$i] > 0 )
            {
                if ( $posneg eq 'neg' )
                {
                    croak "The values for a Chart::StackedBars data point must either be all positive or all negative";
                }
                else
                {
                    $posneg = 'pos';
                }
            }
            elsif ( $data->[$j][$i] < 0 )
            {
                if ( $posneg eq 'pos' )
                {
                    croak "The values for a Chart::StackedBars data point must either be all positive or all negative";
                }
                else
                {
                    $posneg = 'neg';
                }
            }
        }
    }

    # find good min and max y-values for the plot
    $self->_find_y_scale;

    # find the longest x-tick label
    for ( @{ $data->[0] } )
    {
        if ( length($_) > $length )
        {
            $length = length($_);
        }
    }

    # now store it in the object
    $self->{'x_tick_label_length'} = $length;

    return;
}

## @fn private _find_y_range
sub _find_y_range
{
    my $self = shift;

    #   This finds the minimum and maximum point-sum over all x points,
    #   where the point-sum is the sum of the dataset values for that point.
    #   If the y value in any dataset is undef for a given x, it simply
    #   adds nothing to the sum.

    my $data = $self->{'dataref'};
    my $max  = undef;
    my $min  = undef;
    for my $i ( 0 .. $#{ $data->[0] } )
    {    # data point
        my $sum = $data->[1]->[$i] || 0;
        for my $dataset ( @$data[ 2 .. $#$data ] )
        {    # order not important
            my $datum = $dataset->[$i];
            $sum += $datum if defined $datum;
        }
        if ( defined $max )
        {
            if    ( $sum > $max ) { $max = $sum }
            elsif ( $sum < $min ) { $min = $sum }
        }
        else { $min = $max = $sum }
    }

    # make sure all-positive or all-negative charts get anchored at
    # zero so that we don't cut out some parts of the bars
    if ( ( $max > 0 ) && ( $min > 0 ) )
    {
        $min = 0;
    }
    if ( ( $min < 0 ) && ( $max < 0 ) )
    {
        $max = 0;
    }

    ( $min, $max );
}

# ## override _find_y_scale to account for stacked bars
# sub _find_y_scale {
#   my $self = shift;
#   my $raw = $self->{'dataref'};
#   my $data = [@{$raw->[1]}];
#   my ($i, $j, $max, $min);
#   my ($order, $mult, $tmp);
#   my ($range, $delta, @dec, $y_ticks);
#   my $labels = [];
#   my $length = 0;
#
#   # use realy weird max and min values
#   $max = -999999999999;
#   $min = 999999999999;
#
#   # go through and stack them
#   for $i (0..$self->{'num_datapoints'}-1) {
#     for $j (2..$self->{'num_datasets'}) {
#       $data->[$i] += $raw->[$j][$i];
#     }
#   }
#
#   # get max and min values
#   for $i (0..$self->{'num_datapoints'}-1) {
#     if ($data->[$i] > $max) {
#       $max = $data->[$i];
#     }
#     if ($data->[$i] < $min) {
#       $min = $data->[$i];
#     }
#   }
#
#   # make sure all-positive or all-negative charts get anchored at
#   # zero so that we don't cut out some parts of the bars
#   if (($max > 0) && ($min > 0)) {
#     $min = 0;
#   }
#   if (($min < 0) && ($max < 0)) {
#     $max = 0;
#   }
#
#   # calculate good max value
#   if ($max < -10) {
#     $tmp = -$max;
#     $order = int((log $tmp) / (log 10));
#     $mult = int ($tmp / (10 ** $order));
#     $tmp = ($mult - 1) * (10 ** $order);
#     $max = -$tmp;
#   }
#   elsif ($max < 0) {
#     $max = 0;
#   }
#   elsif ($max > 10) {
#     $order = int((log $max) / (log 10));
#     $mult = int ($max / (10 ** $order));
#     $max = ($mult + 1) * (10 ** $order);
#   }
#   elsif ($max >= 0) {
#     $max = 10;
#   }
#
#   # now go for a good min
#   if ($min < -10) {
#     $tmp = -$min;
#     $order = int((log $tmp) / (log 10));
#     $mult = int ($tmp / (10 ** $order));
#     $tmp = ($mult + 1) * (10 ** $order);
#     $min = -$tmp;
#   }
#   elsif ($min < 0) {
#     $min = -10;
#   }
#   elsif ($min > 10) {
#     $order = int ((log $min) / (log 10));
#     $mult = int ($min / (10 ** $order));
#     $min = $mult * (10 ** $order);
#   }
#   elsif ($min >= 0) {
#     $min = 0;
#   }
#
#   # put the appropriate min and max values into the object if necessary
#   unless (defined ($self->{'max_val'})) {
#     $self->{'max_val'} = $max;
#   }
#   unless (defined ($self->{'min_val'})) {
#     $self->{'min_val'} = $min;
#   }
#
#   # generate the y_tick labels, store them in the object
#   # figure out which one is going to be the longest
#   $range = $self->{'max_val'} - $self->{'min_val'};
#   $y_ticks = $self->{'y_ticks'} - 1;
#   ## Don't adjust y_ticks if the user specified custom labels
#   if ($self->{'integer_ticks_only'} =~ /^true$/i && ! $self->{'y_tick_labels'}) {
#     unless (($range % $y_ticks) == 0) {
#       while (($range % $y_ticks) != 0) {
# 	$y_ticks++;
#       }
#       $self->{'y_ticks'} = $y_ticks + 1;
#     }
#   }
#
#   $delta = $range / $y_ticks;
#   for (0..$y_ticks) {
#     $tmp = $self->{'min_val'} + ($delta * $_);
#     @dec = split /\./, $tmp;
#     if ($dec[1] && (length($dec[1]) > 3)) {
#       $tmp = sprintf("%.3f", $tmp);
#     }
#     $labels->[$_] = $tmp;
#     if (length($tmp) > $length) {
#       $length = length($tmp);
#     }
#   }
#
#   # store it in the object
#   $self->{'y_tick_labels'} = $labels;
#   $self->{'y_tick_label_length'} = $length;
#
#   # and return
#   return;
# }

## @fn private _draw_data
# finally get around to plotting the data
sub _draw_data
{
    my $self      = shift;
    my $raw       = $self->{'dataref'};
    my $data      = [];
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $width, $height, $delta, $map, $mod );
    my ( $x1, $y1, $x2, $y2, $x3, $y3, $i, $j, $color, $cut );
    my $pink = $self->{'gd_obj'}->colorAllocate( 255, 0, 255 );

    # init the imagemap data field if they want it
    if ( $self->true( $self->{'imagemap'} ) )
    {
        $self->{'imagemap_data'} = [];
    }

    # width and height of remaining area, delta for width of bars, mapping value
    $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};

    if ( $self->true( $self->{'spaced_bars'} ) )
    {
        $delta = ( $width / ( $self->{'num_datapoints'} * 2 ) );
    }
    else
    {
        $delta = $width / $self->{'num_datapoints'};
    }
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $map = $height / ( $self->{'max_val'} - $self->{'min_val'} );

    # get the base x and y values
    $x1 = $self->{'curr_x_min'};
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

    # create another copy of the data, but stacked
    $data->[1] = [ @{ $raw->[1] } ];
    for $i ( 0 .. $self->{'num_datapoints'} - 1 )
    {
        for $j ( 2 .. $self->{'num_datasets'} )
        {
            $data->[$j][$i] = $data->[ $j - 1 ][$i] + $raw->[$j][$i];
        }
    }

    # draw the damn bars
    for $i ( 0 .. $self->{'num_datapoints'} - 1 )
    {

        # init the y values for this datapoint
        $y2 = $y1;

        for $j ( 1 .. $self->{'num_datasets'} )
        {

            # get the color
            $color = $self->_color_role_to_index( 'dataset' . ( $j - 1 ) );

            # set up the geometry for the bar
            if ( $self->true( $self->{'spaced_bars'} ) )
            {
                $x2 = $x1 + ( 2 * $i * $delta ) + ( $delta / 2 );
                $x3 = $x2 + $delta;

            }
            else
            {
                $x2 = $x1 + ( $i * $delta );
                $x3 = $x2 + $delta;
            }
            $y3 = $y1 - ( ( $data->[$j][$i] - $mod ) * $map );

            #cut the bars off, if needed
            if ( $data->[$j][$i] > $self->{'max_val'} )
            {
                $y3 = $y1 - ( ( $self->{'max_val'} - $mod ) * $map );
                $cut = 1;
            }
            elsif ( $data->[$j][$i] < $self->{'min_val'} )
            {
                $y3 = $y1 - ( ( $self->{'min_val'} - $mod ) * $map );
                $cut = 1;
            }
            else
            {
                $cut = 0;
            }

            # draw the bar
            ## y2 and y3 are reversed in some cases because GD's fill
            ## algorithm is lame
            if ( $data->[$j][$i] > 0 )
            {
                $self->{'gd_obj'}->filledRectangle( $x2, $y3, $x3, $y2, $color );
                if ( $self->true( $self->{'imagemap'} ) )
                {
                    $self->{'imagemap_data'}->[$j][$i] = [ $x2, $y3, $x3, $y2 ];
                }
            }
            else
            {
                $self->{'gd_obj'}->filledRectangle( $x2, $y2, $x3, $y3, $color );
                if ( $self->true( $self->{'imagemap'} ) )
                {
                    $self->{'imagemap_data'}->[$j][$i] = [ $x2, $y2, $x3, $y3 ];
                }
            }

            # now outline it. outline red if the bar had been cut off
            unless ($cut)
            {
                $self->{'gd_obj'}->rectangle( $x2, $y2, $x3, $y3, $misccolor );
            }
            else
            {
                $self->{'gd_obj'}->rectangle( $x2, $y2, $x3, $y3, $misccolor );
                $self->{'gd_obj'}->rectangle( $x2, $y1, $x3, $y3, $pink );
            }

            # now bootstrap the y values
            $y2 = $y3;
        }
    }

    # and finaly box it off
    $self->{'gd_obj'}
      ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );
    return;

}

## @fn private _draw_left_legend
sub _draw_left_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get the miscellaneous color
    $misccolor = $self->_color_role_to_index('misc');

    # find out how wide the largest label is
    $width =
      ( 2 * $self->{'text_space'} ) +
      ( $self->{'max_legend_label'} * $w ) +
      $self->{'legend_example_size'} +
      ( 2 * $self->{'legend_space'} );

    # get some base x-y coordinates
    $x1 = $self->{'curr_x_min'};
    $x2 = $self->{'curr_x_min'} + $width;
    $y1 = $self->{'curr_y_min'} + $self->{'graph_border'};
    $y2 =
      $self->{'curr_y_min'} +
      $self->{'graph_border'} +
      $self->{'text_space'} +
      ( $self->{'num_datasets'} * ( $h + $self->{'text_space'} ) ) +
      ( 2 * $self->{'legend_space'} );

    # box the legend off
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $misccolor );

    # leave that nice space inside the legend box
    $x1 += $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};

    # now draw the actual legend
    for ( 0 .. $#labels )
    {

        # get the color
        my $c = $self->{'num_datasets'} - $_ - 1;

        # color of the datasets in the legend
        if ( $self->{'dataref'}[1][0] < 0 )
        {
            $color = $self->_color_role_to_index( 'dataset' . $_ );
        }
        else
        {
            $color = $self->_color_role_to_index( 'dataset' . $c );
        }

        # find the x-y coords
        $x2 = $x1;
        $x3 = $x2 + $self->{'legend_example_size'};
        $y2 = $y1 + ( $_ * ( $self->{'text_space'} + $h ) ) + $h / 2;

        # do the line first
        $self->{'gd_obj'}->line( $x2, $y2, $x3, $y2, $color );

        # reset the brush for points
        $brush = $self->_prepare_brush( $color, 'point', $self->{ 'pointStyle' . $_ } );
        $self->{'gd_obj'}->setBrush($brush);

        # draw the point
        $self->{'gd_obj'}->line( int( ( $x3 + $x2 ) / 2 ), $y2, int( ( $x3 + $x2 ) / 2 ), $y2, gdBrushed );

        # now the label
        $x2 = $x3 + ( 2 * $self->{'text_space'} );
        $y2 -= $h / 2;

        # order of the datasets in the legend
        if ( $self->{'dataref'}[1][0] < 0 )
        {
            $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
        }
        else
        {
            $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$c], $color );
        }
    }

    # mark off the used space
    $self->{'curr_x_min'} += $width;

    # and return
    return 1;
}

## @fn private _draw_right_legend
sub _draw_right_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get the miscellaneous color
    $misccolor = $self->_color_role_to_index('misc');

    # find out how wide the largest label is
    $width =
      ( 2 * $self->{'text_space'} ) +
      ( $self->{'max_legend_label'} * $w ) +
      $self->{'legend_example_size'} +
      ( 2 * $self->{'legend_space'} );

    # get some starting x-y values
    $x1 = $self->{'curr_x_max'} - $width;
    $x2 = $self->{'curr_x_max'};
    $y1 = $self->{'curr_y_min'} + $self->{'graph_border'};
    $y2 =
      $self->{'curr_y_min'} +
      $self->{'graph_border'} +
      $self->{'text_space'} +
      ( $self->{'num_datasets'} * ( $h + $self->{'text_space'} ) ) +
      ( 2 * $self->{'legend_space'} );

    # box the legend off
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $misccolor );

    # leave that nice space inside the legend box
    $x1 += $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};

    # now draw the actual legend
    for ( 0 .. $#labels )
    {

        # get the color
        my $c = $self->{'num_datasets'} - $_ - 1;

        # color of the datasets in the legend

        if ( $self->{'dataref'}[1][0] < 0 )
        {
            $color = $self->_color_role_to_index( 'dataset' . $_ );
        }
        else
        {
            $color = $self->_color_role_to_index( 'dataset' . $c );
        }

        # find the x-y coords
        $x2 = $x1;
        $x3 = $x2 + $self->{'legend_example_size'};
        $y2 = $y1 + ( $_ * ( $self->{'text_space'} + $h ) ) + $h / 2;

        # do the line first
        $self->{'gd_obj'}->line( $x2, $y2, $x3, $y2, $color );

        # reset the brush for points
        $brush = $self->_prepare_brush( $color, 'point', $self->{ 'pointStyle' . $_ } );
        $self->{'gd_obj'}->setBrush($brush);

        # draw the point
        $self->{'gd_obj'}->line( int( ( $x3 + $x2 ) / 2 ), $y2, int( ( $x3 + $x2 ) / 2 ), $y2, gdBrushed );

        # now the label
        $x2 = $x3 + ( 2 * $self->{'text_space'} );
        $y2 -= $h / 2;

        # order of the datasets in the legend
        if ( $self->{'dataref'}[1][0] < 0 )
        {
            $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
        }
        else
        {
            $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$c], $color );
        }
    }

    # mark off the used space
    $self->{'curr_x_max'} -= $width;

    # and return
    return 1;
}

## be a good module and return 1
1;
