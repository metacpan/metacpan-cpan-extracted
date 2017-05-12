## @file
# Implementation of Chart::Pie
#
# written and maintained by
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

## @class Chart::Pie
# @brief Pie class derived class for Chart to implement pies
#
package Chart::Pie;

use Chart::Base '2.4.10';
use GD;
use Carp;
use Chart::Constants;
use strict;

@Chart::Pie::ISA     = qw(Chart::Base);
$Chart::Pie::VERSION = '2.4.10';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private _draw_data
# @brief
# finally get around to plotting the data
#
# @details
# The user may define the kind of labelling the data by setting\n
# 'label_values' to 'percent' if she wants to have the percentages\n
# 'label_values' to 'values' if she wants to have the absolut values\n
# 'label_values' to 'both' if she wants to have absolut values and percentages\n
# 'label_values' to 'none' if she wants to have neither absolute values nor percentages\n
# 'ring' to a number less then 1 to define a ring as output;
#                      if 'ring' is 1 ore greater a full pie is plotted\n
#
sub _draw_data
{
    my $self       = shift;
    my $data       = $self->{'dataref'};
    my $misccolor  = $self->_color_role_to_index('misc');
    my $textcolor  = $self->_color_role_to_index('text');
    my $background = $self->_color_role_to_index('background');
    my ( $width, $height, $centerX, $centerY, $diameter, $diameter_previous, $text_diameter );
    my $dataset_sum;
    my ( $start_degrees, $end_degrees, $label_degrees, $label_old_degrees, $labelY_repeat_count );
    my ( $pi,            $rd2dg,       $dg2rd );
    my ( $font,          $fontW,       $fontH,         $labelX,            $labelY );
    my $label;
    my ( $i, $j, $color );
    my $label_length = 0;
    my $degrees      = 0;
    my $insidecolor;
    my $forbidden_degrees = 0;    # last occupied degree
    my %labelinfo;
    my $max_val_len   = 0;
    my $max_label_len = 0;

    # set up initial constant values
    $pi = Chart::Constants::PI;

    $dg2rd         = $pi / 180;                        # Degree to Radians
    $rd2dg         = 180 / $pi;                        # Radian to Degree
    $start_degrees = 0;
    $end_degrees   = 0;
    $font          = $self->{'legend_font'};
    $fontW         = $self->{'legend_font'}->width;
    $fontH         = $self->{'legend_font'}->height;
    $label_degrees = $labelY_repeat_count = 0;

    # init the imagemap data field if they wanted it
    if ( $self->true( $self->{'imagemap'} ) )
    {
        $self->{'imagemap_data'} = [];
    }

    # find width and height of the plotting area
    $width  = $self->{'curr_x_max'} - $self->{'curr_x_min'};
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};

    # okay, add up all the numbers of all the datasets, to get the
    # sum total. This will be used to determine the percentage
    # of each dataset. Obviously, negative numbers might be bad :)
    $dataset_sum = 0;
    for $j ( 0 .. $self->{'num_datapoints'} )
    {

        if ( defined $data->[1][$j] && $data->[1][$j] > 0 )
        {

            #add to sum
            $dataset_sum += $data->[1][$j];

            #don't allow negativ values
            if ( $data->[1][$j] < 0 )
            {
                croak "We need positiv data for a pie chart (which is not true for data[$j])!";
            }
        }
    }

    # find the longest label
    # first we need the length of the values
    $max_label_len = 1;
    for $j ( 0 .. ( $self->{'num_datapoints'} - 1 ) )
    {

        # don't try to draw anything if there's no data
        $labelinfo{$j}{data} = 'undefined';
        if ( defined( $data->[1][$j] ) && $data->[1][$j] > 0 )
        {
            $labelinfo{$j}{data}      = $data->[1][$j];
            $label                    = $data->[0][$j];
            $labelinfo{$j}{labeldata} = $label;

            if ( defined $self->{'label_values'} )
            {
                if ( $self->{'label_values'} =~ /^percent$/i )
                {
                    $label = sprintf( "%s %4.2f%%", $label, $data->[1][$j] / ( $dataset_sum || 1 ) * 100 );
                }
                elsif ( $self->{'label_values'} =~ /^value$/i )
                {
                    if ( $data->[1][$j] =~ /\./ )
                    {
                        $label = sprintf( "%s %.2f", $label, $data->[1][$j] );
                    }
                    else
                    {
                        $label = sprintf( "%s %d", $label, $data->[1][$j] );
                    }
                }
                elsif ( $self->{'label_values'} =~ /^both$/i )
                {
                    if ( $data->[1][$j] =~ /\./ )
                    {
                        $label =
                          sprintf( "%s %4.2f%% %.2f", $label, $data->[1][$j] / ( $dataset_sum || 1 ) * 100, $data->[1][$j] );
                    }
                    else
                    {
                        $label =
                          sprintf( "%s %4.2f%% %d", $label, $data->[1][$j] / ( $dataset_sum || 1 ) * 100, $data->[1][$j] );
                    }
                }
                elsif ( $self->{'label_values'} =~ /^none$/i )
                {
                    $label = sprintf( "%s", $label );
                }
            }
            $label_length = length($label);
            $labelinfo{$j}{labelstring} = $label, $labelinfo{$j}{labellength} = $label_length;

        }
        $max_label_len = $label_length if ( $max_label_len < $label_length );
    }
    $max_label_len *= $fontW;

    # find center point, from which the pie will be drawn around
    $centerX = int( $width / 2 ) + $self->{'curr_x_min'};
    $centerY = int( $height / 2 ) + $self->{'curr_y_min'};

    # @details
    # always draw a circle, which means the diameter will be the smaller
    # of the width and height. let enough space for the labels.\n
    # Calculate the space needed for the labels by taking
    # into account the angles where the labels will be plotted

    my $labeldistance = 2 * $self->maximum( $fontW, $fontH );

    $start_degrees = 0;
    $end_degrees   = 0;
    my $max_radius = $self->minimum( $width, $height ) / 2;
    my $radius = $max_radius;

    for $j ( 0 .. ( $self->{'num_datapoints'} - 1 ) )
    {

        # So, get the degree offset for this dataset
        $end_degrees = $start_degrees + ( $data->[1][$j] / ( $dataset_sum || 1 ) * 360 );

        $degrees = $start_degrees + ( $end_degrees - $start_degrees ) / 2;

        # stick the label in the middle of the slice
        $label_degrees = ( $start_degrees + $end_degrees ) / 2;

        #print "Vor Modulo: label_degrees = $label_degrees\n";
        $label_degrees = $self->modulo( $label_degrees, 360.0 );

        #print "Nach Modulo: label_degrees = $label_degrees\n";

        $label = $labelinfo{$j}{labelstring};
        $label_length = $labelinfo{$j}{labellength} || 0;

        #!!DEBUG!!!!
        #print "Text=".$label.", StartDegrees=".$start_degrees.
        #      ", end=".$end_degrees.
        #      ", label_degree=".$label_degrees."\n";

        #   0 degrees means east
        #  90 degrees means south
        # 180 degrees means west
        # 270 degrees means north
        # 360 degrees means east again
        if (   ( $label_degrees >= 270 && $label_degrees <= 360 )
            || ( $label_degrees >= 0 && $label_degrees <= 90 ) )
        {

            # right side of the circle
            {

                # $x value in respect of label arc
                my $x = $radius * sin( $dg2rd * $label_degrees );
                my $y = $radius * cos( $dg2rd * $label_degrees );

                #!!DEBUG!!!!
                #print "Text=".$label.": x=$x, y=$y\n";

                # i.e. the startpoint is at $centerX+$x, $centerY-$y
                #test
                #$self->{'gd_obj'}->rectangle( $centerX, $centerY, $centerX+$x, $centerY-$y, $misccolor );

                # theoretical right value in respect to radius and length of label
                my $right_pos = $centerX + $x + $label_length * $fontW;
                if ( $right_pos > $self->{'curr_x_max'} )
                {

                    # too far right, correct x
                    $right_pos = $self->{'curr_x_max'};
                    $x         = $right_pos - $centerX - $label_length * $fontW;

                    #!!DEBUG!!!!
                    #print "too far right: Text=".$label.": x=$x, y=$y\n";
                }

                # theoretical top position in respect to radius and height of label
                # (Remark: direction to the top of the picture counts backwards!)
                my $top_pos = $centerY - $y - $fontH;
                if ( $top_pos < $self->{'curr_y_min'} )
                {

                    # too far up, correct $y
                    $top_pos = $self->{'curr_y_min'};
                    $y       = $centerY - $top_pos - $fontH;

                    #!!DEBUG!!!!
                    #print "too far up: Text=".$label.": x=$x, y=$y\n";
                }

                my $down_pos = $centerY + $y + $fontH;
                if ( $down_pos > $self->{'curr_y_max'} )
                {
                    $down_pos = $self->{'curr_y_max'};
                    $y        = $down_pos - $centerY - $fontH;

                    #!!DEBUG!!!!
                    #print "too far down: Text=".$label.": x=$x, y=$y\n";
                }

  #test
  #$self->{'gd_obj'}->rectangle( $centerX+$x, $centerY-$y, $right_pos, $top_pos, $textcolor );
  #$self->{'gd_obj'}
  #       ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );
  #return;

#!!DEBUG!!!!
#print "before Line 270: label_degrees=$label_degrees, cos()=".  cos( $dg2rd * $label_degrees ). ", sin()=". sin( $dg2rd * $label_degrees )."\n";
                if ( $label_degrees == 0 )
                {
                    $radius = $self->minimum( $radius, abs( $y / cos( $dg2rd * $label_degrees ) ) );
                }
                else
                {
                    $radius =
                      $self->minimum( $radius, $x / sin( $dg2rd * $label_degrees ),
                        abs( $y / cos( $dg2rd * $label_degrees ) ) );
                }
                $radius = int( $radius + 0.5 );

                #!!DEBUG!!
                #$self->{'gd_obj'}->line( $centerX, $centerY, $centerX+$radius, $centerY, gdBrushed );

            }
            if ( $radius <= 0 ) { croak "radius < 0!"; }
        }
        else
        {    # left side of the circle
                # as 0 degrees means east

            if ( abs($label_degrees) < 0.1 )
            {

                # too small angle
                $radius = $self->{'curr_x_max'} - $label_length * $fontW;
            }
            else
            {

                # $x value in respect of label arc
                my $x = $radius * sin( $dg2rd * $label_degrees );
                my $y = $radius * cos( $dg2rd * $label_degrees );

                # i.e. the startpoint is at $centerX-$x, $centerY+$y
                #test
                #$self->{'gd_obj'}->rectangle( $centerX, $centerY, $centerX-$x, $centerY+$y, $misccolor );

                # theoretical right value in respect to radius and length of label
                my $left_pos = $centerX - $x - $label_length * $fontW;
                if ( $left_pos < $self->{'curr_x_min'} )
                {

                    # too far right, correct x
                    $left_pos = $self->{'curr_x_min'};
                    $x        = $centerX - $left_pos - $label_length * $fontW;
                }

                # theoretical top position in respect to radius and height of label
                # (Remark: direction to the top of the picture counts backwards!)
                my $top_pos = $centerY + $y - $fontH;
                if ( $top_pos < $self->{'curr_y_min'} )
                {

                    # too far up, correct $y
                    $top_pos = $self->{'curr_y_min'};
                    $y       = $centerY - $top_pos - $fontH;
                }

                my $down_pos = $centerY - $y + $fontH;
                if ( $down_pos > $self->{'curr_y_max'} )
                {
                    $down_pos = $self->{'curr_y_max'};
                    $y        = $centerY + $fontH - $down_pos;
                }

  #test
  #$self->{'gd_obj'}->rectangle( $centerX-$x, $centerY+$y, $left_pos, $top_pos, $textcolor );
  #$self->{'gd_obj'}
  #       ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );
  #return;

                $radius =
                  $self->minimum( $radius, $x / sin( $dg2rd * $label_degrees ), abs( $y / cos( $dg2rd * $label_degrees ) ) );
                $radius = int( $radius + 0.5 );

                #test
                #$self->{'gd_obj'}->line( $centerX, $centerY, $centerX+$radius, $centerY, gdBrushed );

            }
            if ( $radius <= 0 ) { croak "radius < 0!"; }
        }

        # reset starting point for next dataset and continue.
        $start_degrees = $end_degrees;

    }
    $diameter = $radius * 2 - 2 * $labeldistance;

    $text_diameter = $diameter + $labeldistance;
    $self->{'gd_obj'}->arc( $centerX, $centerY, $diameter, $diameter, 0, 360, $misccolor );

    # for DEBUG!!
    #$self->{'gd_obj'}->arc($centerX, $centerY, $text_diameter, $text_diameter,
    #                           0, 360, $misccolor);

    # for DEBUG!!
    #print "-------------------------------------------\n";

    # @details
    # Plot the pies
    $start_degrees = 0;
    $end_degrees   = 0;
    for $j ( 0 .. ( $self->{'num_datapoints'} - 1 ) )
    {

        next if $labelinfo{$j}{data} eq 'undefined';

        # get the color for this datapoint, take the color of the datasets
        $color = $self->_color_role_to_index( 'dataset' . $j );

        $label        = $labelinfo{$j}{labelstring};
        $label_length = $labelinfo{$j}{labellength};

        # The first value starts at 0 degrees, each additional dataset
        # stops where the previous left off, and since I've already
        # calculated the sum_total for the whole graph, I know that
        # the final pie slice will end at 360 degrees.

        # So, get the degree offset for this dataset
        $end_degrees = $start_degrees + ( $data->[1][$j] / ( $dataset_sum || 1 ) * 360 );

        $degrees = ( $start_degrees + $end_degrees ) / 2;

        # stick the label in the middle of the slice
        $label_degrees = $degrees;
        $label_degrees = $self->modulo( $label_degrees, 360.0 );

        if ( $start_degrees < $end_degrees )
        {

     # draw filled Arc
     # test
     #print "centerX=$centerX, centerY=$centerY, diameter=$diameter, $start_degrees, ".int($start_degrees) . ", $end_degrees\n";
     #$self->{'gd_obj'}->filledArc( $centerX, $centerY, $diameter, $diameter, $start_degrees, $end_degrees, $color );
            $self->{'gd_obj'}->filledArc(
                $centerX, $centerY, $diameter, $diameter,
                int( $start_degrees - 0.5 ),
                int( $end_degrees + 0.5 ), $color
            );
        }

        # Figure out where to place the label
        # $forbidden_degrees = angle of the center, representing the height of the label
        if ( $j == 0 )
        {
            $forbidden_degrees = $rd2dg * atan2( $fontH, 0.5 * $text_diameter );
            $label_old_degrees = 0;
        }
        else
        {
            my $winkel;
            my $h;

            if (   ( $label_old_degrees <= 90.0 && $label_degrees > 90.0 )
                || ( $label_old_degrees <= 270.0 && $label_degrees > 270.0 ) )
            {

                # at 90 degrees there the reference point to the text changes
                # from the beginning to the back
                $forbidden_degrees = 0;
            }
            $label_degrees = $self->maximum( $label_degrees, $forbidden_degrees );
            $label_old_degrees = $label_degrees;    # remember old label_degrees

            $winkel = cos( $label_degrees * $dg2rd );

            $winkel = abs($winkel);
            if ( abs($winkel) < 0.01 )
            {
                $h = 0;
            }
            else
            {
                $h = $fontH / $winkel;
            }

            my $atan = atan2( $h, 0.5 * $text_diameter );    #  -pi ... +pi

            $forbidden_degrees = $label_degrees + $rd2dg * $atan;

            # for debugging
            #printf("Index=%2d  winkel=%6.2f, H=%3d atan=%5.2f  label=%6.2f  forbidden=%6.2f\n",
            #       $j, $winkel*$dg2rd,$h, $atan*$rd2dg, $label_degrees,$forbidden_degrees);
            # end for debugging

        }
        $labelX = $centerX + $text_diameter * 0.5 * cos( $label_degrees * $dg2rd );
        $labelY = $centerY + $text_diameter * 0.5 * sin( $label_degrees * $dg2rd );

        #!!DEBUG!!!!
        #print "Text=".$label.": labelX=$labelX, y=$labelY\n";
        #        # For debugging
        #        # Draw Point
        #        # reset the brush for points
        #        my $brush = $self->_prepare_brush($color, 'point',
        #			$self->{'pointStyle' . '0'});
        #        $self->{'gd_obj'}->setBrush($brush);
        #
        #        # draw the point
        #        $self->{'gd_obj'}->line($labelX, $labelY, $labelX, $labelY, gdBrushed);
        #        # end for debugging

        # Okay, if a bunch of very small datasets are close together, they can
        # overwrite each other. The following if statement is to help keep
        # labels of neighbor datasets from being overlapped. It ain't perfect,
        # but it does a pretty good job.

        if (   ( $label_degrees >= 270 && $label_degrees <= 360 )
            || ( $label_degrees >= 0 && $label_degrees <= 90 ) )
        {

            # right side of the circle
            # as 0 degrees means east
            # $textcolor marks everything black
            $self->{'gd_obj'}->string( $font, $labelX, $labelY - $fontH * 0.5, $label, $textcolor );

        }
        else
        {

            # $textcolor marks everything black
            $self->{'gd_obj'}->string( $font, $labelX - length($label) * $fontW, $labelY - $fontH * 0.5, $label, $textcolor );
        }

        if ( $self->true( $self->{'legend_lines'} ) )
        {
            $self->{'gd_obj'}->line(
                $centerX + 0.5 * $diameter * cos( $degrees * $dg2rd ),
                $centerY + 0.5 * $diameter * sin( $degrees * $dg2rd ),
                $labelX, $labelY, $color
            );
        }

        # reset starting point for next dataset and continue.
        $start_degrees = $end_degrees;

    }    # end for $j

    # print "Center $centerX, $centerY\n";
    # print "Durchmesser $diameter\n";
    # print "Hintergrund $background\n";

    if ( defined( $self->{'ring'} ) && abs( $self->{'ring'} ) < 1 )
    {

        # print "bground $bground\n";
        my $hole = ( 1 - abs( $self->{'ring'} ) );
        if ( $self->true( $self->{'grey_background'} ) )
        {
            $insidecolor = $self->_color_role_to_index('grey_background');
        }
        else
        {
            $insidecolor = $background;
        }

        $self->{'gd_obj'}->filledArc( $centerX, $centerY, $hole * $diameter, $hole * $diameter, 0, 360, $insidecolor );

        $self->{'gd_obj'}->arc( $centerX, $centerY, $hole * $diameter, $hole * $diameter, 0, 360, $misccolor );

    }

    # and finaly box it off

    $self->{'gd_obj'}
      ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );
    return;

}

## @fn private _draw_right_legend
# Overwrite the legend methods to get the right legend
sub _draw_right_legend
{
    my $self   = shift;
    my $data   = $self->{'dataref'};
    my @labels = @{ $data->[0] };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush );
    my $font = $self->{'legend_font'};
    my $l1   = 0;
    my $l2   = 0;
    my ( $i, $j, $label, $dataset_sum );
    my $max_label_len = 1;

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get the miscellaneous color
    $misccolor = $self->_color_role_to_index('misc');

    #find out what the sum of all datapoits is, needed for the Labels with percent
    $dataset_sum = 0;
    for my $j ( 0 .. $self->{'num_datapoints'} )
    {
        if ( defined $data->[1][$j] )
        {
            $dataset_sum += $data->[1][$j];
        }
    }

    # find out how who wide the largest label text is
    foreach (@labels)
    {
        if ( length($_) > $l1 )
        {
            $l1 = length($_);
        }
    }
    for ( my $i = 0 ; $i < ( $self->{'num_datapoints'} ) ; $i++ )
    {
        if ( length( $data->[1][$i] ) > $l2 )
        {
            $l2 = length( $data->[1][$i] );
        }
    }

    if ( $self->{'legend_label_values'} =~ /^value$/i )
    {
        $max_label_len = $l1 + $l2 + 1;
    }
    elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
    {
        $max_label_len = $l1 + 7;
    }
    elsif ( $self->{'legend_label_values'} =~ /^both$/i )
    {
        $max_label_len = $l1 + $l2 + 9;
    }
    else
    {
        $max_label_len = $l1;
    }

    # find out how wide the largest label is
    $width = ( 2 * $self->{'text_space'} )

      #+ ($self->{'max_legend_label'} * $w)
      + $max_label_len * $w + $self->{'legend_example_size'} + ( 2 * $self->{'legend_space'} );

    # get some starting x-y values
    $x1 = $self->{'curr_x_max'} - $width;
    $x2 = $self->{'curr_x_max'};
    $y1 = $self->{'curr_y_min'} + $self->{'graph_border'};
    $y2 =
      $self->{'curr_y_min'} +
      $self->{'graph_border'} +
      $self->{'text_space'} +
      ( $self->{'num_datapoints'} * ( $h + $self->{'text_space'} ) ) +
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
        $color = $self->_color_role_to_index( 'dataset' . $_ );

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
        if ( defined $data->[1][$_] )
        {
            if ( $self->{'legend_label_values'} =~ /^value$/i )
            {
                $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_] . ' ' . $data->[1][$_], $color );
            }
            elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
            {
                $label = sprintf( "%s %4.2f%%", $labels[$_], $data->[1][$_] / ( $dataset_sum || 1 ) * 100 );
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $color );
            }
            elsif ( $self->{'legend_label_values'} =~ /^both$/i )
            {
                if ( $data->[1][$_] =~ /\./ )
                {
                    $label =
                      sprintf( "%s %4.2f%% %.2f", $labels[$_], $data->[1][$_] / ( $dataset_sum || 1 ) * 100, $data->[1][$_] );
                }
                else
                {
                    $label =
                      sprintf( "%s %4.2f%% %d", $labels[$_], $data->[1][$_] / ( $dataset_sum || 1 ) * 100, $data->[1][$_] );
                }
                $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $color );
            }
            else
            {
                $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
            }

        }
    }

    # mark off the used space
    $self->{'curr_x_max'} -= $width;

    # and return
    return 1;
}

## @fn private _draw_left_legend
# put the legend on the left of the chart
sub _draw_left_legend
{
    my $self = shift;

    my $data   = $self->{'dataref'};
    my @labels = @{ $data->[0] };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush );
    my $font          = $self->{'legend_font'};
    my $max_label_len = 1;
    my $l1            = 0;
    my $l2            = 0;
    my ( $dataset_sum, $label );

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get the miscellaneous color
    $misccolor = $self->_color_role_to_index('misc');

    #find out what the sum of all datapoits is, needed for the Labels with percent
    $dataset_sum = 0;
    for my $j ( 0 .. $self->{'num_datapoints'} )
    {
        if ( defined $data->[1][$j] )
        {
            $dataset_sum += $data->[1][$j];
        }
    }

    # find out how who wide the largest label text is
    foreach (@labels)
    {
        if ( length($_) > $l1 )
        {
            $l1 = length($_);
        }
    }
    for ( my $i = 0 ; $i < ( $self->{'num_datapoints'} ) ; $i++ )
    {
        if ( length( $data->[1][$i] ) > $l2 )
        {
            $l2 = length( $data->[1][$i] );
        }
    }

    if ( $self->{'legend_label_values'} =~ /^value$/i )
    {
        $max_label_len = $l1 + $l2 + 1;
    }
    elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
    {
        $max_label_len = $l1 + 7;
    }
    elsif ( $self->{'legend_label_values'} =~ /^both$/i )
    {
        $max_label_len = $l1 + $l2 + 9;
    }
    else
    {
        $max_label_len = $l1;
    }

    # find out how wide the largest label is
    $width =
      ( 2 * $self->{'text_space'} ) +
      ( $max_label_len * $w ) +
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
      ( $self->{'num_datapoints'} * ( $h + $self->{'text_space'} ) ) +
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
        $color = $self->_color_role_to_index( 'dataset' . $_ );

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
        if ( $self->{'legend_label_values'} =~ /^value$/i )
        {
            $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_] . ' ' . $data->[1][$_], $color );
        }
        elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
        {
            $label = sprintf( "%s %4.2f%%", $labels[$_], $data->[1][$_] / ( $dataset_sum || 1 ) * 100 );
            $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $color );
        }
        elsif ( $self->{'legend_label_values'} =~ /^both$/i )
        {
            if ( $data->[1][$_] =~ /\./ )
            {
                $label =
                  sprintf( "%s %4.2f%% %.2f", $labels[$_], $data->[1][$_] / ( $dataset_sum || 1 ) * 100, $data->[1][$_] );
            }
            else
            {
                $label = sprintf( "%s %4.2f%% %d", $labels[$_], $data->[1][$_] / ( $dataset_sum || 1 ) * 100, $data->[1][$_] );
            }
            $self->{'gd_obj'}->string( $font, $x2, $y2, $label, $color );
        }
        else
        {
            $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
        }

    }

    # mark off the used space
    $self->{'curr_x_min'} += $width;

    # and return
    return 1;
}

## @fn private _draw_bottom_legend
# put the legend on the bottom of the chart
sub _draw_bottom_legend
{
    my $self   = shift;
    my $data   = $self->{'dataref'};
    my @labels = @{ $data->[0] };
    my ( $x1, $y1, $x2, $x3, $y2, $empty_width, $max_label_width, $cols, $rows, $color, $brush );
    my ( $col_width, $row_height, $r, $c, $index, $x, $y, $w, $h );
    my $font = $self->{'legend_font'};
    my $max_label_len;
    my $l1 = 0;
    my $l2 = 0;
    my ( $dataset_sum, $j );
    my $label;

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # find the base x values
    $x1 = $self->{'curr_x_min'} + $self->{'graph_border'};

    # + ($self->{'y_tick_label_length'} * $self->{'tick_label_font'}->width)
    # + $self->{'tick_len'} + (3 * $self->{'text_space'});
    $x2 = $self->{'curr_x_max'} - $self->{'graph_border'};
    if ( $self->{'y_label'} )
    {
        $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }
    if ( $self->{'y_label2'} )
    {
        $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }

    #find out what the sum of all datapoits is, needed for the Labels with percent
    $dataset_sum = 0;
    for $j ( 0 .. $self->{'num_datapoints'} )
    {
        if ( defined $data->[1][$j] )
        {
            $dataset_sum += $data->[1][$j];
        }
    }

    # find out how who wide the largest label text is, especially look what kind of
    # label is needed
    foreach (@labels)
    {
        if ( length($_) > $l1 )
        {
            $l1 = length($_);
        }
    }
    for ( my $i = 0 ; $i < ( $self->{'num_datapoints'} ) ; $i++ )
    {
        if ( length( $data->[1][$i] ) > $l2 )
        {
            $l2 = length( $data->[1][$i] );
        }
    }

    if ( $self->{'legend_label_values'} =~ /^value$/i )
    {
        $max_label_len = $l1 + $l2 + 1;
    }
    elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
    {
        $max_label_len = $l1 + 7;
    }
    elsif ( $self->{'legend_label_values'} =~ /^both$/i )
    {
        $max_label_len = $l1 + $l2 + 9;
    }
    else
    {
        $max_label_len = $l1;
    }

    # figure out how wide the columns need to be, and how many we
    # can fit in the space available
    $empty_width = ( $x2 - $x1 ) - ( 2 * $self->{'legend_space'} );
    $max_label_width = $max_label_len * $w

      #$self->{'max_legend_label'} * $w
      + ( 4 * $self->{'text_space'} ) + $self->{'legend_example_size'};
    $cols = int( $empty_width / $max_label_width );
    unless ($cols)
    {
        $cols = 1;
    }
    $col_width = $empty_width / $cols;

    # figure out how many rows we need, remember how tall they are
    $rows = int( $self->{'num_datapoints'} / $cols );
    unless ( ( $self->{'num_datapoints'} % $cols ) == 0 )
    {
        $rows++;
    }
    unless ($rows)
    {
        $rows = 1;
    }
    $row_height = $h + $self->{'text_space'};

    # box the legend off
    $y1 = $self->{'curr_y_max'} - $self->{'text_space'} - ( $rows * $row_height ) - ( 2 * $self->{'legend_space'} );
    $y2 = $self->{'curr_y_max'};
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $self->_color_role_to_index('misc') );
    $x1 += $self->{'legend_space'} + $self->{'text_space'};
    $x2 -= $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};
    $y2 -= $self->{'legend_space'} + $self->{'text_space'};

    # draw in the actual legend
    for $r ( 0 .. $rows - 1 )
    {
        for $c ( 0 .. $cols - 1 )
        {
            $index = ( $r * $cols ) + $c;    # find the index in the label array
            if ( $labels[$index] )
            {

                # get the color
                $color = $self->_color_role_to_index( 'dataset' . $index );

                # get the x-y coordinate for the start of the example line
                $x = $x1 + ( $col_width * $c );
                $y = $y1 + ( $row_height * $r ) + $h / 2;

                # now draw the example line
                $self->{'gd_obj'}->line( $x, $y, $x + $self->{'legend_example_size'}, $y, $color );

                # reset the brush for points
                $brush = $self->_prepare_brush( $color, 'point', $self->{ 'pointStyle' . $index } );
                $self->{'gd_obj'}->setBrush($brush);

                # draw the point
                $x3 = int( $x + $self->{'legend_example_size'} / 2 );
                $self->{'gd_obj'}->line( $x3, $y, $x3, $y, gdBrushed );

                # adjust the x-y coordinates for the start of the label
                $x += $self->{'legend_example_size'} + ( 2 * $self->{'text_space'} );
                $y = $y1 + ( $row_height * $r );

                # now draw the label
                if ( $self->{'legend_label_values'} =~ /^value$/i )
                {
                    $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index] . ' ' . $data->[1][$index], $color );

         #$self->{'gd_obj'}->stringTTF($color, FONT, 10, 0, $x, $y+10, $labels[$index].' '.$data->[1][$index]);     ############
                }
                elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
                {
                    $label = sprintf( "%s %4.2f%%", $labels[$index], $data->[1][$index] / ( $dataset_sum || 1 ) * 100 );
                    $self->{'gd_obj'}->string( $font, $x, $y, $label, $color );
                }
                elsif ( $self->{'legend_label_values'} =~ /^both$/i )
                {
                    if ( $data->[1][$index] =~ /\./ )
                    {
                        $label = sprintf( "%s %4.2f%% %.2f",
                            $labels[$index],
                            $data->[1][$index] / ( $dataset_sum || 1 ) * 100,
                            $data->[1][$index] );
                    }
                    else
                    {
                        $label = sprintf( "%s %4.2f%% %d",
                            $labels[$index],
                            $data->[1][$index] / ( $dataset_sum || 1 ) * 100,
                            $data->[1][$index] );
                    }
                    $self->{'gd_obj'}->string( $font, $x, $y, $label, $color );    ###
                            # $self->{'gd_obj'}->stringTTF($color, FONT, 10, 0, $x, $y, $label);

                }
                else
                {
                    $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index], $color );
                }
            }
        }
    }

    # mark off the space used
    $self->{'curr_y_max'} -= ( $rows * $row_height ) + $self->{'text_space'} + ( 2 * $self->{'legend_space'} );

    # now return
    return 1;
}

## @fn private _draw_top_legend
# put the legend on top of the chart
sub _draw_top_legend
{
    my $self = shift;
    my $data = $self->{'dataref'};
    my ($max_label_len);
    my $l1     = 0;
    my $l2     = 0;
    my @labels = @{ $data->[0] };
    my ( $x1, $y1, $x2, $x3, $y2, $empty_width, $max_label_width, $cols, $rows, $color, $brush );
    my ( $col_width, $row_height, $r, $c, $index, $x, $y, $w, $h, $dataset_sum, $label );
    my $font = $self->{'legend_font'};

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    #find out what the sum of all datapoits is, needed for the Labels with percent
    $dataset_sum = 0;
    for my $j ( 0 .. $self->{'num_datapoints'} )
    {
        if ( defined $data->[1][$j] )
        {
            $dataset_sum += $data->[1][$j];
        }
    }

    # get some base x coordinates
    $x1 = $self->{'curr_x_min'} + $self->{'graph_border'};

    # + $self->{'y_tick_label_length'} * $self->{'tick_label_font'}->width
    # + $self->{'tick_len'} + (3 * $self->{'text_space'});
    $x2 = $self->{'curr_x_max'} - $self->{'graph_border'};
    if ( $self->{'y_label'} )
    {
        $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }
    if ( $self->{'y_label2'} )
    {
        $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }

    # find out how who wide the largest label text is
    foreach (@labels)
    {
        if ( length($_) > $l1 )
        {
            $l1 = length($_);
        }
    }
    for ( my $i = 0 ; $i < ( $self->{'num_datapoints'} ) ; $i++ )
    {
        if ( length( $data->[1][$i] ) > $l2 )
        {
            $l2 = length( $data->[1][$i] );
        }
    }

    if ( $self->{'legend_label_values'} =~ /^value$/i )
    {
        $max_label_len = $l1 + $l2 + 1;
    }
    elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
    {
        $max_label_len = $l1 + 7;
    }
    elsif ( $self->{'legend_label_values'} =~ /^both$/i )
    {
        $max_label_len = $l1 + $l2 + 9;
    }
    else
    {
        $max_label_len = $l1;
    }

    # figure out how wide the columns can be, and how many will fit
    $empty_width     = ( $x2 - $x1 ) - ( 2 * $self->{'legend_space'} );
    $max_label_width = ( 4 * $self->{'text_space'} ) + $max_label_len * $w + $self->{'legend_example_size'};
    $cols            = int( $empty_width / $max_label_width );

    unless ($cols)
    {
        $cols = 1;
    }
    $col_width = $empty_width / $cols;

    # figure out how many rows we need and remember how tall they are
    $rows = int( $self->{'num_datapoints'} / $cols );
    unless ( ( $self->{'num_datapoints'} % $cols ) == 0 )
    {
        $rows++;
    }
    unless ($rows)
    {
        $rows = 1;
    }
    $row_height = $h + $self->{'text_space'};

    # box the legend off
    $y1 = $self->{'curr_y_min'};
    $y2 = $self->{'curr_y_min'} + $self->{'text_space'} + ( $rows * $row_height ) + ( 2 * $self->{'legend_space'} );
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $self->_color_role_to_index('misc') );

    # leave some space inside the legend
    $x1 += $self->{'legend_space'} + $self->{'text_space'};
    $x2 -= $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};
    $y2 -= $self->{'legend_space'} + $self->{'text_space'};

    # draw in the actual legend
    for $r ( 0 .. $rows - 1 )
    {
        for $c ( 0 .. $cols - 1 )
        {
            $index = ( $r * $cols ) + $c;    # find the index in the label array
            if ( $labels[$index] )
            {

                # get the color
                $color = $self->_color_role_to_index( 'dataset' . $index );

                # find the x-y coords
                $x = $x1 + ( $col_width * $c );
                $y = $y1 + ( $row_height * $r ) + $h / 2;

                # draw the line first
                $self->{'gd_obj'}->line( $x, $y, $x + $self->{'legend_example_size'}, $y, $color );

                # reset the brush for points
                $brush = $self->_prepare_brush( $color, 'point', $self->{ 'pointStyle' . $index } );
                $self->{'gd_obj'}->setBrush($brush);

                # draw the point
                $x3 = int( $x + $self->{'legend_example_size'} / 2 );
                $self->{'gd_obj'}->line( $x3, $y, $x3, $y, gdBrushed );

                # now the label
                $x += $self->{'legend_example_size'} + ( 2 * $self->{'text_space'} );
                $y -= $h / 2;
                if ( $self->{'legend_label_values'} =~ /^value$/i )
                {
                    $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index] . ' ' . $data->[1][$index], $color );
                }
                elsif ( $self->{'legend_label_values'} =~ /^percent$/i )
                {
                    $label = sprintf( "%s %4.2f%%", $labels[$index], $data->[1][$index] / ( $dataset_sum || 1 ) * 100 );
                    $self->{'gd_obj'}->string( $font, $x, $y, $label, $color );
                }
                elsif ( $self->{'legend_label_values'} =~ /^both$/i )
                {
                    if ( $data->[1][$index] =~ /\./ )
                    {
                        $label = sprintf( "%s %4.2f%% %.2f",
                            $labels[$index],
                            $data->[1][$index] / ( $dataset_sum || 1 ) * 100,
                            $data->[1][$index] );
                    }
                    else
                    {
                        $label = sprintf( "%s %4.2f%% %d",
                            $labels[$index],
                            $data->[1][$index] / ( $dataset_sum || 1 ) * 100,
                            $data->[1][$index] );
                    }
                    $self->{'gd_obj'}->string( $font, $x, $y, $label, $color );
                }
                else
                {
                    $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index], $color );
                }
            }
        }
    }

    # mark off the space used
    $self->{'curr_y_min'} += ( $rows * $row_height ) + $self->{'text_space'} + 2 * $self->{'legend_space'};

    # now return
    return 1;
}

## @fn private _draw_x_ticks
# Override the ticks methods for the pie charts.\n
# Here: do nothing
sub _draw_x_ticks
{
    my $self = shift;

    return;
}

## @fn private _draw_y_ticks
# Override the ticks methods for the pie charts.\n
sub _draw_y_ticks
{
    my $self = shift;

    return;
}

## @fn private _find_y_scale
# Override the find_y_scale methods for the pie charts.\n
# Here: do nothing
sub _find_y_scale
{
    my $self = shift;

    return;
}

## be a good module and return 1
1;
