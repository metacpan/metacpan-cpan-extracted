## @file
# Implementation of Chart::Pareto
#
# written and maintained by
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

## @class Chart::Pareto
# @brief Pareto class derived class for Chart to implement
#
package Chart::Pareto;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::Pareto::ISA     = qw(Chart::Base);
$Chart::Pareto::VERSION = '2.4.10';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private _find_y_scale
#calculate the range with the sum dataset1. all datas has to be positiv
sub _find_y_range
{
    my $self = shift;
    my $data = $self->{'dataref'};
    my $sum  = 0;

    for ( my $i = 0 ; $i < $self->{'num_datapoints'} ; $i++ )
    {
        if ( $data->[1][$i] >= 0 )
        {
            $sum += $data->[1][$i];
        }
        else
        {
            carp "We need positiv data, if we want to draw a pareto graph!!";
            return 0;
        }
    }

    #store the sum
    $self->{'sum'} = $sum;

    #return the range
    ( 0, $sum );
}

## @fn private _sort_data
# sort the data
sub _sort_data
{
    my $self   = shift;
    my $data   = $self->{'dataref'};
    my @labels = @{ $data->[0] };
    my @values = @{ $data->[1] };

    # sort the values and their labels
    @labels = @labels[ sort { $values[$b] <=> $values[$a] } 0 .. $#labels ];
    @values = sort { $b <=> $a } @values;

    #save the sorted values and their labels
    @{ $data->[0] } = @labels;
    @{ $data->[1] } = @values;

    #finally return
    return 1;
}

## @fn private _draw_legend
#  let them know what all the pretty colors mean
sub _draw_legend
{
    my $self = shift;
    my ($length);
    my $num_dataset;

    # check to see if legend type is none..
    if ( $self->{'legend'} =~ /^none$/ )
    {
        return 1;
    }

    # check to see if they have as many labels as datasets,
    # warn them if not
    if (   ( $#{ $self->{'legend_labels'} } >= 0 )
        && ( ( scalar( @{ $self->{'legend_labels'} } ) ) != 2 ) )
    {
        carp "I need two legend labels. One for the data and one for the sum.";
    }

    # init a field to store the length of the longest legend label
    unless ( $self->{'max_legend_label'} )
    {
        $self->{'max_legend_label'} = 0;
    }

    # fill in the legend labels, find the longest one
    unless ( $self->{'legend_labels'}[0] )
    {
        $self->{'legend_labels'}[0] = "Dataset";
    }
    unless ( $self->{'legend_labels'}[1] )
    {
        $self->{'legend_labels'}[1] = "Running sum";
    }

    if ( length( $self->{'legend_labels'}[0] ) > length( $self->{'legend_labels'}[1] ) )
    {
        $self->{'max_legend_label'} = length( $self->{'legend_labels'}[0] );
    }
    else
    {
        $self->{'max_legend_label'} = length( $self->{'legend_labels'}[1] );
    }

    #set the number of datasets to 2, and store it
    $num_dataset = $self->{'num_datasets'};
    $self->{'num_datasets'} = 2;

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

    #reload the number of datasets
    $self->{'num_datasets'} = $num_dataset;

    # and return
    return 1;
}

## @fn private _draw_data
# finally get around to plotting the data
sub _draw_data
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $x1, $x2, $x3, $y1, $y2, $y3, $y1_line, $y2_line, $x1_line, $x2_line, $h, $w );
    my ( $width, $height, $delta1, $delta2,     $map,     $mod,       $cut );
    my ( $i,     $j,      $color,  $line_color, $percent, $per_label, $per_label_len );
    my $sum      = $self->{'sum'};
    my $curr_sum = 0;
    my $font     = $self->{'legend_font'};
    my $pink     = $self->{'gd_obj'}->colorAllocate( 255, 0, 255 );
    my $diff;

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

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
    $delta1 = $width / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
    $diff   = ( $self->{'max_val'} - $self->{'min_val'} );
    $diff   = 1 if $diff == 0;
    $map    = $height / $diff;
    if ( $self->true( $self->{'spaced_bars'} ) )
    {
        $delta2 = $delta1 / 3;
    }
    else
    {
        $delta2 = $delta1;
    }

    # get the base x-y values
    $x1      = $self->{'curr_x_min'};
    $y1      = $self->{'curr_y_max'};
    $y1_line = $y1;
    $mod     = $self->{'min_val'};
    $x1_line = $self->{'curr_x_min'};

    # draw the bars and the lines
    $color      = $self->_color_role_to_index('dataset0');
    $line_color = $self->_color_role_to_index('dataset1');

    # draw every bar for this dataset
    for $j ( 0 .. $self->{'num_datapoints'} )
    {

        # don't try to draw anything if there's no data
        if ( defined( $data->[1][$j] ) )
        {

            #calculate the percent value for this data and the actual sum;
            $curr_sum += $data->[1][$j];
            $percent = int( $curr_sum / ( $sum || 1 ) * 100 );

            # find the bounds of the rectangle
            if ( $self->true( $self->{'spaced_bars'} ) )
            {
                $x2 = $x1 + ( $j * $delta1 ) + $delta2;
            }
            else
            {
                $x2 = $x1 + ( $j * $delta1 );
            }
            $y2 = $y1;
            $x3 = $x2 + $delta2;
            $y3 = $y1 - ( ( $data->[1][$j] - $mod ) * $map );

            #cut the bars off, if needed
            if ( $data->[1][$j] > $self->{'max_val'} )
            {
                $y3 = $y1 - ( ( $self->{'max_val'} - $mod ) * $map );
                $cut = 1;
            }
            elsif ( $data->[1][$j] < $self->{'min_val'} )
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
            $self->{'gd_obj'}->filledRectangle( $x2, $y3, $x3, $y2, $color );
            if ( $self->true( $self->{'imagemap'} ) )
            {
                $self->{'imagemap_data'}->[1][$j] = [ $x2, $y3, $x3, $y2 ];
            }

            # now outline it. outline red if the bar had been cut off
            unless ($cut)
            {
                $self->{'gd_obj'}->rectangle( $x2, $y3, $x3, $y2, $misccolor );
            }
            else
            {

                $self->{'gd_obj'}->rectangle( $x2, $y3, $x3, $y2, $pink );
            }
            $x2_line = $x3;
            if ( $self->{'max_val'} >= $curr_sum )
            {

                #get the y value
                $y2_line = $y1 - ( ( $curr_sum - $mod ) * $map );

                #draw the line
                $self->{'gd_obj'}->line( $x1_line, $y1_line, $x2_line, $y2_line, $line_color );

                #draw a little rectangle at the end of the line
                $self->{'gd_obj'}->filledRectangle( $x2_line - 2, $y2_line - 2, $x2_line + 2, $y2_line + 2, $line_color );

                #draw the label for the percent value
                $per_label     = $percent . '%';
                $per_label_len = length($per_label) * $w;
                $self->{'gd_obj'}->string( $font, $x2_line - $per_label_len - 1, $y2_line - $h - 1, $per_label, $line_color );

                #update the values for next the line
                $y1_line = $y2_line;
                $x1_line = $x2_line;
            }
            else
            {

                #get the y value
                $y2_line = $y1 - ( ( $self->{'max_val'} - $mod ) * $map );

                #draw the line
                $self->{'gd_obj'}->line( $x1_line, $y1_line, $x2_line, $y2_line, $pink );

                #draw a little rectangle at the end of the line
                $self->{'gd_obj'}->filledRectangle( $x2_line - 2, $y2_line - 2, $x2_line + 2, $y2_line + 2, $pink );

                #draw the label for the percent value
                $per_label     = $percent . '%';
                $per_label_len = length($per_label) * $w;
                $self->{'gd_obj'}->string( $font, $x2_line - $per_label_len - 1, $y2_line - $h - 1, $per_label, $pink );

                #update the values for the next line
                $y1_line = $y2_line;
                $x1_line = $x2_line;
            }

        }
        else
        {
            if ( $self->true( $self->{'imagemap'} ) )
            {
                $self->{'imagemap_data'}->[1][$j] = [ undef(), undef(), undef(), undef() ];
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
