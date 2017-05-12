## @file
# Implementation of Chart::Composite
#
# written by
# @author david bonner (dbonner@cs.bu.edu)
#
# maintained by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#
#---------------------------------------------------------------------
# History:
#----------

## @class Chart::Composite
# Composite class derived from class Base.\n
# This class provides all functions which are specific to
# composite charts

package Chart::Composite;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::Composite::ISA     = qw(Chart::Base);
$Chart::Composite::VERSION = '2.4.10';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @method int set(%opts)
# @param[in] %opts Hash of options to the Chart
# @return ok or croak
#
# @brief
# Set all options
#
# @details
# Overwrite the set function of class Base to pass
# options to the sub-objects later
sub set
{
    my $self = shift;
    my %opts = @_;

    # basic error checking on the options, just warn 'em
    unless ( $#_ % 2 )
    {
        carp "Whoops, some option to be set didn't have a value.\n", "You might want to look at that.\n";
    }

    # store the options they gave us
    unless ( $self->{'opts'} )
    {
        $self->{'opts'} = {};
    }

    # now set 'em
    for ( keys %opts )
    {
        $self->{$_} = $opts{$_};
        $self->{'opts'}{$_} = $opts{$_};
    }

    # now return
    return;
}

## @fn imagemap_dump()
# @brief
# Overwrite function imagemap_dump of base class
#
# @details
# Get the information to turn the chart into an imagemap
# had to override it to reassemble the \@data array correctly
#
# @return Reference to an array of the image
sub imagemap_dump
{
    my $self = shift;
    my ( $i, $j );
    my @map;
    my $dataset_count = 0;

    # croak if they didn't ask me to remember the data, or if they're asking
    # for the data before I generate it
    unless ( ( $self->true( $self->{'imagemap'} ) ) && $self->{'imagemap_data'} )
    {
        croak "You need to set the imagemap option to true, and then call the png method, before you can get the imagemap data";
    }

    #make a copy of the imagemap data
    #this is the data of the first component
    for $i ( 1 .. $#{ $self->{'sub_0'}->{'imagemap_data'} } )
    {
        for $j ( 0 .. $#{ $self->{'sub_0'}->{'imagemap_data'}->[$i] } )
        {
            $map[$i][$j] = \@{ $self->{'sub_0'}->{'imagemap_data'}->[$i][$j] };
        }
        $dataset_count++;
    }

    #and add the data of the second component
    for $i ( 1 .. $#{ $self->{'sub_1'}->{'imagemap_data'} } )
    {
        for $j ( 0 .. $#{ $self->{'sub_1'}->{'imagemap_data'}->[$i] } )
        {
            $map[ $i + $dataset_count ][$j] = \@{ $self->{'sub_1'}->{'imagemap_data'}->[$i][$j] };
        }
    }

    # return their copy
    return \@map;

}

# private routine
sub __print_array
{
    my @a = @_;
    my $i;

    my $li = $#a;

    $li++;
    print STDERR "Anzahl der Elemente = $li\n";
    $li--;

    for ( $i = 0 ; $i <= $li ; $i++ )
    {
        print STDERR "\t$i\t$a[$i]\n";
    }
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private int _check_data
# Overwrite _check_data of Chart::Base and check the internal data to be displayed.
#
# Make sure the data isn't really weird
#  and collect some basic info about it\n
# @return status of check
sub _check_data
{
    my $self   = shift;
    my $length = 0;

    # first things first, make sure we got the composite_info
    unless ( ( $self->{'composite_info'} ) && ( $#{ $self->{'composite_info'} } == 1 ) )
    {
        croak "Chart::Composite needs to be told what kind of components to use";
    }

    # make sure we don't end up dividing by zero if they ask for
    # just one y_tick
    if ( $self->{'y_ticks'} == 1 )
    {
        $self->{'y_ticks'} = 2;
        carp "The number of y_ticks displayed must be at least 2";
    }

    # remember the number of datasets
    $self->{'num_datasets'} = $#{ $self->{'dataref'} };

    # remember the number of points in the largest dataset
    $self->{'num_datapoints'} = 0;
    for ( 0 .. $self->{'num_datasets'} )
    {
        if ( scalar( @{ $self->{'dataref'}[$_] } ) > $self->{'num_datapoints'} )
        {
            $self->{'num_datapoints'} = scalar( @{ $self->{'dataref'}[$_] } );
        }
    }

    # find the longest x-tick label, and remember how long it is
    for ( @{ $self->{'dataref'}[0] } )
    {
        if ( length($_) > $length )
        {
            $length = length($_);
        }
    }
    $self->{'x_tick_label_length'} = $length;

    # now split the data into sub-objects
    $self->_split_data;

    return;
}

## @fn private _split_data
# split data to the composited classes
#
# create sub-objects for each type, store the appropriate
# data sets in each one, and stick the correct values into
# them (ie. 'gd_obj');
sub _split_data
{
    my $self = shift;
    my @types = ( $self->{'composite_info'}[0][0], $self->{'composite_info'}[1][0] );
    my ( $ref, $i, $j );

    # Already checked for number of components in _check_data, above.
    # we can only do two at a time
    #   if ($self->{'composite_info'}[2]) {
    #     croak "Sorry, Chart::Composite can only do two chart types at a time";
    #   }

    # load the individual modules
    require "Chart/" . $types[0] . ".pm";
    require "Chart/" . $types[1] . ".pm";

    # create the sub-objects
    $self->{'sub_0'} = ( "Chart::" . $types[0] )->new();
    $self->{'sub_1'} = ( "Chart::" . $types[1] )->new();

    # set the options (set the min_val, max_val, brush_size, y_ticks,
    #
    # options intelligently so that the sub-objects don't get
    # confused)
    $self->{'sub_0'}->set( %{ $self->{'opts'} } );
    $self->{'sub_1'}->set( %{ $self->{'opts'} } );
    if ( defined( $self->{'opts'}{'min_val1'} ) )
    {
        $self->{'sub_0'}->set( 'min_val' => $self->{'opts'}{'min_val1'} );
    }
    if ( defined( $self->{'opts'}{'max_val1'} ) )
    {
        $self->{'sub_0'}->set( 'max_val' => $self->{'opts'}{'max_val1'} );
    }
    if ( defined( $self->{'opts'}{'min_val2'} ) )
    {
        $self->{'sub_1'}->set( 'min_val' => $self->{'opts'}{'min_val2'} );
    }
    if ( defined( $self->{'opts'}{'max_val2'} ) )
    {
        $self->{'sub_1'}->set( 'max_val' => $self->{'opts'}{'max_val2'} );
    }
    if ( $self->{'opts'}{'y_ticks1'} )
    {
        $self->{'sub_0'}->set( 'y_ticks' => $self->{'opts'}{'y_ticks1'} );
    }
    if ( $self->{'opts'}{'y_ticks2'} )
    {
        $self->{'sub_1'}->set( 'y_ticks' => $self->{'opts'}{'y_ticks2'} );
    }
    if ( $self->{'opts'}{'brush_size1'} )
    {
        $self->{'sub_0'}->set( 'brush_size' => $self->{'opts'}{'brush_size1'} );
    }
    if ( $self->{'opts'}{'brush_size2'} )
    {
        $self->{'sub_1'}->set( 'brush_size' => $self->{'opts'}{'brush_size2'} );
    }

    if ( $self->{'opts'}{'brushStyle1'} )
    {
        $self->{'sub_0'}->set( 'brushStyle' => $self->{'opts'}{'brushStyle1'} );
    }
    if ( $self->{'opts'}{'brushStyle2'} )
    {
        $self->{'sub_1'}->set( 'brushStyle' => $self->{'opts'}{'brushStyle2'} );
    }

    #  f_y_tick for left and right axis
    if ( defined( $self->{'opts'}{'f_y_tick1'} ) )
    {
        $self->{'sub_0'}->set( 'f_y_tick' => $self->{'opts'}{'f_y_tick1'} );
    }
    if ( defined( $self->{'opts'}{'f_y_tick2'} ) )
    {
        $self->{'sub_1'}->set( 'f_y_tick' => $self->{'opts'}{'f_y_tick2'} );
    }

    # replace the gd_obj fields
    $self->{'sub_0'}->{'gd_obj'} = $self->{'gd_obj'};
    $self->{'sub_1'}->{'gd_obj'} = $self->{'gd_obj'};

    # let the sub-objects know they're sub-objects
    $self->{'sub_0'}->{'component'} = 'true';
    $self->{'sub_1'}->{'component'} = 'true';

    # give each sub-object its data
    $self->{'component_datasets'} = [];
    for $i ( 0 .. 1 )
    {
        $ref = [];
        $self->{'component_datasets'}[$i] = $self->{'composite_info'}[$i][1];
        push @{$ref}, $self->{'dataref'}[0];
        for $j ( @{ $self->{'composite_info'}[$i][1] } )
        {
            $self->_color_role_to_index( 'dataset' . ( $j - 1 ) );    # allocate color index
            push @{$ref}, $self->{'dataref'}[$j];
        }
        $self->{ 'sub_' . $i }->_copy_data($ref);
    }

    # and let them check it
    $self->{'sub_0'}->_check_data;
    $self->{'sub_1'}->_check_data;

    # realign the y-axes if they want
    if ( $self->true( $self->{'same_y_axes'} ) )
    {
        if ( $self->{'sub_0'}{'min_val'} < $self->{'sub_1'}{'min_val'} )
        {
            $self->{'sub_1'}{'min_val'} = $self->{'sub_0'}{'min_val'};
        }
        else
        {
            $self->{'sub_0'}{'min_val'} = $self->{'sub_1'}{'min_val'};
        }

        if ( $self->{'sub_0'}{'max_val'} > $self->{'sub_1'}{'max_val'} )
        {
            $self->{'sub_1'}{'max_val'} = $self->{'sub_0'}{'max_val'};
        }
        else
        {
            $self->{'sub_0'}{'max_val'} = $self->{'sub_1'}{'max_val'};
        }

        $self->{'sub_0'}->_check_data;
        $self->{'sub_1'}->_check_data;
    }

    # find out how big the y-tick labels will be from sub_0 and sub_1
    $self->{'y_tick_label_length1'} = $self->{'sub_0'}->{'y_tick_label_length'};
    $self->{'y_tick_label_length2'} = $self->{'sub_1'}->{'y_tick_label_length'};

    # now return
    return;
}

## @fn private int _draw_legend()
# let the user know what all the pretty colors mean
# @return status
#
sub _draw_legend
{
    my $self = shift;
    my ($length);

    # check to see if they have as many labels as datasets,
    # warn them if not
    if (   ( $#{ $self->{'legend_labels'} } >= 0 )
        && ( ( scalar( @{ $self->{'legend_labels'} } ) ) != $self->{'num_datasets'} ) )
    {
        carp "The number of legend labels and datasets doesn\'t match";
    }

    # init a field to store the length of the longest legend label
    unless ( $self->{'max_legend_label'} )
    {
        $self->{'max_legend_label'} = 0;
    }

    # fill in the legend labels, find the longest one
    for ( 1 .. $self->{'num_datasets'} )
    {
        unless ( $self->{'legend_labels'}[ $_ - 1 ] )
        {
            $self->{'legend_labels'}[ $_ - 1 ] = "Dataset $_";
        }
        $length = length( $self->{'legend_labels'}[ $_ - 1 ] );
        if ( $length > $self->{'max_legend_label'} )
        {
            $self->{'max_legend_label'} = $length;
        }
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
    elsif ( $self->{'legend'} eq 'none' )
    {
        $self->_draw_none_legend;
    }
    else
    {
        carp "I can't put a legend there\n";
    }

    # and return
    return 1;
}

## @fn private int _draw_top_legend()
# put the legend on the top of the data plot
#
# Overwrite the base class _draw_top_legend
#
# @return status
sub _draw_top_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $y1, $x2, $y2, $empty_width, $max_label_width );
    my ( $cols, $rows, $color );
    my ( $col_width, $row_height, $i, $j, $r, $c, $index, $x, $y, $sub, $w, $h );
    my ( $yh, $yi );    #  for boxing legends
    my $font = $self->{'legend_font'};
    my ( %colors, @datasets );
    my $max_legend_example = 0;
    $yh = 0;

    # copy the current boundaries into the sub-objects
    $self->_sub_update;

    # init the legend_example_height
    $self->_legend_example_height_init;

    ## Make datasetI numbers match indexes of @{ $self->{'dataref'} }[1.....].
    #   # modify the dataset color table entries to avoid duplicating
    #   # dataset colors (this limits the number of possible data sets
    #   # for each component to 8)
    #   for (0..7) {
    #     $self->{'sub_1'}{'color_table'}{'dataset'.$_}
    #       = $self->{'color_table'}{'dataset'.($_+8)};
    #   }

    # modify the dataset color table entries to avoid duplicating
    # dataset colors.
    my ( $n0, $n1 ) = map { scalar @{ $self->{'composite_info'}[$_][1] } } 0 .. 1;
    for ( 0 .. $n1 - 1 )
    {
        $self->{'sub_1'}{'color_table'}{ 'dataset' . $_ } = $self->{'color_table'}{ 'dataset' . ( $_ + $n0 ) };
    }

    # make sure we use the right colors for the legend
    @datasets = @{ $self->{'composite_info'}[0][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ($i) };
        $i++;
    }
    @datasets = @{ $self->{'composite_info'}[1][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ( $i + $n0 ) };
        $i++;
    }

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # get some base x coordinates
    $x1 =
      $self->{'curr_x_min'} +
      $self->{'graph_border'} +
      $self->{'y_tick_label_length1'} * $self->{'tick_label_font'}->width +
      $self->{'tick_len'} +
      ( 3 * $self->{'text_space'} );
    $x2 =
      $self->{'curr_x_max'} -
      $self->{'graph_border'} -
      $self->{'y_tick_label_length2'} * $self->{'tick_label_font'}->width -
      $self->{'tick_len'} -
      ( 3 * $self->{'text_space'} );
    if ( $self->{'y_label'} )
    {
        $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }
    if ( $self->{'y_label2'} )
    {
        $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }

    # figure out how wide the widest label is, then figure out how many
    # columns we can fit into the allotted space
    $empty_width = $x2 - $x1 - ( 2 * $self->{'legend_space'} );
    $max_label_width =
      $self->{'max_legend_label'} * $self->{'legend_font'}->width + 4 * $self->{'text_space'} + $self->{'legend_example_size'};
    $cols = int( $empty_width / $max_label_width );
    unless ($cols)
    {
        $cols = 1;
    }
    $col_width = $empty_width / $cols;

    # figure out how many rows we need and how tall they are
    $rows = int( $self->{'num_datasets'} / $cols );
    unless ( ( $self->{'num_datasets'} % $cols ) == 0 )
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

    $max_legend_example = $y2 - $y1;

    # leave some space inside the legend
    $x1 += $self->{'legend_space'} + $self->{'text_space'};
    $x2 -= $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};
    $y2 -= $self->{'legend_space'} + $self->{'text_space'};

    # draw in the actual legend
    $r  = 0;    # current row
    $c  = 0;    # current column
    $yi = 0;    # current dataset

    for $i ( 0 .. 1 )
    {
        for $j ( 0 .. $#{ $self->{'component_datasets'}[$i] } )
        {

            # get the color
            $color = $self->{ 'sub_' . $i }->{'color_table'}{ 'dataset' . $j };
            $index = $self->{'component_datasets'}[$i][$j] - 1;                   # index in label list

            # find the x-y coordinates for the beginning of the example line
            $x = $x1 + ( $col_width * $c );
            $y = $y1 + ( $row_height * $r ) + $h / 2;

            # draw the example line if legend_example_height==1 or ==0
            if ( $rows == 1 )
            {
                if ( $self->{ 'legend_example_height' . $yi } < $max_legend_example )
                {
                    $yh = $self->{ 'legend_example_height' . $yi };
                }
                else
                {
                    $yh = $max_legend_example;
                }
            }
            else
            {
                if ( $self->{ 'legend_example_height' . $yi } < $row_height )
                {
                    $yh = $self->{ 'legend_example_height' . $yi };
                }
                else
                {
                    $yh = $row_height;
                }
            }
            $yi++;
            if ( $yh <= 1 )
            {
                $self->{'gd_obj'}->line( $x, $y, $x + $self->{'legend_example_size'}, $y, $color );
            }
            else
            {

                #  draw the example bar if legend_example_height > 1
                $yh = int( $yh / 2 );
                $self->{'gd_obj'}->filledRectangle( $x, $y - $yh, $x + $self->{'legend_example_size'}, $y + $yh, $color );
            }

            # find the x-y coordinates for the beginning of the label
            $x += $self->{'legend_example_size'} + 2 * $self->{'text_space'};
            $y -= $h / 2;

            # now draw the label
            $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index], $color );

            # keep track of which row/column we're using
            $r = ( $r + 1 ) % $rows;
            if ( $r == 0 )
            {
                $c++;
            }
        }
    }

    # mark of the space used
    $self->{'curr_y_min'} += $rows * $row_height + $self->{'text_space'} + 2 * $self->{'legend_space'};

    return;
}

## @fn private int _draw_right_legend()
# put the legend on the right of the chart
#
# Overwrite the base class _draw_right_legend
#
# @return status
sub _draw_right_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h );
    my ($yh) = 0;                        # for boxing legend
    my $font = $self->{'legend_font'};
    my ( %colors, @datasets, $i );
    my $max_legend_example = 0;

    # copy the current boundaries and colors into the sub-objects
    $self->_sub_update;

    # init the legend exapmle height
    $self->_legend_example_height_init;

    #   # modify the dataset color table entries to avoid duplicating
    #   # dataset colors (this limits the number of possible data sets
    #   # for each component to 8)
    #   for (0..7) {
    #     $self->{'sub_1'}{'color_table'}{'dataset'.$_}
    #       = $self->{'color_table'}{'dataset'.($_+8)};
    #   }
    # modify the dataset color table entries to avoid duplicating
    # dataset colors.
    my ( $n0, $n1 ) = map { scalar @{ $self->{'composite_info'}[$_][1] } } 0 .. 1;

    for ( 0 .. $n1 - 1 )
    {
        $self->{'sub_1'}{'color_table'}{ 'dataset' . $_ } = $self->{'color_table'}{ 'dataset' . ( $_ + $n0 ) };
    }

    # make sure we use the right colors for the legend
    @datasets = @{ $self->{'composite_info'}[0][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ($_) };
        $i++;
    }

    @datasets = @{ $self->{'composite_info'}[1][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ( $i + $n0 ) };
        $i++;
    }

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

    # box the thing off
    $x1 = $self->{'curr_x_max'} - $width;
    $x2 = $self->{'curr_x_max'};
    $y1 = $self->{'curr_y_min'} + $self->{'graph_border'};
    $y2 =
      $self->{'curr_y_min'} +
      $self->{'graph_border'} +
      $self->{'text_space'} +
      ( $self->{'num_datasets'} * ( $h + $self->{'text_space'} ) ) +
      ( 2 * $self->{'legend_space'} );
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $misccolor );

    # leave that nice space inside the legend box
    $x1 += $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};

    # now draw the actual legend
    for ( 0 .. $#labels )
    {

        # get the color
        $color = $colors{$_};

        # find the max_legend_example
        $max_legend_example = $self->{'legend_space'} + $h;

        # find the x-y coords
        $x2 = $x1;
        $x3 = $x2 + $self->{'legend_example_size'};
        $y2 = $y1 + ( $_ * ( $self->{'text_space'} + $h ) ) + $h / 2;

        # draw the example line if legend_example_height==1 or ==0
        if ( $self->{ 'legend_example_height' . $_ } < $max_legend_example )
        {
            $yh = $self->{ 'legend_example_height' . $_ };
        }
        else
        {
            $yh = $max_legend_example;
        }
        if ( $yh <= 1 )
        {
            $self->{'gd_obj'}->line( $x2, $y2, $x3, $y2, $color );
        }
        else
        {
            $yh = int( $yh / 2 );
            $self->{'gd_obj'}->filledRectangle( $x2, $y2 - $yh, $x3, $y2 + $yh, $color );
        }

        # now the label
        $x2 = $x3 + ( 2 * $self->{'text_space'} );
        $y2 -= $h / 2;
        $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
    }

    # mark off the used space
    $self->{'curr_x_max'} -= $width;

    # and return
    return;
}

## @fn private int _draw_left_legend()
#  draw the legend at the left of the data plot
#
# Overwrite the base class _draw_left_legend
#
# @return status
sub _draw_left_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h );
    my $yh;    # for boxing legend
    my $font = $self->{'legend_font'};
    my ( %colors, @datasets, $i );
    my $max_legend_example = 0;

    # copy the current boundaries and colors into the sub-objects
    $self->_sub_update;

    # init the legend_example height
    $self->_legend_example_height_init;

    #   # modify the dataset color table entries to avoid duplicating
    #   # dataset colors (this limits the number of possible data sets
    #   # for each component to 8)
    #   for (0..7) {
    #     $self->{'sub_1'}{'color_table'}{'dataset'.$_}
    #       = $self->{'color_table'}{'dataset'.($_+8)};
    #   }
    # modify the dataset color table entries to avoid duplicating
    # dataset colors.
    my ( $n0, $n1 ) = map { scalar @{ $self->{'composite_info'}[$_][1] } } 0 .. 1;
    for ( 0 .. $n1 - 1 )
    {
        $self->{'sub_1'}{'color_table'}{ 'dataset' . $_ } = $self->{'color_table'}{ 'dataset' . ( $_ + $n0 ) };
    }

    # make sure we use the right colors for the legend
    @datasets = @{ $self->{'composite_info'}[0][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ($i) };
        $i++;
    }
    @datasets = @{ $self->{'composite_info'}[1][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ( $i + $n0 ) };
        $i++;
    }

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
        $color = $colors{$_};

        # find the max_legend_example
        $max_legend_example = $self->{'legend_space'} + $h;

        # find the x-y coords
        $x2 = $x1;
        $x3 = $x2 + $self->{'legend_example_size'};
        $y2 = $y1 + ( $_ * ( $self->{'text_space'} + $h ) ) + $h / 2;

        # draw the example line if legend_example_height==1 or ==0
        if ( $self->{ 'legend_example_height' . $_ } < $max_legend_example )
        {
            $yh = $self->{ 'legend_example_height' . $_ };
        }
        else
        {
            $yh = $max_legend_example;
        }
        if ( $yh <= 1 )
        {
            $self->{'gd_obj'}->line( $x2, $y2, $x3, $y2, $color );
        }
        else
        {

            # draw the example bar if legend_example_height > 1
            $yh = int( $yh / 2 );
            $self->{'gd_obj'}->filledRectangle( $x2, $y2 - $yh, $x3, $y2 + $yh, $color );
        }

        # now the label
        $x2 = $x3 + ( 2 * $self->{'text_space'} );
        $y2 -= $h / 2;
        $self->{'gd_obj'}->string( $font, $x2, $y2, $labels[$_], $color );
    }

    # mark off the used space
    $self->{'curr_x_min'} += $width;

    # and return
    return 1;
}

## @fn private int _draw_bottom_legend()
# put the legend on the bottom of the chart
#
# Overwrite the base class _draw_bottom_legend
#
# @return status
sub _draw_bottom_legend
{
    my $self   = shift;
    my @labels = @{ $self->{'legend_labels'} };
    my ( $x1, $y1, $x2, $y2, $empty_width, $max_label_width, $cols, $rows, $color );
    my ( $col_width, $row_height, $i, $j, $r, $c, $index, $x, $y, $sub, $w, $h );
    my ( $yh, $yi );    # for boxing legend
    my $font = $self->{'legend_font'};
    my ( %colors, @datasets );
    my $max_legend_example = 0;
    $yh = 0;

    # copy the current boundaries and colors into the sub-objects
    $self->_sub_update;

    # init the legend example height
    $self->_legend_example_height_init;

    #   # modify the dataset color table entries to avoid duplicating
    #   # dataset colors (this limits the number of possible data sets
    #   # for each component to 8)
    #   for (0..7) {
    #     $self->{'sub_1'}{'color_table'}{'dataset'.$_}
    #       = $self->{'color_table'}{'dataset'.($_+8)};
    #   }
    # modify the dataset color table entries to avoid duplicating
    # dataset colors.
    my ( $n0, $n1 ) = map { scalar @{ $self->{'composite_info'}[$_][1] } } 0 .. 1;
    for ( 0 .. $n1 - 1 )
    {
        $self->{'sub_1'}{'color_table'}{ 'dataset' . $_ } = $self->{'color_table'}{ 'dataset' . ( $_ + $n0 ) };
    }

    @datasets = @{ $self->{'composite_info'}[0][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ($i) };
        $i++;
    }
    @datasets = @{ $self->{'composite_info'}[1][1] };
    $i        = 0;
    for ( 0 .. $#datasets )
    {
        $colors{ $datasets[$_] - 1 } = $self->{'color_table'}{ 'dataset' . ( $i + $n0 ) };
        $i++;
    }

    # make sure we're using a real font
    unless ( ( ref($font) ) eq 'GD::Font' )
    {
        croak "The subtitle font you specified isn\'t a GD Font object";
    }

    # get the size of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # figure out how many columns we can fit
    $x1 =
      $self->{'curr_x_min'} +
      $self->{'graph_border'} +
      $self->{'y_tick_label_length1'} * $self->{'tick_label_font'}->width +
      $self->{'tick_len'} +
      ( 3 * $self->{'text_space'} );
    $x2 =
      $self->{'curr_x_max'} -
      $self->{'graph_border'} -
      $self->{'y_tick_label_length2'} * $self->{'tick_label_font'}->width -
      $self->{'tick_len'} -
      ( 3 * $self->{'text_space'} );
    if ( $self->{'y_label'} )
    {
        $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }
    if ( $self->{'y_label2'} )
    {
        $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
    }
    $empty_width = $x2 - $x1 - ( 2 * $self->{'legend_space'} );
    $max_label_width =
      $self->{'max_legend_label'} * $self->{'legend_font'}->width + 4 * $self->{'text_space'} + $self->{'legend_example_size'};
    $cols = int( $empty_width / $max_label_width );
    unless ($cols)
    {
        $cols = 1;
    }
    $col_width = $empty_width / $cols;

    # figure out how many rows we need
    $rows = int( $self->{'num_datasets'} / $cols );
    unless ( ( $self->{'num_datasets'} % $cols ) == 0 )
    {
        $rows++;
    }
    unless ($rows)
    {
        $rows = 1;
    }
    $row_height = $h + $self->{'text_space'};

    # box it off
    $y1 = $self->{'curr_y_max'} - $self->{'text_space'} - ( $rows * $row_height ) - ( 2 * $self->{'legend_space'} );
    $y2 = $self->{'curr_y_max'};
    $self->{'gd_obj'}->rectangle( $x1, $y1, $x2, $y2, $self->_color_role_to_index('misc') );

    # get the max_legend_example_height
    $max_legend_example = $y2 - $y1;

    $x1 += $self->{'legend_space'} + $self->{'text_space'};
    $x2 -= $self->{'legend_space'};
    $y1 += $self->{'legend_space'} + $self->{'text_space'};
    $y2 -= $self->{'legend_space'} + $self->{'text_space'};

    # draw in the actual legend
    $r  = 0;
    $c  = 0;
    $yi = 0;    # current dataset
    for $i ( 0 .. 1 )
    {
        for $j ( 0 .. $#{ $self->{'component_datasets'}[$i] } )
        {
            $color = $self->{ 'sub_' . $i }->{'color_table'}{ 'dataset' . $j };
            $index = $self->{'component_datasets'}[$i][$j] - 1;

            $x = $x1 + ( $col_width * $c );
            $y = $y1 + ( $row_height * $r ) + $h / 2;

            #  draw the example line if legend_example_height==1 or ==0
            if ( $rows == 1 )
            {
                if ( $self->{ 'legend_example_height' . $yi } < $max_legend_example )
                {
                    $yh = $self->{ 'legend_example_height' . $yi };
                }
                else
                {
                    $yh = $max_legend_example;
                }
            }
            else
            {
                if ( $self->{ 'legend_example_height' . $yi } < $row_height )
                {
                    $yh = $self->{ 'legend_example_height' . $yi };
                }
                else
                {
                    $yh = $row_height;
                }
            }
            $yi++;
            if ( $yh <= 1 )
            {
                $self->{'gd_obj'}->line( $x, $y, $x + $self->{'legend_example_size'}, $y, $color );
            }
            else
            {

                # draw the example bar if legend_example_height > 1
                $yh = int( $yh / 2 );
                $self->{'gd_obj'}->filledRectangle( $x, $y - $yh, $x + $self->{'legend_example_size'}, $y + $yh, $color );
            }

            $x += $self->{'legend_example_size'} + 2 * $self->{'text_space'};
            $y -= $h / 2;
            $self->{'gd_obj'}->string( $font, $x, $y, $labels[$index], $color );

            # keep track of which row/column we're using
            $r = ( $r + 1 ) % $rows;
            if ( $r == 0 )
            {
                $c++;
            }
        }
    }

    # mark of the space used
    $self->{'curr_y_max'} -= ( $rows * $row_height ) + 2 * $self->{'text_space'} + 2 * $self->{'legend_space'};

    return;
}

## @fn private int _draw_none_legend()
# no legend to draw.. just update the color tables for subs
#
# This routine overwrites this function of the Base class
#
# @return status
sub _draw_none_legend
{
    my $self   = shift;
    my $status = 1;

    $self->_sub_update();

    #   for (0..7) {
    #     $self->{'sub_1'}{'color_table'}{'dataset'.$_}
    #        = $self->{'color_table'}{'dataset'.($_+8)};
    #    }
    # modify the dataset color table entries to avoid duplicating
    # dataset colors.
    my ( $n0, $n1 ) = map { scalar @{ $self->{'composite_info'}[$_][1] } } 0 .. 1;
    for ( 0 .. $n1 - 1 )
    {
        $self->{'sub_1'}{'color_table'}{ 'dataset' . $_ } = $self->{'color_table'}{ 'dataset' . ( $_ + $n0 ) };
    }

    return $status;
}

## @fn private int _draw_ticks()
# draw the ticks and tick labels
#
# Overwrites function _draw_ticks() of base class
#
# @return status
sub _draw_ticks
{
    my $self = shift;

    #draw the x ticks again
    if ( $self->true( $self->{'xy_plot'} ) )
    {
        $self->_find_x_scale;

        # The following statement is necessary as the
        # _draw_x_number_ticks() located in Base.pm does nothing know
        # about different y_tick_label_length variables!
        # This is a hack here
        $self->{'y_tick_label_length'} = $self->{'y_tick_label_length1'};
        $self->_draw_x_number_ticks;
    }
    else
    {
        $self->_draw_x_ticks;
    }

    # update the boundaries in the sub-objects
    $self->_boundary_update( $self, $self->{'sub_0'} );
    $self->_boundary_update( $self, $self->{'sub_1'} );

    # now the y ticks
    $self->_draw_y_ticks;

    # then return
    return;
}

## @fn private int _draw_x_ticks()
# draw the x-ticks and their labels
#
# Overwrites function _draw_x_ticks() of base class
#
# @return status
sub _draw_x_ticks
{
    my $self      = shift;
    my $data      = $self->{'dataref'};
    my $font      = $self->{'tick_label_font'};
    my $textcolor = $self->_color_role_to_index('text');
    my $misccolor = $self->_color_role_to_index('misc');
    my ( $h,     $w );
    my ( $x1,    $x2, $y1, $y2 );
    my ( $width, $delta );
    my ($stag);

    $self->{'grid_data'}->{'x'} = [];

    # make sure we got a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn\'t a GD Font object";
    }

    # get the height and width of the font
    ( $h, $w ) = ( $font->height, $font->width );

    # allow for the amount of space the y-ticks will push the
    # axes over to the right and to the left
## _draw_y_ticks allows 3 * text_space, not 2 * ;  this caused mismatch between
## the ticks (and grid lines) and the data.
    #   $x1 = $self->{'curr_x_min'} + ($w * $self->{'y_tick_label_length1'})
    #          + (2 * $self->{'text_space'}) + $self->{'tick_len'};
    #   $x2 = $self->{'curr_x_max'} - ($w * $self->{'y_tick_label_length2'})
    #          - (2 * $self->{'text_space'}) - $self->{'tick_len'};

    $x1 =
      $self->{'curr_x_min'} + ( $w * $self->{'y_tick_label_length1'} ) + ( 3 * $self->{'text_space'} ) + $self->{'tick_len'};
    $x2 =
      $self->{'curr_x_max'} - ( $w * $self->{'y_tick_label_length2'} ) - ( 3 * $self->{'text_space'} ) - $self->{'tick_len'};
    $y1 = $self->{'curr_y_max'} - $h - $self->{'text_space'};

    # get the delta value, figure out how to draw the labels
    $width = $x2 - $x1;
    $delta = $width / ( $self->{'num_datapoints'} > 0 ? $self->{'num_datapoints'} : 1 );
    if ( $delta <= ( $self->{'x_tick_label_length'} * $w ) )
    {
        unless ( $self->{'x_ticks'} =~ /^vertical$/i )
        {
            $self->{'x_ticks'} = 'staggered';
        }
    }

    # now draw the labels
    if ( $self->{'x_ticks'} =~ /^normal$/i )
    {    # normal ticks
        if ( $self->{'skip_x_ticks'} )
        {
            for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
            {
                $x2 =
                  $x1 +
                  ( $delta / 2 ) +
                  ( $delta * ( $_ * $self->{'skip_x_ticks'} ) ) -
                  ( $w * length( $self->{'f_x_tick'}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) ) ) / 2;
                $self->{'gd_obj'}
                  ->string( $font, $x2, $y1, $self->{'f_x_tick'}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ), $textcolor );
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {
            for ( @{ $self->{'custom_x_ticks'} } )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length( $self->{'f_x_tick'}->( $data->[0][$_] ) ) ) / 2;
                $self->{'gd_obj'}->string( $font, $x2, $y1, $self->{'f_x_tick'}->( $data->[0][$_] ), $textcolor );
            }
        }
        else
        {
            for ( 0 .. $self->{'num_datapoints'} - 1 )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length( $self->{'f_x_tick'}->( $data->[0][$_] ) ) ) / 2;
                $self->{'gd_obj'}->string( $font, $x2, $y1, $self->{'f_x_tick'}->( $data->[0][$_] ), $textcolor );
            }
        }
    }
    elsif ( $self->{'x_ticks'} =~ /^staggered$/i )
    {    # staggered ticks
        if ( $self->{'skip_x_ticks'} )
        {
            $stag = 0;
            for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
            {
                $x2 =
                  $x1 +
                  ( $delta / 2 ) +
                  ( $delta * ( $_ * $self->{'skip_x_ticks'} ) ) -
                  ( $w * length( $self->{'f_x_tick'}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) ) ) / 2;
                if ( ( $stag % 2 ) == 1 )
                {
                    $y1 -= $self->{'text_space'} + $h;
                }
                $self->{'gd_obj'}
                  ->string( $font, $x2, $y1, $self->{'f_x_tick'}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ), $textcolor );
                if ( ( $stag % 2 ) == 1 )
                {
                    $y1 += $self->{'text_space'} + $h;
                }
                $stag++;
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {
            $stag = 0;
            for ( sort ( @{ $self->{'custom_x_ticks'} } ) )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length( $self->{'f_x_tick'}->( $data->[0][$_] ) ) ) / 2;
                if ( ( $stag % 2 ) == 1 )
                {
                    $y1 -= $self->{'text_space'} + $h;
                }
                $self->{'gd_obj'}->string( $font, $x2, $y1, $self->{'f_x_tick'}->( $data->[0][$_] ), $textcolor );
                if ( ( $stag % 2 ) == 1 )
                {
                    $y1 += $self->{'text_space'} + $h;
                }
                $stag++;
            }
        }
        else
        {
            for ( 0 .. $self->{'num_datapoints'} - 1 )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - ( $w * length( $self->{'f_x_tick'}->( $data->[0][$_] ) ) ) / 2;
                if ( ( $_ % 2 ) == 1 )
                {
                    $y1 -= $self->{'text_space'} + $h;
                }
                $self->{'gd_obj'}->string( $font, $x2, $y1, $self->{'f_x_tick'}->( $data->[0][$_] ), $textcolor );
                if ( ( $_ % 2 ) == 1 )
                {
                    $y1 += $self->{'text_space'} + $h;
                }
            }
        }
    }
    elsif ( $self->{'x_ticks'} =~ /^vertical$/i )
    {    # vertical ticks
        $y1 = $self->{'curr_y_max'} - $self->{'text_space'};
        if ( defined( $self->{'skip_x_ticks'} ) && $self->{'skip_x_ticks'} > 1 )
        {
            for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * ( $_ * $self->{'skip_x_ticks'} ) ) - $h / 2;
                $y2 = $y1 - (
                    (
                        $self->{'x_tick_label_length'} -
                          length( $self->{'f_x_tick'}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ) )
                    ) * $w
                );
                $self->{'gd_obj'}
                  ->stringUp( $font, $x2, $y2, $self->{'f_x_tick'}->( $data->[0][ $_ * $self->{'skip_x_ticks'} ] ),
                    $textcolor );
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {
            for ( @{ $self->{'custom_x_ticks'} } )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - $h / 2;
                $y2 = $y1 - ( ( $self->{'x_tick_label_length'} - length( $self->{'f_x_tick'}->( $data->[0][$_] ) ) ) * $w );
                $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $self->{'f_x_tick'}->( $data->[0][$_] ), $textcolor );
            }
        }
        else
        {
            for ( 0 .. $self->{'num_datapoints'} - 1 )
            {
                $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ ) - $h / 2;
                $y2 = $y1 - ( ( $self->{'x_tick_label_length'} - length( $self->{'f_x_tick'}->( $data->[0][$_] ) ) ) * $w );
                $self->{'gd_obj'}->stringUp( $font, $x2, $y2, $self->{'f_x_tick'}->( $data->[0][$_] ), $textcolor );
            }
        }
    }
    else
    {    # error time
        carp "I don't understand the type of x-ticks you specified";
    }

    # update the current y-max value
    if ( $self->{'x_ticks'} =~ /^normal$/i )
    {
        $self->{'curr_y_max'} -= $h + ( 2 * $self->{'text_space'} );
    }
    elsif ( $self->{'x_ticks'} =~ /^staggered$/i )
    {
        $self->{'curr_y_max'} -= ( 2 * $h ) + ( 3 * $self->{'text_space'} );
    }
    elsif ( $self->{'x_ticks'} =~ /^vertical$/i )
    {
        $self->{'curr_y_max'} -= ( $w * $self->{'x_tick_label_length'} ) + ( 2 * $self->{'text_space'} );
    }

    # now plot the ticks
    $y1 = $self->{'curr_y_max'};
    $y2 = $self->{'curr_y_max'} - $self->{'tick_len'};
    if ( $self->{'skip_x_ticks'} )
    {
        for ( 0 .. int( ( $self->{'num_datapoints'} - 1 ) / $self->{'skip_x_ticks'} ) )
        {
            $x2 = $x1 + ( $delta / 2 ) + ( $delta * ( $_ * $self->{'skip_x_ticks'} ) );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }
    elsif ( $self->{'custom_x_ticks'} )
    {
        for ( @{ $self->{'custom_x_ticks'} } )
        {
            $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }
    else
    {
        for ( 0 .. $self->{'num_datapoints'} - 1 )
        {
            $x2 = $x1 + ( $delta / 2 ) + ( $delta * $_ );
            $self->{'gd_obj'}->line( $x2, $y1, $x2, $y2, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x2;
            }
        }
    }

    # update the current y-max value
    $self->{'curr_y_max'} -= $self->{'tick_len'};

    # and return
    return;
}

## @fn private int _draw_y_ticks()
# draw the y-ticks and their labels
#
# Overwrites function _draw_y_ticks() of base class
#
# @return status
sub _draw_y_ticks
{
    my $self = shift;

    # let the first guy do his
    $self->{'sub_0'}->_draw_y_ticks('left');

    # and update the other two objects
    $self->_boundary_update( $self->{'sub_0'}, $self );
    $self->_boundary_update( $self->{'sub_0'}, $self->{'sub_1'} );

    # now draw the other ones
    $self->{'sub_1'}->_draw_y_ticks('right');

    # and update the other two objects
    $self->_boundary_update( $self->{'sub_1'}, $self );
    $self->_boundary_update( $self->{'sub_1'}, $self->{'sub_0'} );

    # then return
    return;
}

## @fn private _draw_data
# finally get around to plotting the data for composite chart
sub _draw_data
{
    my $self = shift;

    # do a grey background if they want it
    if ( $self->true( $self->{'grey_background'} ) )
    {
        $self->_grey_background;
        $self->{'sub_0'}->{'grey_background'} = 'false';
        $self->{'sub_1'}->{'grey_background'} = 'false';
    }

    # draw grid again if necessary (if grey background ruined it..)
    unless ( !$self->true( $self->{grey_background} ) )
    {
        $self->_draw_grid_lines    if ( $self->true( $self->{grid_lines} ) );
        $self->_draw_x_grid_lines  if ( $self->true( $self->{x_grid_lines} ) );
        $self->_draw_y_grid_lines  if ( $self->true( $self->{y_grid_lines} ) );
        $self->_draw_y2_grid_lines if ( $self->true( $self->{y2_grid_lines} ) );
    }

    # do a final bounds update
    $self->_boundary_update( $self, $self->{'sub_0'} );
    $self->_boundary_update( $self, $self->{'sub_1'} );

    # init the imagemap data field if they wanted it
    if ( $self->true( $self->{'imagemap'} ) )
    {
        $self->{'imagemap_data'} = [];
    }

    # now let the component modules go to work

    $self->{'sub_0'}->_draw_data;
    $self->{'sub_1'}->_draw_data;

    return;
}

## @fn private _sub_update()
# update all the necessary information in the sub-objects
#
# Only for Chart::Composite
sub _sub_update
{
    my $self = shift;
    my $sub0 = $self->{'sub_0'};
    my $sub1 = $self->{'sub_1'};

    # update the boundaries
    $self->_boundary_update( $self, $sub0 );
    $self->_boundary_update( $self, $sub1 );

    # copy the color tables
    $sub0->{'color_table'} = { %{ $self->{'color_table'} } };
    $sub1->{'color_table'} = { %{ $self->{'color_table'} } };

    # now return
    return;
}

## @fn private _boundary_update()
# copy the current gd_obj boundaries from one object to another
#
# Only for Chart::Composite
sub _boundary_update
{
    my $self = shift;
    my $from = shift;
    my $to   = shift;

    $to->{'curr_x_min'} = $from->{'curr_x_min'};
    $to->{'curr_x_max'} = $from->{'curr_x_max'};
    $to->{'curr_y_min'} = $from->{'curr_y_min'};
    $to->{'curr_y_max'} = $from->{'curr_y_max'};

    return;
}

## @fn private int _draw_y_grid_lines()
# draw grid_lines for y
#
# Overwrites this function of Base
sub _draw_y_grid_lines
{
    my ($self) = shift;
    $self->{'sub_0'}->_draw_y_grid_lines();
    return;
}

## @fn private int _draw_y2_grid_lines()
# draw grid_lines for y
#
# Overwrites this function of Base
sub _draw_y2_grid_lines
{
    my ($self) = shift;
    $self->{'sub_1'}->_draw_y2_grid_lines();
    return;
}

## @fn private _legend_example_height_values
# init the legend_example_height_values
#
sub _legend_example_height_init
{
    my $self = shift;
    my $a    = $self->{'num_datasets'};
    my ( $b, $e ) = ( 0, 0 );
    my $bis = '..';

    if ( $self->false( $self->{'legend_example_height'} ) )
    {
        for my $i ( 0 .. $a )
        {
            $self->{ 'legend_example_height' . $i } = 1;
        }
    }

    if ( $self->true( $self->{'legend_example_height'} ) )
    {
        for my $i ( 0 .. $a )
        {
            if ( defined( $self->{ 'legend_example_height' . $i } ) ) { }
            else
            {
                ( $self->{ 'legend_example_height' . $i } ) = 1;
            }
        }

        for $b ( 0 .. $a )
        {
            for $e ( 0 .. $a )
            {
                my $anh = sprintf( $b . $bis . $e );
                if ( defined( $self->{ 'legend_example_height' . $anh } ) )
                {
                    if ( $b > $e )
                    {
                        croak "Please reverse the datasetnumber in legend_example_height\n";
                    }
                    for ( my $n = $b ; $n <= $e ; $n++ )
                    {
                        $self->{ 'legend_example_height' . $n } = $self->{ 'legend_example_height' . $anh };
                    }
                }
            }
        }
    }
}

## be a good module and return 1
1;
