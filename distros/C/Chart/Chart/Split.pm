## @file
# Implementation of Chart::Split
#
# written and maintained by the
# @author Chart Group at Geodetic Fundamental Station Wettzell (Chart@fs.wettzell.de)
# @date 2015-03-01
# @version 2.4.10
#

## @class Chart::Split
#Split class derived from class Base.
#
# This class provides all functions which are specific to
# splitted plots
#
package Chart::Split;

use Chart::Base '2.4.10';
use GD;
use Carp;
use strict;

@Chart::Split::ISA     = qw(Chart::Base);
$Chart::Split::VERSION = '2.4.10';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## @fn private _draw_x_number_ticks
#draw the ticks
sub _draw_x_number_ticks
{
    my $self       = shift;
    my $data       = $self->{'dataref'};
    my $font       = $self->{'tick_label_font'};
    my $textcolor  = $self->_color_role_to_index('text');
    my $misccolor  = $self->_color_role_to_index('misc');
    my $num_points = $self->{'num_datapoints'};
    my ( $h, $w, $width, $step, $start, $interval, $label, $stag, @labels );
    my ( $x_start, $y_start, $y, $x, $lines, $delta, $ticks );
    my $x_label_len = 1;
    my $y_label_len = 1;
    my $x_max       = -0x80000000;

    $self->{'grid_data'}->{'x'} = [];

    # find the width
    $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
    $width = 1 if $width == 0;

    # make sure we got a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn\'t a GD Font object";
    }

    # find out how big the font is
    ( $w, $h ) = ( $font->width, $font->height );

    unless ( defined $self->{'start'} && defined $self->{'interval'} )
    {
        croak "I need two values from you to draw a split chart: start and interval!";
    }
    else
    {
        $interval = $self->{'interval'};
        $start    = $self->{'start'};
        $ticks    = $self->{'interval_ticks'} - 1;
        $label    = $start;
    }

    #look after devision by zero!
    if ( $ticks == 0 ) { $ticks = 1; }

    #calculate the step between the ticks
    $step = $interval / $ticks;

    for ( 0 .. $ticks )
    {
        push @labels, $self->{f_x_tick}->( sprintf( "%." . $self->{'precision'} . "f", $label ) );
        $label += $step;
    }

    #find the biggest x value
    foreach ( @{ $data->[0] } )
    {
        if ( $_ > $x_max )
        {
            $x_max = $_;
        }
    }

    #find the length of the x and y labels
    foreach (@labels)
    {
        if ( length($_) > $x_label_len )
        {
            $x_label_len = length($_);
        }
    }

    #find the amount of lines
    $lines = int( ( ( $x_max - $start ) / $interval ) + 0.99999999999 );
    $lines = 1 if $lines == 0;

    #find the length, of the label.
    $y_label_len = length($lines);

    #get the starting point and the width
    if ( $lines > 1 )
    {    #if there are y-ticks
        if ( $self->{'y_axes'} =~ /^right$/i )
        {
            $x_start = $self->{'curr_x_min'};
            $width   = $self->{'curr_x_max'} - $x_start - $self->{'text_space'} * 2 - $y_label_len * $w - $self->{'tick_len'};

        }
        elsif ( $self->{'y_axes'} =~ /^both$/i )
        {
            $x_start = $self->{'curr_x_min'} + ( $w * $y_label_len ) + 2 * $self->{'text_space'} + $self->{'tick_len'};
            $width = $self->{'curr_x_max'} - $x_start - ( $w * $y_label_len ) - 2 * $self->{'text_space'} - $self->{'tick_len'};
        }
        else
        {
            $x_start = $self->{'curr_x_min'} + ( $w * $y_label_len ) + 3 * $self->{'text_space'};
            $width = $self->{'curr_x_max'} - $x_start;
        }
    }
    else
    {    #if there are no y-axes
        $x_start = $self->{'curr_x_min'};
        $width   = $self->{'curr_x_max'} - $x_start;
    }

    #and the y_start value
    $y_start = $self->{'curr_y_max'} - $h - $self->{'text_space'};

    #get the delta value
    $delta = $width / ($ticks);

    if ( !defined( $self->{'skip_x_ticks'} ) )
    {
        $self->{'skip_x_ticks'} = 1;
    }

    #draw the labels
    if ( $self->{'x_ticks'} =~ /^normal$/i )
    {
        if ( $self->{'skip_x_ticks'} > 1 )
        {    #draw a normal tick every nth label
            for ( 0 .. $#labels - 1 )
            {
                if ( defined( $labels[ $_ * $self->{'skip_x_ticks'} ] ) )
                {
                    $x =
                      $x_start +
                      $delta * ( $_ * $self->{'skip_x_ticks'} ) -
                      ( $w * length( $labels[ $_ * $self->{'skip_x_ticks'} ] ) ) / 2;
                    $self->{'gd_obj'}->string( $font, $x, $y_start, $labels[ $_ * $self->{'skip_x_ticks'} ], $textcolor );
                }
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {    #draw only the normal ticks they wanted
            foreach ( @{ $self->{'custom_x_ticks'} } )
            {
                if ( defined $labels[$_] )
                {
                    $x = $x_start + $delta * $_ - ( $w * length( $labels[$_] ) ) / 2;
                    $self->{'gd_obj'}->string( $font, $x, $y_start, $labels[$_], $textcolor );
                }
            }
        }
        else
        {
            for ( 0 .. $#labels )
            {    #draw all ticks normal
                if ( defined $labels[$_] )
                {
                    $x = $x_start + $delta * ($_) - ( $w * length( $labels[$_] ) ) / 2;
                    $self->{'gd_obj'}->string( $font, $x, $y_start, $labels[$_], $textcolor );
                }
            }
        }
    }
    elsif ( $self->{'x_ticks'} =~ /^staggered$/i )
    {
        $stag = 0;
        if ( $self->{'skip_x_ticks'} > 1 )
        {    #draw a staggered tick every nth label
            for ( 0 .. $#labels - 1 )
            {
                if ( defined( $labels[ $_ * $self->{'skip_x_ticks'} ] ) )
                {
                    $x =
                      $x_start +
                      $delta * ( $_ * $self->{'skip_x_ticks'} ) -
                      ( $w * length( $labels[ $_ * $self->{'skip_x_ticks'} ] ) ) / 2;
                    if ( $stag % 2 == 0 )
                    {
                        $y_start -= $self->{'text_space'} + $h;
                    }
                    $self->{'gd_obj'}->string( $font, $x, $y_start, $labels[ $_ * $self->{'skip_x_ticks'} ], $textcolor );
                    if ( $stag % 2 == 0 )
                    {
                        $y_start += $self->{'text_space'} + $h;
                    }
                    $stag++;
                }
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {    # draw only the wanted ticks staggered
            foreach ( sort ( @{ $self->{'custom_x_ticks'} } ) )
            {
                if ( defined $labels[$_] )
                {
                    $x = $x_start + $delta * $_ - ( $w * ( length( $labels[$_] ) ) ) / 2;
                    if ( $stag % 2 == 0 )
                    {
                        $y_start -= $self->{'text_space'} + $h;
                    }
                    $self->{'gd_obj'}->string( $font, $x, $y_start, $labels[$_], $textcolor );
                    if ( $stag % 2 == 0 )
                    {
                        $y_start += $self->{'text_space'} + $h;
                    }
                    $stag++;
                }
            }
        }
        else
        {    # draw all ticks staggered
            for ( 0 .. $#labels )
            {
                if ( defined $labels[$_] )
                {
                    $x = $x_start + $delta * $_ - ( $w * ( length( $labels[$_] ) ) ) / 2;
                    if ( $stag % 2 == 0 )
                    {
                        $y_start -= $self->{'text_space'} + $h;
                    }
                    $self->{'gd_obj'}->string( $font, $x, $y_start, $labels[$_], $textcolor );
                    if ( $stag % 2 == 0 )
                    {
                        $y_start += $self->{'text_space'} + $h;
                    }
                    $stag++;
                }
            }
        }
    }
    elsif ( $self->{'x_ticks'} =~ /^vertical$/i )
    {
        $y_start = $self->{'curr_y_max'} - $self->{'text_space'};
        if ( $self->{'skip_x_ticks'} > 1 )
        {    #draw every nth tick vertical
            for ( 0 .. $#labels )
            {
                if ( defined $_ )
                {
                    $x = $x_start + $delta * ( $_ * $self->{'skip_x_ticks'} ) - $h / 2;
                    $y = $y_start - ( $x_label_len - length( $labels[ $_ * $self->{'skip_x_ticks'} ] ) ) * $w;
                    $self->{'gd_obj'}->stringUp( $font, $x, $y, $labels[ $_ * $self->{'skip_x_ticks'} ], $textcolor );
                }
            }
        }
        elsif ( $self->{'custom_x_ticks'} )
        {
            foreach ( @{ $self->{'custom_x_ticks'} } )
            {    #draw the ticks they want vertical
                if ( defined $labels[$_] )
                {
                    $x = $x_start + $delta * $_ - $h / 2;
                    $y = $y_start - ( $x_label_len - length( $labels[$_] ) ) * $w;
                    $self->{'gd_obj'}->stringUp( $font, $x, $y, $labels[$_], $textcolor );
                }
            }
        }
        else
        {        # draw all ticks vertical
            for ( 0 .. $#labels )
            {
                if ( defined $labels[$_] )
                {
                    $x = $x_start + $delta * $_ - $h / 2;
                    $y = $y_start - ( $x_label_len - length( $labels[$_] ) ) * $w;
                    $self->{'gd_obj'}->stringUp( $font, $x, $y, $labels[$_], $textcolor );
                }
            }
        }

    }

    #update the borders
    if ( $self->{'interval_ticks'} > 0 )
    {
        if ( $self->{'x_ticks'} =~ /^normal$/i )
        {
            $self->{'curr_y_max'} -= $h + $self->{'text_space'} * 2;
        }
        elsif ( $self->{'x_ticks'} =~ /^staggered$/i )
        {
            $self->{'curr_y_max'} -= 2 * $h + 3 * $self->{'text_space'};
        }
        elsif ( $self->{'x_ticks'} =~ /^vertical$/i )
        {
            $self->{'curr_y_max'} -= $w * $x_label_len + $self->{'text_space'} * 2;
        }
    }

    #draw the ticks
    $y_start = $self->{'curr_y_max'};
    $y       = $y_start - $self->{'tick_len'};

    if ( $self->{'skip_x_ticks'} > 1 )
    {
        for ( 0 .. int( ($#labels) / $self->{'skip_x_ticks'} ) )
        {
            $x = $x_start + $delta * ( $_ * $self->{'skip_x_ticks'} );
            $self->{'gd_obj'}->line( $x, $y_start, $x, $y, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x;
            }
        }
    }
    elsif ( $self->{'custom_x_ticks'} )
    {
        foreach ( @{ $self->{'custom_x_ticks'} } )
        {
            if ( $_ <= $ticks )
            {
                $x = $x_start + $delta * $_;
                $self->{'gd_obj'}->line( $x, $y_start, $x, $y, $misccolor );
                if (   $self->true( $self->{'grid_lines'} )
                    or $self->true( $self->{'x_grid_lines'} ) )
                {
                    $self->{'grid_data'}->{'x'}->[$_] = $x;
                }
            }
        }
    }
    else
    {
        for ( 0 .. $#labels )
        {
            $x = $x_start + $_ * $delta;
            $self->{'gd_obj'}->line( $x, $y_start, $x, $y, $misccolor );
            if (   $self->true( $self->{'grid_lines'} )
                or $self->true( $self->{'x_grid_lines'} ) )
            {
                $self->{'grid_data'}->{'x'}->[$_] = $x;
            }
        }
    }

    #another update of the borders
    $self->{'curr_y_max'} -= $self->{'tick_len'} if $self->{'interval_ticks'} > 0;

    #finally return
    return;
}

## @fn private _draw_x_ticks
# override the function implemented in base
sub _draw_x_ticks
{
    my $self = shift;

    #Use always the _draw_x_tick funktion because we always do a xy_plot!!!
    $self->_draw_x_number_ticks();

    #and return
    return 1;
}

## @fn private _draw_y_ticks
# override the function implemented in base
sub _draw_y_ticks
{
    my $self       = shift;
    my $side       = shift || 'left';
    my $data       = $self->{'dataref'};
    my $font       = $self->{'tick_label_font'};
    my $textcolor  = $self->_color_role_to_index('text');
    my $misccolor  = $self->_color_role_to_index('misc');
    my @labels     = @{ $self->{'y_tick_labels'} };
    my $num_points = $self->{'num_datapoints'};
    my ( $w, $h );
    my ( $x_start, $x, $y_start, $y, $start, $interval );
    my ( $height, $delta, $label, $lines, $label_len );
    my ( $s, $f );
    my $x_max = -0x80000000;
    $self->{grid_data}->{'y'}  = [];
    $self->{grid_data}->{'y2'} = [];

    # find the height
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};

    # make sure we got a real font
    unless ( ( ref $font ) eq 'GD::Font' )
    {
        croak "The tick label font you specified isn\'t a GD Font object";
    }

    # find out how big the font is
    ( $w, $h ) = ( $font->width, $font->height );

    #get the base variables
    $interval = $self->{'interval'};
    $start    = $self->{'start'};

    #find the biggest x value
    foreach ( @{ $data->[0] } )
    {
        if ( $_ > $x_max )
        {
            $x_max = $_;
        }
    }

    #calculate the number of lines and the length
    $lines = int( ( ( $x_max - $start ) / $interval ) + 0.99999999999 );
    $lines = 1 if $lines == 0;
    $label_len = length($lines);

    #get the space between two lines
    $delta = $height / $lines;

    #now draw them
    if ( $lines > 1 )
    {
        if ( $side =~ /^right$/i )
        {

            #get the starting point
            $x_start = $self->{'curr_x_max'};
            $y_start = $self->{'curr_y_min'};

            #draw the labels
            for $label ( 0 .. $lines - 1 )
            {
                $x = $x_start - $self->{'text_space'} - $label_len * $w;
                $y = $y_start + $label * $delta + $delta / 2 - $h / 2;
                $self->{'gd_obj'}->string( $font, $x, $y, $label, $textcolor );
            }

            #draw the ticks
            for $label ( 0 .. $lines )
            {
                $x = $x_start - $self->{'text_space'} * 2 - $label_len * $w - $self->{'tick_len'};
                $y = $y_start + $label * $delta;
                $self->{'gd_obj'}->line( $x_start - $self->{'text_space'}, $y, $x, $y, $misccolor );

                #add data for grid_lines
                push @{ $self->{grid_data}->{'y'} }, $y;
            }

            #update the borders
            $self->{'curr_x_max'} = $x_start - $self->{'text_space'} * 2 - $label_len * $w - $self->{'tick_len'};

        }

        elsif ( $side =~ /^both$/i )
        {

            #get the starting point
            $x_start = $self->{'curr_x_min'};
            $y_start = $self->{'curr_y_min'};

            #first the left side
            #draw the labels
            for $label ( 0 .. $lines - 1 )
            {
                $x = $self->{'curr_x_min'} + $self->{'text_space'} * 2;
                $y = $y_start + $label * $delta + $delta / 2 - $h / 2;
                $self->{'gd_obj'}->string( $font, $x, $y, $self->{'f_y_tick'}->($label), $textcolor );
            }

            #draw the ticks
            for $label ( 0 .. $lines )
            {
                $x = $x_start + $self->{'text_space'} * 2 + $label_len * $w + $self->{'tick_len'};
                $y = $y_start + $label * $delta;
                $self->{'gd_obj'}->line( $x_start + $self->{'text_space'}, $y, $x, $y, $misccolor );
            }

            #then the right side
            #get the starting point
            $x_start = $self->{'curr_x_max'};
            $y_start = $self->{'curr_y_min'};

            #draw the labels
            for $label ( 0 .. $lines - 1 )
            {
                $x = $x_start - $self->{'text_space'} - $label_len * $w;
                $y = $y_start + $label * $delta + $delta / 2 - $h / 2;
                $self->{'gd_obj'}->string( $font, $x, $y, $self->{'f_y_tick'}->($label), $textcolor );
            }

            #draw the ticks
            for $label ( 0 .. $lines )
            {
                $x = $x_start - $self->{'text_space'} * 2 - $label_len * $w - $self->{'tick_len'};
                $y = $y_start + $label * $delta;
                $self->{'gd_obj'}->line( $x_start - $self->{'text_space'}, $y, $x, $y, $misccolor );

                #add data for grid_lines
                push @{ $self->{grid_data}->{'y'} }, $y;
            }

            #update the borders
            $self->{'curr_x_min'} += $self->{'text_space'} * 2 + $label_len * $w + $self->{'tick_len'};
            $self->{'curr_x_max'} = $x_start - $self->{'text_space'} * 2 - $label_len * $w - $self->{'tick_len'};

        }
        else
        {

            #get the starting point
            $x_start = $self->{'curr_x_min'};
            $y_start = $self->{'curr_y_min'};

            #draw the labels
            for $label ( 0 .. $lines - 1 )
            {
                $x = $self->{'curr_x_min'} + $self->{'text_space'} * 2;
                $y = $y_start + $label * $delta + $delta / 2 - $h / 2;
                $self->{'gd_obj'}->string( $font, $x, $y, $self->{'f_y_tick'}->($label), $textcolor );
            }

            #draw the ticks
            for $label ( 0 .. $lines )
            {
                $x = $x_start + $label_len * $w + $self->{'tick_len'} + $self->{'text_space'} * 3;
                $y = $y_start + $label * $delta;
                $self->{'gd_obj'}->line( $x_start + $self->{'text_space'}, $y, $x, $y, $misccolor );

                #this is also where we have to draw the grid_lines
                push @{ $self->{grid_data}->{'y'} }, $y;
            }

            #update the borders
            $self->{'curr_x_min'} = $x_start + $self->{'text_space'} * 3 + $label_len * $w;
        }

    }

    #finally return
    return 1;
}

## @fn private _draw_data
# plot the data
sub _draw_data
{
    my $self       = shift;
    my $data       = $self->{'dataref'};
    my $misccolor  = $self->_color_role_to_index('misc');
    my $num_points = $self->{'num_datapoints'};
    $num_points = 1 if $num_points == 0;
    my $num_sets = $self->{'num_datasets'};
    $num_sets = 1 if $num_sets == 0;
    my ( $lines,    $split,   $width,     $height, $delta_lines, $delta_sets, $map, $last_line );
    my ( $akt_line, $akt_set, $akt_point, $color,  $x_start,     $y_start,    $x,   $y );
    my ( $x_last, $y_last, $delta_point, $brush, $mod, $x_interval, $start );
    my $i        = 0;
    my $interval = ( $self->{'max_val'} - $self->{'min_val'} );
    $interval = 1 if $interval == 0;
    my $x_max = -0x80000000;

    # find the height and the width
    $width  = $self->{'curr_x_max'} - $self->{'curr_x_min'};
    $width  = 1 if $width == 0;
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $height = 1 if $height == 0;

    # init the imagemap data field if they asked for it
    if ( $self->true( $self->{'imagemap'} ) )
    {
        $self->{'imagemap_data'} = [];
    }

    #get the base values
    $x_interval = $self->{'interval'};
    $x_interval = 1 if $x_interval == 0;
    $start      = $self->{'start'};

    #find the biggest x value
    foreach ( @{ $data->[0] } )
    {
        if ( $_ > $x_max )
        {
            $x_max = $_;
        }
    }

    #calculate the number of lines
    $lines = int( ( ( $x_max - $start ) / $x_interval ) + 0.99999999999 );
    $lines = 1 if $lines == 0;

    #find delta_lines for the space between the lines
    #and delta_sets for the space of the datasets of one line
    #and the delta_point for the space between the datapoints
    $delta_lines = $height / $lines;
    $delta_sets  = $delta_lines / $num_sets;
    $delta_point = $width / ($x_interval);

    #find $map, for the y values
    $map = $delta_sets / $interval;

    #find the mod and the y_start value
    #correct the start value, if scale is set! Otherwise the plot is to high or to low!
    #The corecction, isn't perfect, but it does a good job in most cases.
    if ( $self->{'min_val'} >= 0 )
    {
        $mod = $self->{'min_val'};
        if ( $self->{'scale'} > 1 )
        {
            $y_start = $self->{'curr_y_min'} + ( $interval * $map / 2 ) * ( $self->{'scale'} - 1 );
        }
        else
        {
            $y_start = $self->{'curr_y_min'};
        }
    }
    elsif ( $self->{'max_val'} <= 0 )
    {
        $mod = $self->{'min_val'};
        if ( $self->{'scale'} > 1 )
        {
            $y_start = $self->{'curr_y_min'} + ( $interval * $map / 2 ) * ( $self->{'scale'} - 1 );
        }
        else
        {
            $y_start = $self->{'curr_y_min'};
        }
    }
    else
    {
        $y_start = $self->{'curr_y_min'} + ( $map * $self->{'min_val'} );
        $mod = 0;
    }

    #The upper right corner is the point, where we start
    $x_start = $self->{'curr_x_min'};

    #draw the lines
    for $akt_set ( 0 .. $num_sets - 1 )
    {
        for $akt_point ( 0 .. $self->{'num_datapoints'} - 1 )
        {

            #get the color for this dataset
            $color = $self->_color_role_to_index( 'dataset' . $akt_set );
            $brush = $self->_prepare_brush( $color, 'line' );
            $self->{'gd_obj'}->setBrush($brush);

            #start with the first point at line number zero
            $last_line = 0;
            for $akt_line ( $last_line .. $lines - 1 )
            {

                #update the last line. That makes it a little bit faster.
                $last_line = $akt_line;

                #Don't try to draw, if there is no data
                if ( defined $data->[0][$akt_point] )
                {
                    if (   $data->[0][$akt_point] <= ( ( $akt_line + 1 ) * $x_interval + $start )
                        && $data->[0][$akt_point] >= $akt_line * $x_interval + $start )
                    {

                        #the current point
                        $x = $x_start + ( $data->[0][$akt_point] - ( $akt_line * $x_interval ) - ($start) ) * $delta_point;
                        $y =
                          $y_start +
                          $akt_line * $delta_lines +
                          $akt_set * $delta_sets +
                          $delta_sets -
                          ( $data->[ 1 + $akt_set ][$akt_point] - $mod ) * $map * $self->{'scale'};

                        #draw the line
                        $self->{'gd_obj'}->line( $x_last, $y_last, $x, $y, gdBrushed ) if $akt_point != 0;

                        #calculate the start point for the next line
                        #first if the next point is in the same line
                        if (   defined( $data->[0][ $akt_point + 1 ] )
                            && $data->[0][ $akt_point + 1 ] <= ( ( $akt_line + 1 ) * $x_interval + $start )
                            && $data->[0][ $akt_point + 1 ] > $akt_line * $x_interval + $start )
                        {
                            $x_last = $x;
                            $y_last = $y;
                        }

                        #second, if the next point is not in the same line
                        else
                        {
                            $x_last = $self->{'curr_x_min'};
                            $y_last =
                              $y_start +
                              ( $akt_line + 1 ) * $delta_lines +
                              $akt_set * $delta_sets +
                              $delta_sets -
                              ( $data->[ 1 + $akt_set ][$akt_point] - $mod ) * $map * $self->{'scale'};
                        }

                        # store the imagemap data if they asked for it
                        if ( $self->true( $self->{'imagemap'} ) )
                        {
                            $self->{'imagemap_data'}->[$akt_set][ $akt_point - 1 ] = [ $x_last, $y_last ];
                            $self->{'imagemap_data'}->[$akt_set][$akt_point] = [ $x, $y ];
                        }
                    }
                    else
                    {    #Go to the next line. Maybe the current point is in that line!
                        next;
                    }
                }
                else
                {
                    if ( $self->true( $self->{'imagemap'} ) )
                    {
                        $self->{'imagemap_data'}->[$akt_set][ $akt_point - 1 ] = [ undef(), undef() ];
                        $self->{'imagemap_data'}->[$akt_set][$akt_point] = [ undef(), undef() ];
                    }
                }
            }
        }
    }

    $y_start = $self->{'curr_y_min'};

    #draw some nice little lines
    for $akt_set ( 0 .. $num_sets - 1 )
    {
        for $akt_line ( 0 .. $lines - 1 )
        {

            #draw a line between the sets at the left side of the chart
            $self->{'gd_obj'}->line(
                $x_start,
                $y_start + $akt_line * $delta_lines + $akt_set * $delta_sets,
                $x_start + $self->{'tick_len'},
                $y_start + $akt_line * $delta_lines + $akt_set * $delta_sets, $misccolor
            );

            #draw a line between the sets at the right side of the chart
            $self->{'gd_obj'}->line(
                $self->{'curr_x_max'},
                $y_start + $akt_line * $delta_lines + $akt_set * $delta_sets,
                $self->{'curr_x_max'} - $self->{'tick_len'},
                $y_start + $akt_line * $delta_lines + $akt_set * $delta_sets, $misccolor
            );
        }
    }

    #Box it off
    $self->{'gd_obj'}
      ->rectangle( $self->{'curr_x_min'}, $self->{'curr_y_min'}, $self->{'curr_x_max'}, $self->{'curr_y_max'}, $misccolor );

    #finally retrun
    return;
}

#be a good modul and return 1
1;

