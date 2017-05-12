# -*- perl -*-

# Copyright (c) 2002 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+chart-strip @ tcp4me.com>
# Date: 2002-Nov-01 16:11 (EST)
# Function: draw strip charts
#
# $Id: Strip.pm,v 1.22 2011/11/11 00:38:11 jaw Exp $

$Chart::Strip::VERSION = "1.08";

=head1 NAME

Chart::Strip - Draw strip chart type graphs.

=head1 SYNOPSIS

    use Chart::Strip;

    my $ch = Chart::Strip->new(
	         title   => 'Happiness of our Group',
		 # other options ...
             );

    $ch->add_data( $davey_data, { style => 'line',
				  color => 'FF0000',
				  label => 'Davey' } );

    $ch->add_data( $jenna_data, { style => 'line',
				  color => '00FF88',
				  label => 'Jenna' } );

    print $ch->png();

=head1 DESCRIPTION

The Chart::Strip package plots data values versus time graphs, such as
used for seismographs, EKGs, or network usage reports.

It can plot multiple data sets on one graph. It offers several
styles of plots. It automatically determines the proper ranges
and labels for both axii.

=head1 USAGE

=head2 Create the Chart

    $chart = Chart::Strip->new();
    $chart = Chart::Strip->new(
			       option1 => value,
			       option2 => value,
			       );

If no options are specified, sensible default values will be used.
The following options are recognized:

=over 4

=item C<width>

The width of the image

=item C<height>

The height of the image.

=item C<title>

The title of the graph. Will be placed centered at the top.

=item C<x_label>

The label for the x axis. Will be placed centered at the bottom.

=item C<y_label>

The label for the y axis. Will be placed vertically along the left side.

=item C<draw_grid>

Should a grid be drawn on the graph?

=item C<draw_border>

Should a border be drawn around the edge of the image?

=item C<draw_tic_labels>

Should value labels be shown?

=item C<draw_data_labels>

Should each data set be labeled?

=item C<transparent>

Should the background be transparent?

=item C<grid_on_top>

Should the grid be drawn over the data (1) or below the data (0)?

=item C<binary>

Use powers of 2 instead of powers of 10 for the y axis labels.

=item C<data_label_style>

Style for drawing the graph labels. C<text> or C<box>

=item C<thickness>

Thickness of lines in pixels. (Requires GD newer than $VERSION).

=item C<skip_undefined>

Don\'t draw a line into or out of a datapoint whose value is undefined.
If false, undefined values are treated as though they were 0.

=item C<boxwidth>

Width of boxes for box style graphs. The width may also be specified as C<width>
in the data options or per point. If no width is specified a reasonable default is used.

=back

=head2 Adding Data

    $chart->add_data( $data, $options );

The data should be an array ref of data points. Each data point
should be a hash ref containing:

    {
	time  => $time_t,  # must be a unix time_t
	value => $value,   # the data value
	color => $color,   # optional, used for this one point
    }

or, range style graphs should contain:

    {
	time  => $time_t,  # must be a unix time_t
	min   => $low,     # the minimum data value
	max   => $high,    # the maximum data value
	color => $color,   # optional, used for this one point
    }

and the options may contain:

    {
	style => 'line',	     # graph style: line, filled, range, points, box
	color => 'FF00FF',           # color used for the graph
	label => 'New England',      # name of the data set
    }

points style graphs may specify the point diameter, as C<diam>

box style graphs may specify the box width, as C<width>

line and filled graphs may specify a C<smooth> parameter, to connect
points using smooth curves instead of straight lines. A value of C<1>
is recommended, larger values will be less smooth.

line, points, box, and filled graphs may specify a drop shadow,
consisting of a hashref containing C<dx>, C<dy>, C<dw>, and optionally, C<color>

    shadow => { dx => 3, dy => 3, dw => 3, color => 'CCCCCC' }


=head2 Outputing The Image

=over 4

=item $chart->png()

Will return the PNG image

=item $chart->jpeg()

Will return the jpeg image

=item $chart->gd()

Will return the underlying GD object.

=back

=cut
    ;

package Chart::Strip;
use GD;
use Carp;
use POSIX;
use strict;

my $LT_HM = 1;	# time
my $LT_HR = 2;	# time/day
my $LT_DW = 3;	# day/date
my $LT_DM = 4;	# date/yr
my $LT_YR = 5;	# year

my $MT_NO = 0;	# none
my $MT_HR = 1;	# hrs
my $MT_MN = 2;	# midnight
my $MT_SU = 3;	# sunday
my $MT_M1 = 4;	# 1st
my $MT_Y1 = 5;	# new years

sub new {
    my $class = shift;
    my %param = @_;

    my $me = bless {
	width	      => 640,
	height        => 192,
	margin_left   => 8,
	margin_bottom => 8,
	margin_right  => 8,
	margin_top    => 8,
	n_y_tics      => 4, # aprox.

	transparent      => 1,
	grid_on_top      => 1,
	draw_grid        => 1,
	draw_border      => 1,
	draw_tic_labels  => 1,
	draw_data_labels => 1,
	limit_factor     => 0,
	data_label_style => 'text',  # or 'box'
	thickness	 => 1,
        tm_time		 => \&POSIX::localtime,	# or gmtime, or...
        shadow_color	 => '#CCCCCC',
# GD can only antialias on a truecolor image, and only if thickness==1
# yes, I know what the GD documentation says. I also know what the src says...
        antialias	 => 0,
        truecolor	 => 0,

	# title
	# x_label
	# y_label

	# user specified params override defaults
	%param,

    }, $class;

    $me->adjust();

    my $im = GD::Image->new( $me->{width}, $me->{height}, $me->{truecolor} );
    $me->{img} = $im;

    # Nor long the sun his daily course withheld,
    # But added colors to the world reveal'd:
    # When early Turnus, wak'ning with the light,
    #   -- Virgil, Aeneid
    # allocate some useful colors, 1st is used for bkg
    my $bkg = $me->color({ color => $me->{background_color} }) if $me->{background_color};
    $me->{color}{white} = $im->colorAllocate(255,255,255);
    $me->{color}{black} = $im->colorAllocate(0,0,0);
    $me->{color}{blue}  = $im->colorAllocate(0, 0, 255);
    $me->{color}{red}   = $im->colorAllocate(255, 0, 0);
    $me->{color}{green} = $im->colorAllocate(0, 255, 0);
    $me->{color}{gray}  = $im->colorAllocate(128, 128, 128);

    # style for grid lines
    $im->setStyle(gdTransparent, $me->{color}{gray}, gdTransparent, gdTransparent);

    $im->interlaced('true');
    $im->transparent($me->{color}{white})
	if $me->{transparent};

    $im->filledRectangle( 0, 0, $me->{width}-1, $me->{height}-1, ($bkg || $me->{color}{white}));

    my $bc = $me->{border_color} ? $me->img_color($me->{border_color}) : $me->{color}{black};

    $im->rectangle(0, 0, $me->{width}-1, $me->{height}-1, $bc )
	if $me->{draw_border};

    $me;
}

sub add_data {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;

    $me->analyze( $data, $opts );

    unless( $opts->{style} ){
	$opts->{style} = defined $data->[0]{min} ? 'range' : 'line';
    }

    push @{$me->{data}}, {data => $data, opts => $opts};
    $me->{has_shadow} = 1 if $opts->{shadow};

    $me;
}

# A plot shall show us all a merry day.
#   -- Shakespeare, King Richard II
sub plot {
    my $me = shift;

    return unless $me->{data};
    return if $me->{all_done};

    $me->adjust();
    $me->clabels();
    $me->xlabel();
    $me->ylabel();
    $me->title();

    if( $me->{draw_tic_labels} ){
	# move margin for xtics before we do ytics
	$me->{margin_bottom} += 12;
	$me->adjust();
    }

    $me->ytics();
    $me->xtics();

    # draw shadows
    foreach my $d ( @{$me->{data}} ){
        next unless $d->{opts}{shadow};
        $me->plot_data( $d->{data}, $d->{opts}, $d->{opts}{shadow} );
    }

    $me->axii();
    $me->drawgrid() unless $me->{grid_on_top};

    # plot
    foreach my $d ( @{$me->{data}} ){
	$me->plot_data( $d->{data}, $d->{opts}, undef );
    }

    $me->drawgrid() if $me->{grid_on_top};

    $me->{all_done} = 1;
    $me;
}


# The axis of the earth sticks out visibly through the centre of each and every town or city.
#   -- Oliver Wendell Holmes, The Autocrat of the Breakfast-Table
sub axii {
    my $me = shift;
    my $im = $me->{img};

    # draw axii
    $im->line( $me->xpt(-1), $me->ypt(-1), $me->xpt(-1), $me->ypt($me->{ymax}), $me->{color}{black});
    $im->line( $me->xpt(-1), $me->ypt(-1), $me->xpt($me->{xmax}), $me->ypt(-1), $me->{color}{black});

    # 'Talking of axes,' said the Duchess, 'chop off her head!'
    #   -- Alice in Wonderland
    $me;
}

sub set_thickness {
    my $me = shift;
    my $tk = shift;
    my $im = $me->{img};

    # not available until gd 2.07
    return unless $im->can('setThickness');
    $im->setThickness($tk);
}

sub gd {
    my $me = shift;

    $me->plot();
    $me->{img};
}

sub png {
    my $me = shift;

    $me->plot();
    $me->{img}->png( @_ );
}

sub jpeg {
    my $me = shift;

    $me->plot();
    $me->{img}->jpeg( @_ );
}


# xpt, ypt - convert graph space => image space
sub xpt {
    my $me = shift;
    my $pt = shift;

    $pt + $me->{margin_left};
}

sub ypt {
    my $me = shift;
    my $pt = shift;

    # make 0 bottom
    $me->{height} - $pt - $me->{margin_bottom};
}

# xdatapt, ydatapt - convert data space => image space
sub xdatapt {
    my $me = shift;
    my $pt = shift;

    $me->xpt( ($pt - $me->{xd_min}) * $me->{xd_scale} );
}

sub ydatapt {
    my $me = shift;
    my $pt = shift;

    $pt = $pt < $me->{yd_min} ? $me->{yd_min} : $pt;
    $pt = $pt > $me->{yd_max} ? $me->{yd_max} : $pt;

    $me->ypt( ($pt - $me->{yd_min}) * $me->{yd_scale} );
}

sub adjust {
    my $me = shift;

    # I have touched the highest point of all my greatness;
    #   -- Shakespeare, King Henry VIII
    $me->{xmax} = $me->{width}  - $me->{margin_right}  - $me->{margin_left};
    $me->{ymax} = $me->{height} - $me->{margin_bottom} - $me->{margin_top} ;

    if( $me->{data} ){
	$me->{xd_scale} = ($me->{xd_min} == $me->{xd_max}) ? 1
	    : $me->{xmax} / ($me->{xd_max} - $me->{xd_min});

	$me->{yd_scale} = ($me->{yd_min} == $me->{yd_max}) ? 1
	    : $me->{ymax} / ($me->{yd_max} - $me->{yd_min});
    }

    $me;
}

sub analyze {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;
    my( $st, $et, $pt, $min, $max );

    $st = $data->[0]{time};	# start time
    $et = $data->[-1]{time};	# end time
    $pt = $st;

    foreach my $s (@$data){
	croak "data point out of order" if $s->{time} < $pt;
	my $a = defined $s->{min} ? $s->{min} : $s->{value};
	my $b = defined $s->{max} ? $s->{max} : $s->{value};
	$a ||= 0 unless $me->{skip_undefined} || $opts->{skip_undefined};
	$b ||= 0 unless $me->{skip_undefined} || $opts->{skip_undefined};
	($a, $b) = ($b, $a) if $a > $b;

	$min = $a if defined($a) && ( !defined($min) || $a < $min );
	$max = $b if defined($b) && ( !defined($max) || $b > $max );
	$pt  = $s->{time};
    }

    if( $opts->{style} eq 'box' ){
	# stretch x axis if drawing wide boxes
	my $defwid = def_box_width($st, $et, scalar(@$data));
	my $w = $data->[0]{width} || $opts->{width} || $me->{boxwidth} || $defwid;
	$st -= $w/2;

	$w = $data->[-1]{width} || $opts->{width} || $me->{boxwidth} || $defwid;
	$et += $w/2;

	# boxes are drawn from y=0
	$min = 0 if $min > 0;
    }

    if( $opts->{smooth} || $me->{smooth} ){
        # calculate derivative at each point (which may or may not be evenly spaced)
        for my $i (0 .. @$data-1){
            my $here  = $data->[$i];
            my $left  = $i ? $data->[$i-1] : $data->[$i];
            my $right = ($i!=@$data-1) ? $data->[$i+1] : $data->[$i];

            my $dxl = $here->{time}   - $left->{time};
            my $dxr = $right->{time}  - $here->{time};
            my $dyl = $here->{value}  - $left->{value};
            my $dyr = $right->{value} - $here->{value};

            if( $dxr && $dxl ){
                my $dl = $dyl / $dxl;
                my $dr = $dyr / $dxr;
                if( $dl < 0 && $dr > 0 || $dl > 0 && $dr < 0 ){
                    # local extrema
                    $data->[$i]{dydx} = 0;
                }else{
                    my $dm = ( $dl * $dxr + $dr * $dxl ) / ($dxr + $dxl);
                    # mathematicaly, $dm is the best estimate of the derivative, and gives the smoothest curve
                    # but, this way looks nicer...
                    my $d = (sort { abs($a) <=> abs($b) } ($dl, $dr, $dm))[0];
                    $data->[$i]{dydx} = ($d + $dm) / 2;
                }
            }elsif($dxr){
                $data->[$i]{dydx} = $dyr / $dxr;
            }elsif($dxl){
                $data->[$i]{dydx} = $dyl / $dxl;
            }
        }
    }

    $me->{xd_min} = $st  if $st && (!defined($me->{xd_min}) || $st  < $me->{xd_min});
    $me->{xd_max} = $et  if $et && (!defined($me->{xd_max}) || $et  > $me->{xd_max});
    $me->{yd_min} = $min if         !defined($me->{yd_min}) || $min < $me->{yd_min};
    $me->{yd_max} = $max if         !defined($me->{yd_max}) || $max > $me->{yd_max};

}

# I hear beyond the range of sound,
# I see beyond the range of sight,
# New earths and skies and seas around,
# And in my day the sun doth pale his light.
#   -- Thoreau, Inspiration
sub set_y_range {
    my $me = shift;
    my $l  = shift;
    my $h  = shift;

    $me->{yd_min} = $l if defined($l) && $l ne '';
    $me->{yd_max} = $h if defined($h) && $h ne '';
    $me->adjust();
}

sub set_x_range {
    my $me = shift;
    my $l  = shift;
    my $h  = shift;

    $me->{xd_min} = $l if defined($l) && $l ne '';
    $me->{xd_max} = $h if defined($h) && $h ne '';
    $me->adjust();
}

sub img_color {
    my $me    = shift;
    my $color = shift;

    $color =~ s/^#//;
    $color =~ s/\s//g;

    return $me->{color}{$color} if $me->{color}{$color};
    my($r,$g,$b) = map {hex} unpack('a2 a2 a2', $color);
    my $i = $me->{img}->colorAllocate( $r, $g, $b );
    $me->{color}{$color} = $i;

    return $i;
}

# choose proper color for plot
sub color {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;

    # What is your favorite color?
    # Blue.  No yel--  Auuuuuuuugh!
    #   -- Monty Python, Holy Grail
    my $c = $data->{color} || $opts->{color};
    if( $c ){
        return $me->img_color( $c );
    }

    return $me->{color}{green};
}

# Titles are marks of honest men, and wise;
# The fool or knave that wears a title lies.
#   -- Edward Young, Love of Fame
sub title {
    my $me = shift;
    my( $loc );

    return unless $me->{title};
    $me->{margin_top} += 16;
    $me->adjust();
    # center title
    $loc = ($me->{width} - length($me->{title}) * 7) / 2;
    $me->{img}->string(gdMediumBoldFont, $loc, 2, $me->{title}, $me->{color}{black});
}

# when I waked, I found This label on my bosom
#   -- Shakespeare, Cymbeline
sub xlabel {
    my $me = shift;
    my( $loc, $y );

    return unless $me->{x_label};
    $me->{margin_bottom} += 16;
    $me->adjust();
    $loc = ($me->{width} - length($me->{x_label}) * 6) / 2;
    $y = $me->{height} - $me->{margin_bottom} + 8;
    $me->{img}->string(gdSmallFont, $loc, $y, $me->{x_label}, $me->{color}{black});
}

sub ylabel {
    my $me = shift;
    my( $loc );

    return unless $me->{y_label};
    $me->{margin_left} += 12;
    $me->adjust();
    my $m = ($me->{height} - $me->{margin_top} - $me->{margin_bottom}) / 2 + $me->{margin_top};
    $loc = $m + length($me->{y_label}) * 6 / 2;
    $me->{img}->stringUp(gdSmallFont, 2, $loc, $me->{y_label}, $me->{color}{black});
    # small => 12,6; tiny => 10,5
}

# It must be a very pretty dance
#   -- Alice in Wonderland
# make tic numbers pretty
sub pretty {
    my $me = shift;
    my $y  = shift;
    my $st = shift;
    my( $ay, $sc, $b, $prec );

    return $me->{fmt_value}->($y) if $me->{fmt_value};
    $sc = '';
    $ay = abs($y);
    $b = $me->{binary} ? 1024 : 1000;

    if( $ay < 1 ){
	if( $ay < 1/$b**3 ){
	    return "0";
	}
	elsif( $ay < 1/$b**2 ){
	    $y *= $b ** 3; $st *= $b ** 3;
	    $sc = 'n';
	}
	elsif( $ay < 1/$b ){
	    $y *= $b**2; $st *= $b**2;
	    $sc = 'u';
	}
	elsif( $ay < 100/$b ){ # QQQ
	    $y *= $b; $st *= $b;
	    $sc = 'm';
	}
    }else{
	if( $ay >= $b**4 ){
	    $y /= $b**4;  $st /= $b**4;
	    $sc = 'T';
	}
	elsif( $ay >= $b**3 ){
	    $y /= $b**3;  $st /= $b**3;
	    $sc = 'G';
	}
	elsif( $ay >= $b**2 ){
	    $y /= $b**2; $st /= $b**2;
	    $sc = 'M';
	}
	elsif( $ay >= $b ){
	    $y /= $b;   $st /= $b;
	    $sc = 'k';
	}
    }
    $sc .= 'i' if $sc && $me->{binary}; # as per IEC 60027-2
    if( $st > 1 ){
	$prec = 0;
    }else{
	$prec = abs(floor(log($st)/log(10)));
    }

    sprintf "%.${prec}f$sc", $y;
}

sub ytics {
    my $me  = shift;
    my( $min, $max, $tp, $st, $is, $low, $maxw, @tics );

    $min = $me->{yd_min};
    $max = $me->{yd_max};
    $maxw = 0;

    if( $min == $max ){
	# not a very interesting graph...
	my $lb = $me->pretty($min, 1);	# QQQ
	my $w = length($lb) * 5 + 6;
	push @tics, [$me->ydatapt($min), $lb, $w];
	$maxw = $w;
    }else{
	$tp = ($max - $min) / $me->{n_y_tics};	# approx spacing of tics
	if( $me->{binary} ){
	    $is =  2 ** floor( log($tp)/log(2) );
	}else{
	    $is = 10 ** floor( log($tp)/log(10) );
	}
	$st  = floor( $tp / $is ) * $is; # -> 4 - 8, ceil -> 2 - 4
        # mathematically, tp/is cannot be less than 1
        # but due to floating-point lossage, in rare cases, it might
        $st ||= $is;
	$low = int( $min / $st ) * $st;
	for my $i ( 0 .. (2 * $me->{n_y_tics} + 2) ){
	    my $y = $low + $i * $st;
	    next if $y < $min;
	    last if $y > $max;
	    my $yy = $me->ydatapt($y);
	    my $label = $me->pretty($y, $st);
	    my $w = 5 * length($label) + 6;
	    $maxw = $w if $w > $maxw;

	    push @tics, [$yy, $label, $w];
	}
    }

    if( $me->{draw_tic_labels} ){
	# move margin
	$me->{margin_left} += $maxw;
	$me->adjust();
    }

    $me->{grid}{y} = \@tics;
}

sub drawgrid {
    my $me = shift;
    my $im = $me->{img};

    foreach my $tic (@{$me->{grid}{y}}){
	# ytics + horiz lines
	my $yy = $tic->[0];
	$im->line($me->xpt(-1), $yy, $me->xpt(-4), $yy,
			 $me->{color}{black});
	$im->line($me->xpt(0), $yy, $me->{width} - $me->{margin_right}, $yy,
			 gdStyled) if $me->{draw_grid};

	if( $me->{draw_tic_labels} ){
	    my $label = $tic->[1];
	    my $w = $tic->[2];
	    $im->string(gdTinyFont, $me->xpt(-$w), $yy-4,
			       $label,
			       $me->{color}{black});
	}
    }

    foreach my $tic (@{$me->{grid}{x}}){
	# xtics + vert lines
	my( $t, $ll, $label ) = @$tic;

	# supress solid line if adjacent to axis
	if( $ll && ($t != $me->{xd_min}) ){
	    # solid line, red label
	    $im->line($me->xdatapt($t), $me->{margin_top},
			     $me->xdatapt($t), $me->ypt(-4),
			     $me->{color}{black} );
	}else{
	    # tic and grid
	    $im->line($me->xdatapt($t), $me->ypt(-1),
			     $me->xdatapt($t), $me->ypt(-4),
			     $me->{color}{black} );
	    $im->line($me->xdatapt($t), $me->{margin_top},
			     $me->xdatapt($t), $me->ypt(0),
			     gdStyled ) if $me->{draw_grid};
	}

	if( $me->{draw_tic_labels} ){
	    my $a = length($label) * 6 / 4;	# it looks better not quite centered
	    if( length($label)*6 * 3/4 + $me->xdatapt($t) > $me->{width} ){
		# too close to edge, shift
		$a = $me->xdatapt($t) - $me->{width} + length($label) * 6 + 2;
	    }

	    $im->string(gdSmallFont, $me->xdatapt($t)-$a, $me->ypt(-6),
			       $label, $ll ? $me->{color}{red} : $me->{color}{black} );
	}
    }
}

sub xtic_range_data {
    my $me    = shift;	# not used
    my $range = shift;

    my $range_hrs  = $range / 3600;
    my $range_days = $range_hrs / 24;

    # return: step, labeltype, marktype, lti, tmod

    if( $range < 720 ){
	(60, $LT_HM, $MT_HR, 1, 1);		# tics: 1 min
    }
    elsif( $range < 1800 ){
	(300, $LT_HM, $MT_HR, 1, 5);		# tics: 5 min
    }
    elsif( $range_hrs < 2 ){
	(600, $LT_HM, $MT_HR, 1, 10);		# tics: 10 min
    }
    elsif( $range_hrs < 6 ){
	(1800, $LT_HR, $MT_MN, 1, 30);		# tics: 30 min
    }
    elsif( $range_hrs < 13 ){
	(3600, $LT_HR, $MT_MN, 2, 1);		# tics: 1 hr
    }
    elsif( $range_hrs < 25 ){
	(3600, $LT_HR, $MT_MN, 2, 2);		# tics: 2 hrs
    }
    elsif( $range_hrs < 50 ){
	(3600, $LT_HR, $MT_MN, 2, 4);		# tics: 4 hrs
    }
    elsif( $range_hrs < 75 ){
	(3600, $LT_HR, $MT_MN, 2, 6);		# tics: 6 hrs
    }

    # NB: days shorter or longer than 24 hours are corrected for below
    elsif( $range_days < 15 ){
	(3600*24, $LT_DW, $MT_SU, 3, 1);	# tics 1 day
    }
    elsif( $range_days < 22 ){
	(3600*24, $LT_DM, $MT_M1, 3, 2);	# tics: 2 days
    }
    elsif( $range_days < 80 ){
	(3600*24, $LT_DM, $MT_M1, 3, 7);	# tics: 7 days
    }
    elsif( $range_days < 168 ){
	(3600*24, $LT_DM, $MT_Y1, 3, 14);	# tics: 14 days
    }
    # NB: months shorter than 31 days are corrected for below
    elsif( $range_days < 370 ){
	(3600*24*31, $LT_DM, $MT_Y1, 4, 1);	# tics: 1 month
    }
    elsif( $range_days < 500 ){
	(3600*24*31, $LT_DM, $MT_Y1, 4, 2);	# tics: 2 month
    }
    elsif( $range_days < 1000 ){
	(3600*24*31, $LT_DM, $MT_Y1, 4, 3);	# tics: 3 month
    }
    elsif( $range_days < 2000 ){
	(3600*24*31, $LT_DM, $MT_NO, 4, 6);	# tics: 6 month
    }

    else{
	# NB: years less than 366 days are corrected for below
	(3600*24*366, $LT_YR, $MT_NO, 4, 12);	# tics: 1 yr
    }
}

sub xtic_align_initial {
    my $me   = shift;
    my $step = shift;

    my $t = ($step < 3600) ? (int($me->{xd_min} / $step) * $step)
	: (int($me->{xd_min} / 3600) * 3600);

    if( $step >= 3600*24*365 ){
	while(1){
	    # search for 1jan
	    my @lt = $me->{tm_time}($t);
	    last if $lt[4] == 0 && $lt[3] == 1 && $lt[2] == 0;
	    # jump fwd: 1M, 1D, or 1H
	    my $dt = ($lt[4] != 11) ? 24*30 : ($lt[3] < 30) ? 24 : 1;
	    $t += $dt * 3600;
	}
    }
    elsif( $step >= 3600*24*31 ){
	while(1){
	    # find 1st of mon
	    my @lt = $me->{tm_time}($t);
	    last if $lt[3] == 1 && $lt[2] == 0;
	    my $dt = ($lt[3] < 28) ? 24 : 1;
	    $t += $dt * 3600;
	}
    }
    elsif( $step >= 3600*24 ){
	while(1){
	    # search for midnight
	    my @lt = $me->{tm_time}($t);
	    last unless $lt[2];
	    $t += 3600;
	}
    }

    $t;
}

sub xtics {
    my $me = shift;
    my @tics;

    # this is good for (roughly) 10 mins - 10 yrs
    return if $me->{xd_max} == $me->{xd_min};

    my $range      = $me->{xd_max} - $me->{xd_min};
    my $range_hrs  = $range / 3600;
    my $range_days = $range_hrs / 24;

    my ($step, $labtyp, $marktyp, $lti, $tmod) = $me->xtic_range_data( $range );
    my $t = $me->xtic_align_initial( $step );

    # print "days: $range_days, lt: $labtyp, lti: $lti, tmod: $tmod, st: $step\n";
    # print STDERR "t: $t ", scalar(localtime $t), "\n";

    for( ; $t<$me->{xd_max}; $t+=$step ){
	my $redmark = 0;
	next if $t < $me->{xd_min};
	my @lt  = $me->{tm_time}($t);
	my @rlt = @lt;
	# months go from 0. days from 1. absurd!
	$lt[3]--;
	# mathematically, 28 is divisible by 7. but that just looks silly.
	$lt[3] = 22 if $lt[3] > 22 && $lti==3 && $tmod >= 7;

	if( $step >= 3600*24 && $lt[2] ){
	    # handle daylight saving time changes - resync to midnight
	    my $dt = ($lt[2] > 12 ? $lt[2] - 24 : $lt[2]) * 3600;
	    $dt += $lt[1] * 60;
	    $t -= $dt;
	    redo;
	}
	if( $step >= 3600*24*31 && $lt[3] ){
	    # some months are not 31 days!
	    # also corrects years that do not leap
	    my $dt = $lt[3] * 3600*24;
	    $t -= $dt;
	    redo;
	}

	next if $lt[$lti] % $tmod;
	next if $lt[3] && $lti > 3;
	next if $lt[2] && $lti > 2;
	next if $lt[1] && $lti > 1;
	next if $lt[0] && $lti > 0;


	$redmark = 1 if $marktyp == $MT_HR && !$lt[1];			# on the hour
	$redmark = 1 if $marktyp == $MT_MN && !$lt[2] && !$lt[1];	# midnight
	$redmark = 1 if $marktyp == $MT_SU && !$lt[6];			# sunday
	$redmark = 1 if $marktyp == $MT_M1 && !$lt[3];			# 1st of month
	$redmark = 1 if $marktyp == $MT_Y1 && !$lt[3] && !$lt[4];	# 1 jan

	my $label;
	# NB: strftime obeys LC_TIME for localized day/month names
	# (if locales are supported in the OS and perl)
	if( $labtyp == $LT_HM ){
	    $label = sprintf "%d:%0.2d", $rlt[2], $rlt[1];	# time
	}
	if( $labtyp == $LT_HR ){
	    if( $redmark ){
		$label = strftime("%d/%b", @rlt);		# date DD/Mon
	    }else{
		$label = sprintf "%d:%0.2d", $rlt[2], $rlt[1];	# time
	    }
	}
	if( $labtyp == $LT_DW ){
	    if( $redmark ){
		$label = strftime("%d/%b", @rlt);	# date DD/Mon
	    }else{
		$label = strftime("%a", @rlt);		# day of week
	    }
	}
	if( $labtyp == $LT_DM ){
	    if( !$lt[3] && !$lt[4] ){
		$label = $rlt[5] + 1900;		# year
	    }else{
		$label = strftime("%d/%b", @rlt);	# date DD/Mon
	    }
	}
	if( $labtyp == $LT_YR ){
	    $label = $rlt[5] + 1900; 			# year
	}
	push @tics, [$t, $redmark, $label];
    }
    $me->{grid}{x} = \@tics;

}

# it shall be inventoried, and every particle and utensil
# labelled to my will: as, item, two lips,
# indifferent red; item, two grey eyes, with lids to
# them; item, one neck, one chin, and so forth. Were
# you sent hither to praise me?
#   -- Shakespeare, Twelfth Night
sub clabels {
    my $me = shift;

    return unless $me->{draw_data_labels};

    my $rs = 0;
    my $rm = 0;
    if( $me->{data_label_style} eq 'box' ){
        $rs = 6;
        $rm = 3;
    }

    my( $tw, $r, @cl, @cx );
    $tw = $r = 0;
    # round the neck of the bottle was a paper label, with the
    # words 'DRINK ME' beautifully printed on it in large letters
    #   -- Alice in Wonderland
    foreach my $d (@{$me->{data}}){
	my $l = $d->{opts}{label};
	my $c = $d->{opts}{color};
	next unless $l;
	my $w = length($l) * 5 + 6;
	$w += $rm + $rs;

	if( $tw + $w > $me->{width} - $me->{margin_left} - $me->{margin_right} ){
	    $r ++;
	    $tw = 0;
	}
	push @cx, [$l, $tw, $r, $c];
	$tw += $w;
    }

    my $i = 0;
    foreach my $x (@cx){
        my $xx = $x->[1] + $me->{margin_left};
	my $y = $me->{height} - ($r - $x->[2] + 1) * 10;
	my $c = $x->[3];
        if( $rs ){
            $me->{img}->filledRectangle($xx, $y+1, $xx+$rs, $y+$rs+1, $me->color({color => $c}));
            $me->{img}->rectangle($xx, $y+1, $xx+$rs, $y+$rs+1, $me->{color}{black});
            $me->{img}->string(gdTinyFont, $xx+$rs+$rm, $y, $x->[0], $me->{color}{black});
        }else{
            $me->{img}->string(gdTinyFont, $xx, $y, $x->[0], $me->color({color => $c}));
        }
    }
    if( @cx ){
	$me->{margin_bottom} += ($r + 1) * 10;
	$me->adjust();
    }
}

sub plot_data {
    my $me = shift;
    my $data = shift;
    my $opts = shift;
    my $shadow = shift;

    return unless $data && @$data;

    # 'What did they draw?' said Alice, quite forgetting her promise.
    #   -- Alice in Wonderland
    if( $opts->{style} eq 'line' ){
	# 'You can draw water out of a water-well,' said the Hatter
	#   -- Alice in Wonderland
	$me->draw_line( $data, $opts, $shadow );
    }
    elsif( $opts->{style} eq 'filled' ){
	# I should think you could draw treacle out of a treacle-well
	#    -- Alice in Wonderland
	$me->draw_filled( $data, $opts, $shadow );
    }
    elsif( $opts->{style} eq 'range' ){
	# did you ever see such a thing as a drawing of a muchness?
	#    -- Alice in Wonderland
	$me->draw_range( $data, $opts, $shadow );
    }elsif( $opts->{style} eq 'points' ){
        # and they drew all manner of things--everything that begins with an M--'
	#    -- Alice in Wonderland
	$me->draw_points( $data, $opts, $shadow );
    }elsif( $opts->{style} eq 'box' ){
	$me->draw_boxes( $data, $opts, $shadow );
    }else{
	croak "unknown graph style--cannot draw";
    }
}

# A flattering painter, who made it his care
# To draw men as they ought to be, not as they are.
#   -- Oliver Goldsmith, Retaliation

sub draw_filled {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;
    my $shadow = shift;

    my $im = $me->{img};
    my $limit = $me->{limit_factor} * ($me->{xd_max} - $me->{xd_min}) / @$data;
    my $skipundef = $opts->{skip_undefined} || $me->{skip_undefined};
    my $thick     = $opts->{thickness} || $me->{thickness};
    my $smooth    = $opts->{smooth} || $me->{smooth};
    my $shcolor   = $shadow ? $me->img_color($shadow->{color} || $me->{shadow_color} ) : undef;
    my($px, $py, $pxdpt, $pydpt, $pdydx);
    my $ypt0 = $me->ypt(0);

    $thick += $shadow->{dw} if $shadow;
    $me->set_thickness( $thick ) if $thick;

    foreach my $s ( @$data ){
	my $x = $s->{time};
	my $y = $s->{value};

	next if $x < $me->{xd_min} || $x > $me->{xd_max};

	my $xdpt  = $me->xdatapt($x);
	my $ydpt  = $me->ydatapt($y);
        my $dydx;

        if( $shadow ){
            $xdpt += $shadow->{dx};
            $ydpt += $shadow->{dy};
        }

	if( defined($y) || !$skipundef ){
            my $color = $shadow ? $shcolor : $me->color($s, $opts);

	    if( defined($px) && ($xdpt - $pxdpt > 1) && (!$limit || $x - $px <= $limit) ){
                if( $smooth ){
                    next unless defined $s->{dydx};
                    $dydx  = - $s->{dydx} * $me->{yd_scale} / $me->{xd_scale};
                    $me->curve($pxdpt, $pydpt, $pdydx,
                               $xdpt,  $ydpt,  $dydx,
                               $smooth, \&curve_filled, [$color, $ypt0]);
                }else{
                    my $poly = GD::Polygon->new;
                    $poly->addPt($pxdpt, $ypt0);
                    $poly->addPt($pxdpt, $pydpt);
                    $poly->addPt($xdpt,  $ydpt);
                    $poly->addPt($xdpt,  $ypt0);
                    $im->filledPolygon($poly, $color);
                }
	    }else{
		$im->line( $xdpt, $ypt0,
			   $xdpt, $ydpt,
                           $color);
	    }
	    $px = $x; $pxdpt = $xdpt;
	    $py = $y; $pydpt = $ydpt;
            $pdydx = $dydx;
	}else{
	    $px = undef;
	}
    }
    $me->set_thickness( 1 ) if $thick;
}

sub draw_line {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;
    my $shadow = shift;

    my $im = $me->{img};
    my $limit = $me->{limit_factor} * ($me->{xd_max} - $me->{xd_min}) / @$data;
    my $thick = $opts->{thickness} || $me->{thickness};
    my $skipundef = $opts->{skip_undefined} || $me->{skip_undefined};
    my $smooth    = $opts->{smooth} || $me->{smooth};
    my($px, $py, $pxdpt, $pydpt, $pdydx);

    $thick += $shadow->{dw} if $shadow;
    $me->set_thickness( $thick ) if $thick;

    my $shcolor = $shadow ? $me->img_color($shadow->{color} || $me->{shadow_color} ) : undef;

    foreach my $s ( @$data ){
	my $x = $s->{time};
	my $y = $s->{value};

	next if $x < $me->{xd_min} || $x > $me->{xd_max};

	my $xdpt  = $me->xdatapt($x);
	my $ydpt  = $me->ydatapt($y);
        my $dydx  = $smooth ? - $s->{dydx} * $me->{yd_scale} / $me->{xd_scale} : undef;

        if( $shadow ){
            $xdpt += $shadow->{dx};
            $ydpt += $shadow->{dy};
        }

	if( defined($y) || !$skipundef ){
            my $color = $shadow ? $shcolor : $me->color($s, $opts);

            if( $me->{antialias} && $thick == 1 ){
                # GD cannot antialias a thick line
                $im->setAntiAliased($color);
                $color = gdAntiAliased;
            }

	    if( defined($px) && (!$limit || $x - $px <= $limit) ){
                if( $smooth ){
                    next unless defined $s->{dydx};
                    $me->curve($pxdpt, $pydpt, $pdydx,
                               $xdpt,  $ydpt,  $dydx,
                               $smooth, \&curve_line, [$color]);
                }else{
                    $im->line( $pxdpt, $pydpt,
                               $xdpt,  $ydpt,
                               $color );
                }
	    }else{
		$im->setPixel($xdpt,  $ydpt,
			      $color );
	    }
	    $px = $x; $pxdpt = $xdpt;
	    $py = $y; $pydpt = $ydpt;
            $pdydx = $dydx;
	}else{
	    $px = undef;
	}
    }
    $me->set_thickness( 1 ) if $thick;
}

# GD has only circular arcs, not bezier or cubic splines
# bezier math is easier than trying to use circular arcs
sub curve {
    my $me = shift;
    my( $x0, $y0, $dydx0,
        $x1, $y1, $dydx1,
        $smooth, $fnc, $args ) = @_;

    # pick bezier control points
    #   smooth = (.5 - 1) gives nice curves
    #   smooth > 1 gives straighter segments
    #   smooth <= .5 takes the graph on a drug trip
    my $dxt = ($x1 - $x0) / ($smooth * 3);
    my $cx0 = $x0 + $dxt;
    my $cx1 = $x1 - $dxt;
    my $cy0 = $y0 + $dydx0 * $dxt;
    my $cy1 = $y1 - $dydx1 * $dxt;

    # bezier coefficients
    my $ax =     - $x0 + 3 * $cx0 - 3 * $cx1 + $x1;
    my $ay =     - $y0 + 3 * $cy0 - 3 * $cy1 + $y1;
    my $bx =   3 * $x0 - 6 * $cx0 + 3 * $cx1;
    my $by =   3 * $y0 - 6 * $cy0 + 3 * $cy1;
    my $cx = - 3 * $x0 + 3 * $cx0;
    my $cy = - 3 * $y0 + 3 * $cy0;
    my $dx =       $x0;
    my $dy =       $y0;

    # draw bezier curve
    my $px = $x0;
    my $py = $y0;

    # my $im = $me->{img};
    # $im->line($x0,$y0, $cx0,$cy0, $me->img_color('00ff00'));
    # $im->line($x1,$y1, $cx1,$cy1, $me->img_color('00ff00'));
    # $im->line($cx0,$cy0, $cx1,$cy1, $me->img_color('0000ff'));

    my $ymax = $me->{height} - $me->{margin_bottom};
    my $ymin = $me->{margin_top};

    my $T = ($x1 - $x0) + abs($y1 - $y0);
    for my $tt (1 .. $T){
        my $t = $tt / $T;
        my $x = $ax * $t**3 + $bx * $t**2 + $cx * $t + $dx;
        my $y = $ay * $t**3 + $by * $t**2 + $cy * $t + $dy;

        # QQQ - handle out-of-bounds segments how?
        if( $y >= $ymin && $y <= $ymax && $py >= $ymin && $py <= $ymax ){
            $fnc->($me, $px,$py, $x,$y, 0, @$args);
        }else{
            $fnc->($me, $px,$py, $x,$y, [$ymin, $ymax], @$args);
        }
        $px = $x; $py = $y;
    }
}

sub curve_line {
    my $me = shift;
    my ($px, $py, $x, $y, $oob, $color) = @_;

    return if $oob;
    $me->{img}->line($px,$py, $x,$y, $color);
}

sub curve_filled {
    my $me = shift;
    my ($px, $py, $x, $y, $oob, $color, $y0) = @_;

    if( $oob ){
        my($ymin, $ymax) = @$oob;
        $y  = $ymin if $y  < $ymin;
        $py = $ymin if $py < $ymin;
        $y  = $ymax if $y  > $ymax;
        $py = $ymax if $py > $ymax;
    }

    my $poly = GD::Polygon->new;
    $poly->addPt($px, $y0);
    $poly->addPt($px, $py);
    $poly->addPt($x,  $y);
    $poly->addPt($x,  $y0);
    $me->{img}->filledPolygon($poly, $color);
}


sub draw_range {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;
    my $shadow = shift;

    return if $shadow;
    my $im = $me->{img};
    my $limit = $me->{limit_factor} * ($me->{xd_max} - $me->{xd_min}) / @$data;
    my $skipundef = $opts->{skip_undefined} || $me->{skip_undefined};
    my($px, $pn, $pm, $pxdpt);

    foreach my $s ( @$data ){
	my $x = $s->{time};
	my $a = defined $s->{min} ? $s->{min} : $s->{value};
	my $b = defined $s->{max} ? $s->{max} : $s->{value};
	my $xdpt  = $me->xdatapt($x);

	next if $x < $me->{xd_min} || $x > $me->{xd_max};

	$a = $b if !defined($a) && $skipundef;
	$b = $a if !defined($b) && $skipundef;

	if( defined($a) || !$skipundef ){

	    if( defined($px) && ($xdpt - $pxdpt > 1) && (!$limit || $x - $px <= $limit) ){
		my $poly = GD::Polygon->new;
		$poly->addPt($pxdpt, $me->ydatapt($pn));
		$poly->addPt($pxdpt, $me->ydatapt($pm));
		$poly->addPt($xdpt,  $me->ydatapt($b));
		$poly->addPt($xdpt,  $me->ydatapt($a));
		$im->filledPolygon($poly, $me->color($s, $opts));
	    }else{
		$im->line( $xdpt,  $me->ydatapt($b),
			   $xdpt,  $me->ydatapt($a),
			   $me->color($s, $opts) );
	    }
	    $px = $x; $pn = $a; $pm = $b;
	    $pxdpt = $xdpt;
	}else{
	    $px = undef;
	}
    }
}

sub draw_points {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;
    my $shadow = shift;

    my $im = $me->{img};
    my $skipundef = $opts->{skip_undefined} || $me->{skip_undefined};
    my $shcolor   = $shadow ? $me->img_color($shadow->{color} || $me->{shadow_color} ) : undef;

    foreach my $s ( @$data ){
	my $x = $s->{time};
	my $y = $s->{value};
	my $d = $s->{diam} || $opts->{diam} || 4;
	my $c = $shadow ? $shcolor : $me->color($s, $opts);

	next if $x < $me->{xd_min} || $x > $me->{xd_max};
	next if !defined($y) && $skipundef;
	my $xdpt = $me->xdatapt($x);
	my $ydpt = $me->ydatapt($y);

        if( $shadow ){
            $d    += $shadow->{dw};
            $xdpt += $shadow->{dx};
            $ydpt += $shadow->{dy};
        }

	while( $d > 0 ){
	    $im->arc( $xdpt, $ydpt,
		      $d, $d, 0, 360,
		      $c );
	    $d -= 2;
	}
    }
}

sub def_box_width {
    my $ta = shift;
    my $tb = shift;
    my $nd = shift;

    return ($tb - $ta) / ($nd - 1) if $nd > 1;
    return ($tb - $ta) / $nd       if $nd;
    1;
}

sub draw_boxes {
    my $me   = shift;
    my $data = shift;
    my $opts = shift;
    my $shadow = shift;

    my $im = $me->{img};
    my $defwid = def_box_width($data->[0]{time}, $data->[-1]{time}, scalar(@$data));
    my $thick  = $opts->{thickness} || $me->{thickness};
    my $skipundef = $opts->{skip_undefined} || $me->{skip_undefined};
    my $shcolor = $shadow ? $me->img_color($shadow->{color} || $me->{shadow_color} ) : undef;

    $thick += $shadow->{dw} if $shadow;
    $me->set_thickness( $thick ) if $thick;

    foreach my $s ( @$data ){
	my $x = $s->{time};
	my $y = $s->{value};
	my $w = $s->{width} || $opts->{width} || $me->{boxwidth} || $defwid;
	my $y0 = $opts->{boxbase} || $me->{boxbase} || 0;
        my $c = $shadow ? $shcolor : $me->color($s, $opts);

	next if $x < $me->{xd_min} || $x > $me->{xd_max};
	next if !defined($y) && $skipundef;

	# because GD cares...
	my $ya = $me->ydatapt($y > $y0 ? $y : $y0);
	my $yb = $me->ydatapt($y > $y0 ? $y0 : $y);
        my $xa = $me->xdatapt($x - $w/2);
        my $xb = $me->xdatapt($x + $w/2);

        if( $shadow ){
            $xa += $shadow->{dx};
            $xb += $shadow->{dx};
            $ya += $shadow->{dy};
            $yb += $shadow->{dy};
        }

	if( $opts->{filled} || $s->{filled} ){
	    $im->filledRectangle( $xa, $ya, $xb, $yb, $c);
	}else{
	    $im->rectangle( $xa, $ya, $xb, $yb, $c);
	}
    }

    $me->set_thickness( 1 ) if $thick;
}


=head1 EXAMPLE IMAGES

    http://argus.tcp4me.com/shots.html
    http://search.cpan.org/src/JAW/Chart-Strip-1.07/eg/index.html

=head1 LICENSE

This software may be copied and distributed under the terms
found in the Perl "Artistic License".

A copy of the "Artistic License" may be found in the standard
Perl distribution.

=head1 BUGS

There are no known bugs in the module.

=head1 SEE ALSO

    Yellowstone National Park.

=head1 AUTHOR

    Jeff Weisberg - http://www.tcp4me.com

=cut
    ;

1;
