package CGI::Graph::Plot::bars;

use CGI::Graph::Plot;
use GD::Graph::bars;

@ISA = ("CGI::Graph::Plot");

%default = (	y_tick_number   => 8,
                y_label_skip    => 2,
                r_margin        => 7,
		precision	=> 14,
	        header_size 	=> 15,   # default
	        space_size 	=> 18,   # values for
	        data_size 	=> 100   # text box
);

#
# calls parent class to intialize values.
#

sub new {
	my ($pkg, $vars) = @_;
	my $class = ref($pkg) || $pkg;
        $vars->{graph_type} = 'bar';
        $self=$class->SUPER::new($vars);

	return bless $self, $class;
}

#
# determines upper and lower bounds for the grid.
#

sub gridBounds {
        my $self = shift;

        my ($Xref,$Yref) = $self->count();
        my @Y = @$Yref;

        return (0,1,0,(CGI::Graph::Plot::bounds(@Y))[1]);
}

#
# determines upper and lower bounds for the main graph image or map.
#

sub graphBounds {
        my ($self) = @_;

        my ($Xref,$Yref) = $self->count();

	# Y axis is numerical, use bounds to determine min/max
        my @Y = @$Yref;
        my ($y_min,$y_max) = CGI::Graph::Plot::bounds(@Y);

	# use fractions for x min/max
        my ($xc,$yc,$span) = $self->resize();

        my $x_min = sprintf("%.$default{precision}f", 
		($xc-$span/2)/$self->{'divisions'});
        my $x_max = sprintf("%.$default{precision}f", 
		($xc+$span/2)/$self->{'divisions'});

        $y_max = sprintf("%.$default{precision}f", 
		$y_max*($yc+.5)/$self->{'divisions'}) 
		if ($self->{zoom_type}=~/^unlocked/);

	$y_max = ($y_max>1)?int($y_max+.5):1 
		if ($self->{zoom_type} eq 'unlocked int');

	($self->{x_min},$self->{x_max},$self->{y_min},$self->{y_max}) = 
		($x_min,$x_max,0,$y_max);
}

#       
# initializes the graph for the graphMap and drawGraph functions.
#

sub setGraph {
	my ($self,$graph) = @_;

        $graph->set(
		x_labels_vertical => 1,
		x_label_position  => .5,
		y_number_format   => \&shorten,
		x_label           => substr($self->{X},2),
		y_label           => "count",
                y_min_value       => $self->{y_min},
                y_max_value       => $self->{y_max},
                r_margin          => $default{r_margin},
                y_tick_number     => $default{y_tick_number},
                y_label_skip      => $default{y_label_skip}
        );

	return $graph;
}

#
# generates an image map which allows individual points to be selected. Also 
# displays properties of the points in a textbox.
#

sub graphMap {
        my ($self,$name,$mapName) = @_;

	# obtain X and Y values to be drawn
	my ($fullXref,$Xref,$Yref,$Sref) = $self->valuesInRange();
	my @X = @$Xref;
	my @Y = @$Yref;
	# array storying number of elements selected for each value of X
	my @selectDraw = @$Sref;  
	my @dataX = @$fullXref; # X value that has not been shortened

	# set up graph and plot points
        my $graph = GD::Graph::bars->new($self->{width},$self->{height});
	$graph = $self->setGraph($graph);
        my @data = ([@X],[@Y]);
        my $gd = $graph->plot(\@data);

        my @setlist = $graph->get_hotspot;

        my $index=0;
        my $bar_count=1;
	my $mapInfo = $self->mapInfo();

        my $final = "\n<map name=\"$mapName\">\n";

        for $setnum (1.. $#setlist) {
                foreach $set (@{$setlist[$setnum]}) {
                        my $text = sprintf "%-$default{'space_size'}.".
				"$default{'header_size'}s",substr($self->{X},2);
                        $text.= sprintf "%-$default{'data_size'}.".
				"$default{'data_size'}s",$dataX[$bar_count-1];
                        $text.="\\n";
                        $text.= sprintf "%-$default{'space_size'}.".
				"$default{'header_size'}s","count";
                        $text.= sprintf "%-.$default{'data_size'}s",
				$Y[$bar_count-1];

			#escape ' characters
                        $text=~s/\'/\\\'/;

			my $select_fraction = ($Y[$bar_count-1] > 0) ?
				$selectDraw[$bar_count-1]/$Y[$bar_count-1] : 0;
                        $y_mid = $$set[2]+$select_fraction*($$set[4]-$$set[2]);

			# map area for selected portion of bar
                        $final.= "<area alt=\"$dataX[$bar_count-1]\n";
			$final.= "$Y[$bar_count-1]\" "; 
			$final.= "shape=$$set[0] coords=$$set[1],";
                        $final.= "$$set[2],$$set[3],$y_mid ";
                        $final.= "href=\"$name?select=$bar_count&";
			$final.= "select_type=unselect&";
			$final.= $mapInfo;
                        $final.= " onMouseOver=\"myform.myarea.value='$text';";
			$final.= "return true;\">\n";

			# map area for unselected portion of bar
                        $final.= "<area alt=\"$dataX[$bar_count-1]\n";
			$final.= "$Y[$bar_count-1]\"";
			$final.= "shape=$$set[0] coords=$$set[1],";
                        $final.= "$y_mid,$$set[3],$$set[4] ";
                        $final.= "href=\"$name?select=$bar_count&";
			$final.= "select_type=select&";
			$final.= $mapInfo;
                        $final.= " onMouseOver=\"myform.myarea.value='$text';";
			$final.= "return true;\">\n";

                        $bar_count++;
                        $index++;
                }
        }

        $final.= "</map>\n";

        return $final;
}

# 
# returns a graph image (as a gd object) with selected points highlighted in 
# green
# 

sub drawGraph {
	my ($self) = @_;

	my (undef,$Xref,$Yref,$Sref) = $self->valuesInRange();
	my @X = @$Xref;
	my @Y = @$Yref;
	my @selectDraw = @$Sref;

        my $graph = GD::Graph::bars->new($self->{width}, $self->{height});
	$graph = $self->setGraph($graph);
        my @data = ([@X],[@Y]);

        my @dataColor = GD::Graph::colour::hex2rgb($self->{dataColor});
        GD::Graph::colour::add_colour(myColor => \@dataColor);
        $graph->set(dclrs => ["myColor"]);

        my $gd = $graph->plot(\@data);
	my @setlist = $graph->get_hotspot;

        my @selectColor = GD::Graph::colour::hex2rgb($self->{selectColor});
        $selectColor = $gd->colorAllocate(@selectColor);
        my $index=0;

	# color selected portion of bars
        for $setnum (1.. $#setlist) {
                foreach $set (@{$setlist[$setnum]}) {
                        if ($$set[0] eq 'rect' && $selectDraw[$index]) {
                                $select_fraction = 
					$selectDraw[$index]/$Y[$index];
                                $y_mid = $$set[2] + 
					$select_fraction*($$set[4]-$$set[2]);
                                $gd->rectangle($$set[1],$$set[2],$$set[3],
					$y_mid,$selectColor);
                                $gd->rectangle($$set[1]+1,$$set[2]+1,$$set[3]-1,
					$y_mid-1,$selectColor);
                        }

                        $index++;
                }
	}

	return $gd;
}

#
# returns a gd object similar to drawGraph, but with axes hidden
#

sub drawGrid {
	my ($self,$dataColor,$selectColor,$lineColor,$windowColor) = @_;

	my (undef,$Xref,$Yref,$Sref) = $self->valuesInRange();
	my @X = @$Xref;
	my @Y = @$Yref;
	my @selectDraw = @$Sref;

	# create a graph that is larger than necessary
        my $graph = GD::Graph::bars->new(2*$self->{grid_width}, 2*$self->{grid_height});

	my @data = ([@X],[@Y]);

        $graph->set(
		fgclr		  => "white", # hide axes
                y_min_value       => $self->{y_min},
                y_max_value       => $self->{y_max},
                r_margin          => $default{r_margin},
                y_tick_number     => $default{y_tick_number},
                y_label_skip      => $default{y_label_skip}
        );

        my @dataColor = GD::Graph::colour::hex2rgb($self->{dataColor});
        GD::Graph::colour::add_colour(myColor => \@dataColor);
        $graph->set(dclrs => ["myColor"]);

        my $gd = $graph->plot(\@data);
        my @setlist = $graph->get_hotspot;

        my @selectColor = GD::Graph::colour::hex2rgb($self->{selectColor});
        $selectColor = $gd->colorAllocate(@selectColor);

        my $index=0;
        
	# color selected portion of bars
        for $setnum (1.. $#setlist) {
                foreach $set (@{$setlist[$setnum]}) {
                        if ($$set[0] eq 'rect' && $selectDraw[$index]) {
                                $select_fraction = 
					$selectDraw[$index]/$Y[$index];
                                $y_mid = $$set[2] + 
					$select_fraction*($$set[4]-$$set[2]);
                                $gd->rectangle($$set[1],$$set[2],$$set[3],
					$y_mid,$selectColor);
                                $gd->rectangle($$set[1]+1,$$set[2]+1,$$set[3]-1,
					$y_mid-1,$selectColor);
                        } 
                        
                        $index++;
                }                       
        }                       

	# create new blank image of correct size
        my $image = new GD::Image($self->{grid_width},$self->{grid_height});
        my $white = $image->colorAllocate(255,255,255);
        
	# copy only the area of the graph that has data plotted
        $image->copyResized($gd,0,0,$graph->{left},$graph->{top},$self->{grid_width},
		$self->{grid_height},$graph->{right}-$graph->{left},
		$graph->{bottom}-$graph->{top});

        $image = $self->gridLines($image);
        return $image;
}

sub shorten {
        my $value = shift;
        return sprintf ("%g", $value);
}

#
# returns the center and span of the current view, relative to the number of
# divisions.
#

sub resize {
        my $self = shift;

        #calculate effects of center, zoom, and layers
        #fraction of full length
        my @center = split(/,/, $self->{center});

        my $span = (2**(5-$self->{zoom})+1);
        $span = 1 if ($self->{zoom} >= 5);

        my $xc = ($center[0]-.5);
        my $yc = ($self->{divisions}-$center[1]+.5);

        # shift center to avoid going out of bounds
        if (($xc-$span/2) < 0) {
                $xc+=(-1*($xc-$span/2));
        }
        elsif (($xc+$span/2) > $self->{divisions}) {
                $xc-= $xc+$span/2-$self->{divisions};
        }

	$yc = $self->{divisions}/2 unless ($self->{zoom_type}=~/^unlocked/);

        # update center in object
        my $center = ($xc+.5).",".($self->{divisions}+1-($yc+.5));
        $self->{center} = $center;

        return ($xc,$yc,$span);
}

#
# adds grid lines to an image, depending on the number of divisions. Also draws
# in the blue center marker and view window.
#

sub gridLines {
        my ($self,$image) = @_;

        my @lineColor = GD::Graph::colour::hex2rgb($self->{lineColor});
        $lineColor = $image->colorAllocate(@lineColor);

        my @windowColor = GD::Graph::colour::hex2rgb($self->{windowColor});
        $windowColor = $image->colorAllocate(@windowColor);

        #draw horizontal lines (move vertically)
        my $Vinc = $self->{grid_height}/$self->{divisions};
        for (0..$self->{divisions}-1) {
                $y = $_*$Vinc;
                $image->line(0,$y,$self->{grid_width}-1,$y,$lineColor);
        }
        #draw last line
        $image->line(0,$self->{grid_height}-1,$self->{grid_width}-1,$self->{grid_height}-1,
                $lineColor);

        #draw vertical lines (move horizontally)
        my $Hinc = $self->{grid_width}/$self->{divisions};
        for (0..$self->{divisions}-1) {
                $x = $_*$Hinc;
                $image->line($x,0,$x,$self->{grid_height}-1,$lineColor);
        }
        #draw last line
        $image->line($self->{grid_width}-1,0,$self->{grid_width}-1,$self->{grid_height}-1,
                $lineColor);

        # determine center position and size of view window
        @center = split(/,/, $self->{center});
        $span = (2**(5-$self->{zoom})+1);
        $span = (2**(5-$self->{zoom})) if ($self->{zoom} >= 5);

        #draw center marker
        $x1 = ($center[0]-1)*$Hinc;
        $x2 = $center[0]*$Hinc;
        $y1 = ($center[1]-1)*$Vinc;
        $y2 = $center[1]*$Vinc;
        $image->filledRectangle($x1,$y1,$x2,$y2,$windowColor);

        # determine coordinates for view window and draw it
        $x1 = ($center[0]-.5-$span/2)*$Hinc;
        $x2 = ($center[0]-.5+$span/2)*$Hinc;

        # bar graph does not zoom in with respect to Y axis
        $y1 = ($self->{zoom_type}=~/^unlocked/)?($center[1]-1)*$Vinc:0;
	$y2 = ($self->{grid_height}-1);

        $x2-- if ($x2==$self->{grid_width});
        $y2-- if ($y2==$self->{grid_height});

        $image->rectangle($x1,$y1,$x2,$y2,$windowColor);
        $image->rectangle($x1+1,$y1+1,$x2-1,$y2-1,$windowColor);

        return $image;
}

1;
