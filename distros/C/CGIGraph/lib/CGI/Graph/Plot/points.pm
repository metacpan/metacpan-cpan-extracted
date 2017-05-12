package CGI::Graph::Plot::points;

use GD;
use CGI::Graph::Plot;
use GD::Graph::points;

@ISA = ("CGI::Graph::Plot");

my %default = ( x_tick_number  => 8,
                y_tick_number  => 8,
                y_label_skip   => 2,
                r_margin       => 7,
		label_offset   => 65,
		label_size     => 12,
		tick_size      => 4,
		precision      => 14,
                header_size    => 15,   # default
                space_size     => 18,   # values for
                data_size      => 100   # text box
              );

#
# calls parent class to intialize values, then updates selection values if
# necessary. If called from the CGI that is generating the image, then the 
# bounds should not be calculated and the selection values not updated (since 
# these have already been done).
#

sub new {
        my ($pkg, $vars) = @_;
        my $class = ref($pkg) || $pkg;
	$vars->{graph_type} = 'points';
        my $self = $class->SUPER::new($vars);

        # for a point graph, if the Y axis is not numerical,
        # find a numerical data set
        if ($self->{Y} !~ /^[ir]_/) {
		my @header = $self->{table}->header;
                foreach (1..$#header) {
                        $self->{Y} = $header[$_];
                        last if ($self->{Y} =~ /^[ir]_/);
                }
                die "No numerical Y data available!\n" if ($self->{Y} !~ /^[ir]_/);
        }

        # for calls within Draw.cgi, return now
        if ($self->{rand}) {
                return bless $self, $class;
        }

        $self->graphBounds();

        my @selected = split("",$self->{selected});
        if ($self->{select}) {
                $selected[$self->{select}-1]=($selected[$self->{select}-1])?0:1;
        }

	elsif ($self->{select_list} eq 'Visible' || $self->{unselect_list} eq 'Visible') {
	        my ($Xref,$Yref) = $self->valuesInRange();
	        my @drawY = @$Yref;

		foreach (0..$#drawY) {
			if (defined $drawY[$_]) {
				$selected[$self->{table}->elm($_,'_row')-1] = 
					($self->{select_list} eq 'Visible')?1:0;
			}
		}
	}

       	$self->{selected} = join("",@selected);
	$self->write_selected();

        return bless $self, $class;
}

#
# determines upper and lower bounds for the grid.
#

sub gridBounds {
        my $self = shift;

        my @X = $self->{table}->col($self->{X});
        my @Y = $self->{table}->col($self->{Y});
        @X = $self->count(@X);

        return (0,$X[-1],CGI::Graph::Plot::bounds(@Y)) unless ($self->{X} =~/^[ir]_/);
        return (CGI::Graph::Plot::bounds(@X),CGI::Graph::Plot::bounds(@Y));
}

#
# determines upper and lower bounds for the main graph image or map.
#

sub graphBounds {
        my $self = shift;
        
        my @X = $self->{table}->col($self->{X});
        my @Y = $self->{table}->col($self->{Y});
        
        @X = $self->count(@X);

        my ($x_min,$x_max) = ($self->{X} =~/^[ir]_/) ? 
		CGI::Graph::Plot::bounds(@X) : (0,$X[-1]);

        my ($y_min,$y_max) = CGI::Graph::Plot::bounds(@Y);
        
	# for zoom level 1, update self using present min/max values
        if ($self->{zoom} == 1) {
                $self->resize();
                ($self->{x_min},$self->{x_max},$self->{y_min},$self->{y_max}) =
			($x_min,$x_max,$y_min,$y_max);
                return;
        }
        
	# for zoom levels other than 1, adjust the min/max
        else {  
                my ($xc,$yc,$span) = $self->resize();
                
                my $deltaX = $x_max-$x_min;
                $x_max2 = sprintf("%.".$default{precision}."f", 
			$x_min+($xc+$span/2)*($deltaX)/$self->{divisions});
                $x_min2 = sprintf("%.".$default{precision}."f", 
			$x_min+($xc-$span/2)*($deltaX)/$self->{divisions});
                
                my $deltaY = $y_max-$y_min;
                $y_max2 = sprintf("%.".$default{precision}."f", 
			$y_min+($yc+$span/2)*($deltaY)/$self->{divisions});
                $y_min2 = sprintf("%.".$default{precision}."f", 
			$y_min+($yc-$span/2)*($deltaY)/$self->{divisions});
                
                ($self->{x_min},$self->{x_max},$self->{y_min},$self->{y_max}) =
			($x_min2,$x_max2,$y_min2,$y_max2);
                return;
        }
}

#
# initializes the graph for the graphMap and drawGraph functions.
#

sub setGraph {
        my ($self,$graph) = @_;

        $graph->set(
		x_number_format   => \&shorten,
		y_number_format   => \&shorten,
                x_label           => substr($self->{X},2),
		x_label_position  => .5,
                y_label           => substr($self->{Y},2),
                x_min_value       => $self->{x_min},
                x_max_value       => $self->{x_max},
                y_min_value       => $self->{y_min},
                y_max_value       => $self->{y_max},
                r_margin          => $default{r_margin},
                x_tick_number     => $default{x_tick_number},
                y_tick_number     => $default{y_tick_number},
                y_label_skip      => $default{y_label_skip}
        );

	# for non-numerical X data
	unless ($self->{X} =~ /^[ir]_/) {
	        $graph->set(
			x_number_format   => \&x_erase,
                	x_tick_number     => 1,
			x_labels_vertical => 1
	        );
	}
		
	return $graph;
}

#
# generates an image map which allows individual points to be selected. Also 
# displays properties of the points in a textbox.
# 

sub graphMap {
	my ($self,$name,$mapName,$info) = @_;
        
	# obtain X and Y values to be drawn
        my($Xref,$Yref) = $self->valuesInRange();
        my @drawX = @$Xref;
        my @drawY = @$Yref;

	# set up graph and plot points
        my $graph = GD::Graph::points->new($self->{width},$self->{height});
	$graph = $self->setGraph($graph);
        my @data = ([@drawX],[@drawY]);
        my $gd = $graph->plot(\@data);

	my @info = $self->{table}->col($info);
	my @row = $self->{table}->col('_row');
        my @setlist = $graph->get_hotspot;
        my @header = $self->{table}->header;
        my $index= 0;

        my $mapInfo = $self->mapInfo();
        my $final = "\n<map name=\"$mapName\">\n";

        for $setnum (1.. $#setlist) {

                foreach $set (@{$setlist[$setnum]}) {

			# set up string used for text box
                        my $text;
                        for ($i=0; $i<$self->{table}->nofCol-1; $i++) { 
                                $text.= sprintf("%-$default{header_size}.".
					"$default{space_size}s",substr($header[$i],2));
                                $text.= sprintf("%-.$default{data_size}s",
					$self->{table}->elm($index,$i));
                                $text.="\\n";
                        }
                        #escape ' characters
                        $text=~s/\'/\\\'/;

                        $final.= "<area alt=\"$info[$index]\" ";
			$final.= "shape=$$set[0] coords=$$set[1],";
                        $final.= "$$set[4],$$set[2],$$set[3] "; 
			# note that there is an error in documentation
			# arguments are in wrong order
                        $final.= "href=\"$name?select=$row[$index]&$mapInfo";
                        $final.= " onMouseOver=\"myform.myarea.value='$text'; ";
			$final.= "return true;\">\n";

                        $index++;
                }
        }   
        $final.= "</map>\n";

        return $final;
}

#
# returns a graph image (as a gd object) with selected points highlighted
#

sub drawGraph {
        my ($self) = @_;

        my($Xref,$Yref,$Sref) = $self->valuesInRange();
        my @drawX = @$Xref;
        my @drawY = @$Yref;
	my @selectDraw = @$Sref;

        my $graph = GD::Graph::points->new($self->{width}, $self->{height});
	$graph = $self->setGraph($graph);
        my @data = ([@drawX],[@drawY]);

	my @dataColor = GD::Graph::colour::hex2rgb($self->{dataColor});
        GD::Graph::colour::add_colour(myColor => \@dataColor);
        $graph->set(dclrs => ["myColor"]);

        my $gd = $graph->plot(\@data);
	my @setlist = $graph->get_hotspot;

        my @selectColor = GD::Graph::colour::hex2rgb($self->{selectColor});
        $selectColor = $gd->colorAllocate(@selectColor);
	my $index=0;
	
	# draw rectangle around each selected point
	for $setnum (1.. $#setlist) {
	        foreach $set (@{$setlist[$setnum]}) {

	                if ($$set[0] eq 'rect' && $selectDraw[$index]) {
	                        $gd->rectangle($$set[1],$$set[4],
					$$set[2],$$set[3],$selectColor);
	                        $gd->rectangle($$set[1]+1,$$set[4]+1,
					$$set[2]-1,$$set[3]-1,$selectColor);
	                }

	                $index++;
	        }
	}

	$gd = &addLabels($self,$gd,$graph) unless ($self->{X} =~ /^[ir]_/);

	return $gd;
}

#
# returns a gd object similar to drawGraph, but with axes hidden
#

sub drawGrid {
	my ($self,$dataColor,$selectColor,$lineColor,$windowColor) = @_;

        my($Xref,$Yref,$Sref) = $self->valuesInRange();
        my @X = @$Xref;
        my @Y = @$Yref;
        my @selectDraw = @$Sref;

	# create a graph that is larger than necessary
        my $graph = GD::Graph::points->new(2*$self->{grid_width},2*$self->{grid_height}); 
        
        my @data = ([@X],[@Y]);
        
        $graph->set(
		fgclr		  => "white", # hide axes
                x_tick_number     => 1,
                x_min_value       => $self->{x_min},
                x_max_value       => $self->{x_max},
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

	# draw rectangle around each selected point
        for $setnum (1.. $#setlist) {
                foreach $set (@{$setlist[$setnum]}) {

	                if ($$set[0] eq 'rect' && $selectDraw[$index]) {
                                $gd->filledRectangle($$set[1],$$set[4],
					$$set[2],$$set[3],$selectColor);
	                        $gd->rectangle($$set[1]+1,$$set[4]+1,
					$$set[2]-1,$$set[3]-1,$selectColor);
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

#
# formats numerical axis labels to avoid excessively long labels 
#

sub shorten {
	my $value = shift;
	return sprintf ("%g", $value);
}

#
# returns labels containing only spaces to make room for manually drawn labels
#

sub x_erase {
	return (sprintf "%".$default{label_size}."s");
}

#
# adds tick marks and non-numerical labels
#

sub addLabels {
	my ($self,$gd,$graph) = @_;

        my @X = $self->{table}->col($self->{X});

	# allocate same blue as rest of graph axes and labels
        my $blue = $gd->colorAllocate(0,0,125);

	# determine which X labels are needed
        my $start = $self->{x_min};
        $start = int($self->{x_min}+1) unless 
		($self->{x_min} == int($self->{x_min}));
        my $end = int($self->{x_max});

        my @XNR=(""); # non-redundant X values, first value for zero

	# shorten X labels
        for (0.. $#X) {
                if ($X[$_] ne $X[$_-1]) {
                        push (@XNR,sprintf ("%.$default{label_size}s",$X[$_]));
                }
        }

	# write each label under the corresponding point
        foreach ($start..$end) {
		# find coordinates of points on x-axis
                my ($x,$y) = $graph->val_to_pixel($_,$self->{y_min},1); 
 		# draw tick mark
                $gd->line($x,$y-$default{tick_size},$x,$y,$blue);
                $gd->stringUp(gdTinyFont,$x-$default{tick_size},
			$y+$default{label_offset},$XNR[$_],$blue);
        }

        return $gd;
}

1;
