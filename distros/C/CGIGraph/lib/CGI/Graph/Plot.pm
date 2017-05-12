#
# Plot
#
# Parent class containing methods that all graphs have in common.
#

package CGI::Graph::Plot;
use Data::Table;
use CGI;
use GD;
use GD::Graph;

my $directory = ".";

my %default = ( divisions  	=> 17,
		center	   	=> '9,9',
		zoom	   	=> 1,
		grid_height	=> 200,
		grid_width	=> 250,
		height		=> 400,
		width		=> 500,
		dataColor	=> "#ff0000",
		selectColor	=> "#00ff00",
		lineColor	=> "#000000",
		windowColor	=> "#0000ff"
              );

#
# new creates a object and initializes necessary values if they do not
# already exist. a table reference to a sorted table with index column
# is added, as is a scalar value that holds selection values.
#

sub new {
        my ($pkg, $vars) = @_;
        my $class = ref($pkg) || $pkg;
        my $self = $vars;

	# create table
        my $table = Data::Table::fromCSV($self->{source});
        my @header = $table->header;

	# default values
	$self->{X} = $header[0] unless $self->{X};
	$self->{Y} = $header[0] unless $self->{Y};
	$self->{divisions} = $default{divisions} unless ($self->{divisions} && $self->{divisions} > 0);
	$self->{center} = $default{center} unless $self->{center};
	$self->{zoom} = $default{zoom} unless $self->{zoom};
	$self->{grid_height} = $default{grid_height} unless $self->{grid_height};
	$self->{grid_width} = $default{grid_width} unless $self->{grid_width};
	$self->{height} = $default{height} unless $self->{height};
	$self->{width} = $default{width} unless $self->{width};

	foreach ("dataColor","selectColor","lineColor","windowColor") {
	        if ($self->{$_}) {
			# check if array reference
			if (ref($self->{$_})) {
				my $ref = $self->{$_};
				my @rgb = @$ref;
				$self->{$_} = GD::Graph::colour::rgb2hex(@rgb);
			}
			# if not hex, then check for color name
			elsif (!($self->{$_}=~/^#[0-f]{6}$/)) {
				if (grep/^$self->{$_}$/,GD::Graph::colour::colour_list) {
					my @rgb = GD::Graph::colour::_rgb($self->{$_});
					$self->{$_} = GD::Graph::colour::rgb2hex(@rgb);
				}
				else {
					$self->{$_} = $default{$_};
				}
			}
			#otherwise, it is hex, which is ok
		}
		else {
			$self->{$_} = $default{$_};
		}
	}

        # set up table
        my @indices= (1..$table->nofRow);
        $table->addCol(\@indices,'_row');
        $table->sort($self->{X},($self->{X}=~/^[ir]_/)?0:1,0,$self->{Y},0,0);
        $self->{table} = $table;

	# check file that holds selections
	my $select;
	if (open INPUT, "$directory/".$self->{myFile}) {
		$select = <INPUT>;
		close INPUT;		
		
		# if the number of selections in the file is different than 
		# the number of rows, re-initialize
		if (length($select) != $table->nofRow) {
			all_values($self->{myFile},$table->nofRow,0);
			$select = "0"x$table->nofRow;
		}
	} 
	# file does not exist, so initialize it all to 0
	else {
		all_values($self->{myFile},$table->nofRow,0);
		$select = "0"x$table->nofRow;
	}

	$self->{selected} = $select;
        return bless $self, $class;
}

#
# returns a string containing the values necessary to create a graph image.
# a random value is added so that the browser will not use a cached image.
#

sub graphParams {
	my $self = shift;

	my @keys = qw (X Y x_min x_max y_min y_max source myFile graph_type 
		histogram_type zoom_type height width dataColor selectColor); 
	my $final = getValues($self,@keys);
	$final.= "rand=".rand(localtime);
	return $final;
}

#
# similar to graphParams, gridParams returns a string used for a grid image. 
#

sub gridParams {
        my $self = shift;
	my %vars = %$self; #make copy

        ($vars{x_min},$vars{x_max},$vars{y_min},$vars{y_max}) = 
		$self->gridBounds();

	my @keys = qw(X Y x_min x_max y_min y_max source myFile graph_type
		 histogram_type zoom_type zoom center divisions grid_width grid_height
		 dataColor selectColor lineColor windowColor); 
	my $final = getValues(\%vars,@keys);

	$final.= "rand=".rand(localtime);
	$final.= "&grid=on";

        return $final;
}

#
# gridMap returns an image map used on the grid image. The grid is divided into
# divisions * divisions rectangles and the mapInfo string is used to preserve 
# the attributes of the current object except for the center value.
#

sub gridMap{
        my ($self,$name,$mapName) = @_;
	
	my $mapInfo = $self->mapInfo();
        
        my $Vinc = $self->{grid_height}/$self->{divisions};
        my $Hinc = $self->{grid_width}/$self->{divisions};
        my $final = "\n<map name = \"$mapName\">\n";
        
        for $V (1..$self->{divisions}) {

                for $H (1..$self->{divisions}) {
			$mapInfo=~s/center=\d+%2C\d+/center=$H%2C$V/;
                        my $x1 = ($H-1)*$Hinc;
                        my $x2 = $H * $Hinc;
                        my $y1 = ($V-1)*$Vinc;
                        my $y2 = $V * $Vinc;

                        $final.= "<area alt=\"$H , $V\" "; 
			$final.= "shape=rect coords=$x1,$y1,$x2,$y2 ";
			$final.= "href=\"$name?$mapInfo\">\n";
                }
        }

        $final.="</map>\n";
        return $final;
}

#
# mapInfo returns a string which represents the attributes of the current 
# object.
#

sub mapInfo {
	my $self = shift;
	my $final;
	
	my @keys = qw(X Y source myFile refresh_display center zoom graph_type 
		divisions histogram_type zoom_type width height grid_width grid_height
		dataColor selectColor lineColor windowColor);
	$final = getValues($self,@keys);

	chop ($final);
	$final.="\"";
	return $final;
}

#
# calculates a "nice" upper and lower bound for the numerical array passed in.
#

sub bounds {
        my @sorted = sort {$a <=> $b} @_;
        my $x_min = $sorted[0];
        my $x_max = $sorted[-1];
        my $delta = $x_max - $x_min;
        my $ndigit = ($delta <=0)?0: int(log10($delta)+1)-1;
        my $ub = int($x_max/(10**$ndigit)+1)*10**$ndigit;
        my $lb = int($x_min/(10**$ndigit)-1)*10**$ndigit;
		 #changed to -1 from -.5 !!!!!!
        return ($lb,$ub);
}

#
# writes the current selection values to the file specified by the object
#

sub write_selected {
	my $self = shift;
	open OUTPUT, ">$directory/".$self->{myFile} or die "Cannot write to $self->{myFile}\n";
	print OUTPUT $self->{selected};
	close OUTPUT;
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

        if (($yc-$span/2) < 0) {
                $yc+=(-1*($yc-$span/2));
        }
        elsif (($yc+$span/2) > $self->{divisions}) {
                $yc-= $yc+$span/2-$self->{divisions};
        }

	# update center in object
	my $center = ($xc+.5).",".($self->{divisions}+1-($yc+.5));
	$self->{center} = $center;

        return ($xc,$yc,$span);
}

#
# adds grid lines to an image, depending on the number of divisions. Also draws
# in the center marker and view window.
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
	$y1 = ($center[1]-.5-$span/2)*$Vinc;
	$y2 = ($center[1]-.5+$span/2)*$Vinc;
	
        $x2-- if ($x2==$self->{grid_width});
        $y2-- if ($y2==$self->{grid_height});

        $image->rectangle($x1,$y1,$x2,$y2,$windowColor);
        $image->rectangle($x1+1,$y1+1,$x2-1,$y2-1,$windowColor);

        return $image;
}

#
# given a list of keys and a hash reference, will return the keys and values in
# a string.
#

sub getValues {
	my $vars = shift;
	my @keys = @_;
	my $final = '';

	foreach my $key (@keys) {
                my $value = CGI::escape($vars->{$key});
                $final.= "$key=$value&";
	}
	return $final;
}

#
# returns the base 10 logarithm of a number. Cannot handle 0 or negative 
# numbers.
#

sub log10 {
        my $in = shift;
	return undef if ($in <= 0);
        return log($in)/log(10);
}

#
# $value is written $size number of times to the filename specified
#	(used to intialize all values to 0 or 1)
#

sub all_values {
	my ($filename,$size,$value) = @_;
	my $select = "$value"x($size);
	open OUT, ">$directory/$filename" or die "Cannot write to $filename\n";
	print OUT "$select";
	close OUT;
}

1;


__END__;
