## @file
# Implementation of Chart::HorizontalBars
#
# maintained and written by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10

## @class Chart::HorizontalBars
# HorizontalBars class derived from class Base.
#
# This class provides all functions which are specific to
# horizontal bars
#
package Chart::HorizontalBars;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::HorizontalBars::ISA     = qw(Chart::Base);
$Chart::HorizontalBars::VERSION = '2.4.10';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @method private int _draw_x_ticks()
# draw the x-ticks and their labels
# Overwrites this function of Chart::Base
# @return status
#
sub _draw_x_ticks
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $font      = $self->{'tick_label_font'};
    my $textcolor = $self->_color_role_to_index('text');
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $h, $w, $x1, $y1, $y2, $x2, $delta, $width, $label );
    my @labels = @{ $self->{'y_tick_labels'} };

    $self->{'grid_data'}->{'x'} = [];

    #make sure we have a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn't a GD font object";
    }

    #get height and width of the font
    ( $h, $w ) = ( $font->height, $font->width );

    #get the right x-value and width
    if ( $self->{'y_axes'} =~ /^right$/i )
    {
        $x1 = $self->{'curr_x_min'};
        $width =
          $self->{'curr_x_max'} - $x1 - $self->{'tick_len'} - $self->{'text_space'} - $w * $self->{'x_tick_label_length'};
    }
    elsif ( $self->{'y_axes'} =~ /^both$/i )
    {
        $x1 = $self->{'curr_x_min'} + $self->{'text_space'} + $w * $self->{'x_tick_label_length'} + $self->{'tick_len'};
        $width =
          $self->{'curr_x_max'} - $x1 - $self->{'tick_len'} - $self->{'text_space'} - $w * $self->{'x_tick_label_length'};
    }
    else
    {
        $x1    = $self->{'curr_x_min'} + $self->{'text_space'} + $w * $self->{'x_tick_label_length'} + $self->{'tick_len'};
        $width = $self->{'curr_x_max'} - $x1;
    }

    #get the delta value
    $delta = $width / ( $self->{'y_ticks'} - 1 );

    #draw the labels
    $y2 = $y1;

    if ( $self->{'x_ticks'} =~ /^normal/i )
    {    #just normal ticks
            #get the point for updating later
        $y1 = $self->{'curr_y_max'} - 2 * $self->{'text_space'} - $h - $self->{'tick_len'};

        #get the start point
        $y2 = $y1 + $self->{'tick_len'} + $self->{'text_space'};
        for ( 0 .. $#labels )
        {
            $label = $self->{'y_tick_labels'}[$_];
            $x2 = $x1 + ( $delta * $_ ) - ( $w * length($label) / 2 );
            $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
        }
    }
    elsif ( $self->{'x_ticks'} =~ /^staggered/i )
    {    #staggered ticks
            #get the point for updating later
        $y1 = $self->{'curr_y_max'} - 3 * $self->{'text_space'} - 2 * $h - $self->{'tick_len'};

        for ( 0 .. $#labels )
        {
            $label = $self->{'y_tick_labels'}[$_];
            $x2 = $x1 + ( $delta * $_ ) - ( $w * length($label) / 2 );
            unless ( $_ % 2 )
            {
                $y2 = $y1 + $self->{'text_space'} + $self->{'tick_len'};
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
            }
            else
            {
                $y2 = $y1 + $h + 2 * $self->{'text_space'} + $self->{'tick_len'};
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $textcolor );
            }
        }

    }

    elsif ( $self->{'x_ticks'} =~ /^vertical/i )
    {    #vertical ticks
            #get the point for updating later
        $y1 = $self->{'curr_y_max'} - 2 * $self->{'text_space'} - $w * $self->{'y_tick_label_length'} - $self->{'tick_len'};

        for ( 0 .. $#labels )
        {
            $label = $self->{'y_tick_labels'}[$_];

            #get the start point
            $y2 = $y1 + $self->{'tick_len'} + $w * length($label) + $self->{'text_space'};

            $x2 = $x1 + ( $delta * $_ ) - ( $h / 2 );
            $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $label, $textcolor );
        }

    }

    else
    {
        carp "I don't understand the type of x-ticks you specified";
    }

    #update the curr x and y max value
    $self->{'curr_y_max'} = $y1;
    $self->{'curr_x_max'} = $x1 + $width;

    #draw the ticks
    $y1 = $self->{'curr_y_max'};
    $y2 = $self->{'curr_y_max'} + $self->{'tick_len'};
    for ( 0 .. $#labels )
    {
        $x2 = $x1 + ( $delta * $_ );
        $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
        if (   $self->true( $self->{'grid_lines'} )
            or $self->true( $self->{'x_grid_lines'} ) )
        {
            $self->{'grid_data'}->{'x'}->[$_] = $x2;
        }
    }

    return 1;
}

## @fn private int _draw_y_ticks()
#  draw the y-ticks and their labels
# Overwrites this function of Chart::Base
# @return status
sub _draw_y_ticks
{
    my $self      = shift;
    my $side      = shift || 'left';
    my $data      = $self->{'dataref'};
    my $font      = $self->{'tick_label_font'};
    my $textcolor = $self->_color_role_to_index('text');
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $h, $w, $x1, $x2, $y1, $y2 );
    my ( $width, $height, $delta );

    $self->{'grid_data'}->{'y'} = [];

    #make sure that is a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font isn't a GD Font object!";
    }

    #get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    #figure out, where to draw
    if ( $side =~ /^right$/i )
    {

        #get the right startposition
        $x1 = $self->{'curr_x_max'};
        $y1 = $self->{'curr_y_max'} - $h / 2;

        #get the delta values
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $delta = ($height) / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
        $y1 -= ( $delta / 2 );

        #look if skipping is desired
        if ( !defined( $self->{'skip_y_ticks'} ) )
        {
            $self->{'skip_y_ticks'} = 1;
        }

        #draw the labels
        for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ($delta) * ( $_ * $self->{'skip_y_ticks'} );
            $x2 = $x1 + $self->{'tick_len'} + $self->{'text_space'};
            $self->{'gd_obj'}
              ->string( $font, $x2, $y2, $self->{f_y_tick}->( $data->[0][ $_ * $self->{'skip_y_ticks'} ] ), $textcolor );
        }

        #draw the ticks
        $x1 = $self->{'curr_x_max'};
        $x2 = $self->{'curr_x_max'} + $self->{'tick_len'};
        $y1 += $h / 2;
        for ( 0 .. ( $self->{'num_datapoints'} - 1 / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y'}->[$_] = $y2;
            }
        }

    }
    elsif ( $side =~ /^both$/i )
    {

        #get the right startposition
        $x1 = $self->{'curr_x_max'};
        $y1 = $self->{'curr_y_max'} - $h / 2;

        #get the delta values
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $delta = ($height) / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
        $y1 -= ( $delta / 2 );

        #look if skipping is desired
        if ( !defined( $self->{'skip_y_ticks'} ) )
        {
            $self->{'skip_y_ticks'} = 1;
        }

        #first draw the right labels
        for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ($delta) * ( $_ * $self->{'skip_y_ticks'} );
            $x2 = $x1 + $self->{'tick_len'} + $self->{'text_space'};
            $self->{'gd_obj'}
              ->string( $font, $x2, $y2, $self->{f_y_tick}->( $data->[0][ $_ * $self->{'skip_y_ticks'} ] ), $textcolor );
        }

        #then draw the right ticks
        $x1 = $self->{'curr_x_max'};
        $x2 = $self->{'curr_x_max'} + $self->{'tick_len'};
        $y1 += $h / 2;
        for ( 0 .. ( $self->{'num_datapoints'} - 1 / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y'}->[$_] = $y2;
            }
        }

        #get the right startposition
        $x1 = $self->{'curr_x_min'};
        $y1 = $self->{'curr_y_max'} - $h / 2;

        #get the delta values for positioning
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $delta = ($height) / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
        $y1 -= ( $delta / 2 );

        #then draw the left labels
        for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ($delta) * ( $_ * $self->{'skip_y_ticks'} );
            $x2 =
              $x1 -
              $w * length( $self->{f_y_tick}->( $data->[0][ $_ * $self->{'skip_y_ticks'} ] ) )    #print the Labels right-sided
              + $w * $self->{'x_tick_label_length'};
            $self->{'gd_obj'}
              ->string( $font, $x2, $y2, $self->{f_y_tick}->( $data->[0][ $_ * $self->{'skip_y_ticks'} ] ), $textcolor );
        }

        #update the curr_x_min val
        $self->{'curr_x_min'} = $x1 + $self->{'text_space'} + $w * $self->{'x_tick_label_length'} + $self->{'tick_len'};

        #finally draw the left ticks
        $x1 = $self->{'curr_x_min'};
        $x2 = $self->{'curr_x_min'} - $self->{'tick_len'};
        $y1 += $h / 2;
        for ( 0 .. ( $self->{'num_datapoints'} - 1 / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y'}->[$_] = $y2;
            }
        }
    }

    else
    {

        #get the right startposition
        $x1 = $self->{'curr_x_min'};
        $y1 = $self->{'curr_y_max'} - $h / 2;

        #get the delta values for positioning
        $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
        $delta = ($height) / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
        $y1 -= ( $delta / 2 );

        if ( !defined( $self->{'skip_y_ticks'} ) )
        {
            $self->{'skip_y_ticks'} = 1;
        }

        #draw the labels
        for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ($delta) * ( $_ * $self->{'skip_y_ticks'} );
            $x2 =
              $x1 -
              $w * length( $self->{f_y_tick}->( $data->[0][ $_ * $self->{'skip_y_ticks'} ] ) )    #print the Labels right-sided
              + $w * $self->{'x_tick_label_length'};
            $self->{'gd_obj'}
              ->string( $font, $x2, $y2, $self->{f_y_tick}->( $data->[0][ $_ * $self->{'skip_y_ticks'} ] ), $textcolor );
        }

        #update the curr_x_min val
        $self->{'curr_x_min'} = $x1 + $self->{'text_space'} + $w * $self->{'x_tick_label_length'} + $self->{'tick_len'};

        #draw the ticks
        $x1 = $self->{'curr_x_min'};
        $x2 = $self->{'curr_x_min'} - $self->{'tick_len'};
        $y1 += $h / 2;
        for ( 0 .. ( $self->{'num_datapoints'} - 1 / $self->{'skip_y_ticks'} ) )
        {
            $y2 = $y1 - ( $delta * $_ );
            $self->{'gd_obj'}->line( $x1, $y2, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'y'}->[$_] = $y2;
            }
        }
    }

    #now return
    return 1;
}

## @fn private int _find_y_scale()
#  find good values for the minimum and maximum y-value on the chart
# overwrite the find_y_scale function, only to get the right f_x_ticks !!!!!
# @return status
sub _find_y_scale
{
    my $self = shift;

    # Predeclare vars.
    my ( $d_min,        $d_max );       # Dataset min & max.
    my ( $p_min,        $p_max );       # Plot min & max.
    my ( $tickInterval, $tickCount );
    my @tickLabels;                     # List of labels for each tick.
    my $maxtickLabelLen = 0;            # The length of the longest tick label.

    # Find the datatset minimum and maximum.
    ( $d_min, $d_max ) = $self->_find_y_range();

    # Force the inclusion of zero if the user has requested it.
    if ( $self->true( $self->{'include_zero'} ) )
    {
        if ( ( $d_min * $d_max ) > 0 )    # If both are non zero and of the same sign.
        {
            if ( $d_min > 0 )             # If the whole scale is positive.
            {
                $d_min = 0;
            }
            else                          # The scale is entirely negative.
            {
                $d_max = 0;
            }
        }
    }

    if ( $self->{'integer_ticks_only'} =~ /^\d$/ )
    {
        if ( $self->{'integer_ticks_only'} == 1 )
        {
            $self->{'integer_ticks_only'} = 'true';
        }
        else
        {
            $self->{'integer_ticks_only'} = 'false';
        }
    }
    if ( $self->true( $self->{'integer_ticks_only'} ) )
    {

        # Allow the dataset range to be overidden by the user.
        # f_min/max are booleans which indicate that the min & max should not be modified.
        my $f_min = defined $self->{'min_val'};
        $d_min = $self->{'min_val'} if $f_min;

        my $f_max = defined $self->{'max_val'};
        $d_max = $self->{'max_val'} if $f_max;

        # Assert against the min is larger than the max.
        if ( $d_min > $d_max )
        {
            croak "The the specified 'min_val' & 'max_val' values are reversed (min > max: $d_min>$d_max)";
        }

        # The user asked for integer ticks, force the limits to integers.
        # & work out the range directly.
        $p_min = $self->_round2Tick( $d_min, 1, -1 );
        $p_max = $self->_round2Tick( $d_max, 1, 1 );

        my $skip = $self->{skip_int_ticks};

        $tickInterval = $skip;
        $tickCount    = ( $p_max - $p_min ) / $skip + 1;

        # Now sort out an array of tick labels.

        for ( my $labelNum = $p_min ; $labelNum <= $p_max ; $labelNum += $tickInterval )
        {
            my $labelText;

            if ( defined $self->{f_x_tick} )
            {

                # Is _default_f_tick function used?
                if ( $self->{f_x_tick} == \&_default_f_tick )
                {
                    $labelText = sprintf( "%d", $labelNum );
                }
                else
                {
                    $labelText = $self->{f_x_tick}->($labelNum);
                }
            }

            else
            {
                $labelText = sprintf( "%d", $labelNum );
            }

            #print "labelText = $labelText\n";
            push @tickLabels, $labelText;
            $maxtickLabelLen = length $labelText if $maxtickLabelLen < length $labelText;
        }

    }
    else
    {

        # Allow the dataset range to be overidden by the user.
        # f_min/max are booleans which indicate that the min & max should not be modified.
        my $f_min = defined $self->{'min_val'};
        $d_min = $self->{'min_val'} if $f_min;

        my $f_max = defined $self->{'max_val'};
        $d_max = $self->{'max_val'} if $f_max;

        # Assert against the min is larger than the max.
        if ( $d_min > $d_max )
        {
            croak "The the specified 'min_val' & 'max_val' values are reversed (min > max: $d_min>$d_max)";
        }

        # Calculate the width of the dataset. (posibly modified by the user)
        my $d_width = $d_max - $d_min;

        # If the width of the range is zero, forcibly widen it
        # (to avoid division by zero errors elsewhere in the code).
        if ( 0 == $d_width )
        {
            $d_min--;
            $d_max++;
            $d_width = 2;
        }

        # Descale the range by converting the dataset width into
        # a floating point exponent & mantisa pair.
        my ( $rangeExponent, $rangeMantisa ) = $self->_sepFP($d_width);
        my $rangeMuliplier = 10**$rangeExponent;

        # Find what tick
        # to use & how many ticks to plot,
        # round the plot min & max to suatable round numbers.
        ( $tickInterval, $tickCount, $p_min, $p_max ) = $self->_calcTickInterval(
            $d_min / $rangeMuliplier,
            $d_max / $rangeMuliplier,
            $f_min, $f_max,
            $self->{'min_y_ticks'},
            $self->{'max_y_ticks'}
        );

        # Restore the tickInterval etc to the correct scale
        $_ *= $rangeMuliplier foreach ( $tickInterval, $p_min, $p_max );

        #get teh precision for the labels
        my $precision = $self->{'precision'};

        # Now sort out an array of tick labels.
        for ( my $labelNum = $p_min ; $labelNum <= $p_max ; $labelNum += $tickInterval )
        {
            my $labelText;

            if ( defined $self->{f_x_tick} )
            {

                # Is _default_f_tick function used?
                if ( $self->{f_x_tick} == \&_default_f_tick )
                {
                    $labelText = sprintf( "%." . $precision . "f", $labelNum );
                }
                else
                {
                    $labelText = $self->{f_x_tick}->($labelNum);
                }
            }
            else
            {
                $labelText = sprintf( "%." . $precision . "f", $labelNum );
            }

            #print "labelText = $labelText\n";
            push @tickLabels, $labelText;
            $maxtickLabelLen = length $labelText if $maxtickLabelLen < length $labelText;
        }
    }

    # Store the calculated data.
    $self->{'min_val'}             = $p_min;
    $self->{'max_val'}             = $p_max;
    $self->{'y_ticks'}             = $tickCount;
    $self->{'y_tick_labels'}       = \@tickLabels;
    $self->{'y_tick_label_length'} = $maxtickLabelLen;

    # and return.
    return 1;
}

## @fn private _draw_data
# finally get around to plotting the data for (horizontal) bars
sub _draw_data
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $x1, $x2, $x3, $y1, $y2, $y3 );
    my $cut = 0;
    my ( $width, $height, $delta1, $delta2, $map, $mod, $pink );
    my ( $i, $j, $color );

    # init the imagemap data field if they wanted it
    if ( $self->true( $self->{'imagemap'} ) )
    {
        $self->{'imagemap_data'} = [];
    }

    # find both delta values ($delta1 for stepping between different
    # datapoint names, $delta2 for setpping between datasets for that
    # point) and the mapping constant
    $width  = $self->{'curr_x_max'} - $self->{'curr_x_min'};
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $delta1 = $height / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
    $map    = $width / ( $self->{'max_val'} - $self->{'min_val'} );
    if ( $self->true( $self->{'spaced_bars'} ) )
    {
        $delta2 = $delta1 / ( $self->{'num_datasets'} + 2 );
    }
    else
    {
        $delta2 = $delta1 / $self->{'num_datasets'};
    }

    # get the base x-y values
    $y1 = $self->{'curr_y_max'} - $delta2;
    if ( $self->{'min_val'} >= 0 )
    {
        $x1  = $self->{'curr_x_min'};
        $mod = $self->{'min_val'};
    }
    elsif ( $self->{'max_val'} <= 0 )
    {
        $x1  = $self->{'curr_x_max'};
        $mod = $self->{'max_val'};
    }
    else
    {
        $x1  = $self->{'curr_x_min'} + abs( $map * $self->{'min_val'} );
        $mod = 0;
        $self->{'gd_obj'}->line( $x1, $self->{'curr_y_min'}, $x1, $self->{'curr_y_max'}, $misccolor );
    }

    # draw the bars
    for $i ( 1 .. $self->{'num_datasets'} )
    {

        # get the color for this dataset
        $color = $self->_color_role_to_index( 'dataset' . ( $i - 1 ) );

        # draw every bar for this dataset
        for $j ( 0 .. $self->{'num_datapoints'} )
        {

            # don't try to draw anything if there's no data
            if ( defined( $data->[$i][$j] ) )
            {

                # find the bounds of the rectangle
                if ( $self->true( $self->{'spaced_bars'} ) )
                {
                    $y2 = $y1 - ( $j * $delta1 ) - ( $self->{'num_datasets'} * $delta2 ) + ( ( $i - 1 ) * $delta2 );
                }
                else
                {
                    $y2 = $y1 - ( $j * $delta1 ) - ( $self->{'num_datasets'} * $delta2 ) + ( ($i) * $delta2 );
                }
                $x2 = $x1;
                $y3 = $y2 + $delta2;

                #cut the bars off, if needed
                if ( $data->[$i][$j] > $self->{'max_val'} )
                {
                    $x3 = $x1 + ( ( $self->{'max_val'} - $mod ) * $map ) - 1;
                    $cut = 1;
                }
                elsif ( $data->[$i][$j] < $self->{'min_val'} )
                {
                    $x3 = $x1 + ( ( $self->{'min_val'} - $mod ) * $map ) + 1;
                    $cut = 1;
                }
                else
                {
                    $x3 = $x1 + ( ( $data->[$i][$j] - $mod ) * $map );
                    $cut = 0;
                }

                # draw the bar
                ## y2 and y3 are reversed in some cases because GD's fill
                ## algorithm is lame
                if ( $data->[$i][$j] < 0 )
                {
                    $self->{'gd_obj'}->filledRectangle( $x3, $y2, $x2, $y3, $color );
                    if ( $self->true( $self->{'imagemap'} ) )
                    {
                        $self->{'imagemap_data'}->[$i][$j] = [ $x3, $y2, $x2, $y3 ];
                    }

                    $self->{'gd_obj'}->filledRectangle( $x3, $y2, $x2, $y3, $color );
                    if ( $self->true( $self->{'imagemap'} ) )
                    {
                        $self->{'imagemap_data'}->[$i][$j] = [ $x3, $y2, $x2, $y3 ];
                    }
                }
                else
                {
                    $self->{'gd_obj'}->filledRectangle( $x2, $y2, $x3, $y3, $color );
                    if ( $self->true( $self->{'imagemap'} ) )
                    {
                        $self->{'imagemap_data'}->[$i][$j] = [ $x2, $y2, $x3, $y3 ];
                    }
                }

                # now outline it. outline red if the bar had been cut off
                unless ($cut)
                {
                    $self->{'gd_obj'}->rectangle( $x2, $y3, $x3, $y2, $misccolor );
                }
                else
                {
                    $pink = $self->{'gd_obj'}->colorAllocate( 255, 0, 255 );
                    $self->{'gd_obj'}->rectangle( $x2, $y3, $x3, $y2, $pink );
                }

            }
            else
            {
                if ( $self->true( $self->{'imagemap'} ) )
                {
                    $self->{'imagemap_data'}->[$i][$j] = [ undef(), undef(), undef(), undef() ];
                }
            }
        }
    }

    # and finaly box it off
    $self->{'gd_obj'}
      ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );
    return;

}

## be a good module and return 1
1;
