package Chromosome::Map::Track;

use strict;
use GD;

use Chromosome::Map::Element;
use Chromosome::Map::Block;
use Chromosome::Map::Feature;

# overall constants
use constant X_MAX       => 1900;	# max width for initial img track
use constant X_TRACK_PAD => 45;		# right pad add to X_BOUND width track
use constant FEATURE_DISPLAY => 'absolute';
use constant FEATURE_RENDER  => 'plain';

# block constants
use constant BLOCK_WIDTH => 3;
use constant BLOCK_XPAD  => 15;

# feature constants
use constant X_WIDTH_ABS => 5;
use constant X_WIDTH_REL => 70;

our $VERSION = '0.01';
my %COLORS;

################################################################################
# public methods
################################################################################

#-------------------------------------------------------------------------------
# new track
# usage: my $track = Track->new ( ... options ... )
#-------------------------------------------------------------------------------
# By default, the track size is define to 0
# size will update with the map size in the add_track method in Map.pm
# track type:
#	- marker: designed for marker, snp
#	- interval: designed for QTL interval region, could marker interval, too
#	- gene: same as interval but will use larger block
#	- feature: designed to plot physical features on chromosomes (%GC, nb genes)
#	  note: for feature track type, users have to define the track display
#	  -display:
#			'absolute' : in one pixel, the values of all feature will be added
#			'relative' : in one pixel, the sum of all the value be be re-scaled
#	  -render:
#			'gradient'  : represent value with a color gradient
#			'threshold' : shift color depending on value (note: a threshold value
#						  must be defined)
#			'plain'		: default options, no color adjustement
#     -threshold: define the color shift threshold (for threshold render option)
#-------------------------------------------------------------------------------
sub new {
	my $class = shift;
	$class = ref($class) || $class;
	
	my %Options = @_;
	my $self = {};
	$self->{_name}  = $Options{-name};
	$self->{_type}  = $Options{-type};
	$self->{_size}  = 0;
	$self->{_start} = 0;
	$self->{_element} = [];
	
	# only for feature track
	$self->{_feature_display}   = $Options{-display} || FEATURE_DISPLAY;
	$self->{_feature_render}    = $Options{-render}  || FEATURE_RENDER;
	$self->{_feature_threshold} = $Options{-threshold};
	
	# store GD sub-image, X bound and extra_bottom_padding
	$self->{_gd} = undef;
	$self->{_xbound} = undef;
	$self->{_extra_bottom_padding} = 0;	
	
	bless $self,$class;
	return $self;
}

sub get_track_name {
	my ($self) = @_;
	return $self->{_name};
}

sub get_track_type {
	my ($self) = @_;
	return $self->{_type};
}

sub get_track_size {
	my ($self) = @_;
	return $self->{_size};
}

sub get_track_start {
	my ($self) = @_;
	return $self->{_start};
}

sub get_nb_elements {
	my ($self) = @_;
	return scalar ( @{$self->{_element}});
}

sub get_list_element {
	my ($self) = @_;
	my @List = @{$self->{_element}};
	return @List;
}

sub get_list_element_sorted_location {
	my $self = shift;
	my @List = @{$self->{_element}};
	my $end = $#List;
	my @Sort_list = _bubble_sort($end,@List);
	return @Sort_list;
}

sub add_element {
	my ($self,$element) = @_;
	my ($start,$end);

	# Testing the element value type (absolute or relative) and the track
	# feature display options (absolute or relative)
	# In case of element value type = relative, the track feature display
	# has to be set to RELATIVE, too
	my $track_type = $self->get_track_type;
	if ($track_type eq 'feature') {
		my $track_feature_display = $self->_get_track_feature_display;
		my $feature_value_type = $element->get_feature_value_type;
		if (($track_feature_display eq 'absolute')&&($feature_value_type eq 'relative')) {
			$self->_set_track_feature_display('relative');
		}
		
	}

	# adding element to track	
	$start = $end = $element->get_element_loc;
	$end = $element->get_block_end if (ref $element eq 'Block');
	
	if (($end <= $self->get_track_size)&&($start >= $self->get_track_start))
	{
		push ( @{$self->{_element}} , $element);
		return 1;
	}
	
	return 0;
}


################################################################################
# private methods
################################################################################

sub _set_track_feature_display {
	my ($self,$display_options) = @_;
	$self->{_feature_display} = $display_options;
}

sub _get_xbound {
	my ($self) = @_;
	return $self->{_xbound};	
}

sub _get_extra_bottom_padding {
	my ($self) = @_;
	return $self->{_extra_bottom_padding};	
}

sub _get_gd {
	my ($self) = @_;
	return $self->{_gd};	
}

sub _create_gd {
	my ($self,$map,$extra_bottom_padding) = @_;
	$extra_bottom_padding = 0 if (!defined $extra_bottom_padding);
	
	my $height  = $map->_height + $extra_bottom_padding;
	my $width   = X_MAX;
	my $x       = 0;
	my $x_bound = 0;
	my $gd = GD::Image->new($width,$height);
	
	$self->{_gd} = $gd;

	my $white = $gd->colorAllocate(255,255,255);
	$gd->fill(0,0,$white);
		
	return ($gd,$x,$x_bound);
}


#-------------------------------------------------------------------------------
# Render sub-image for MARKER track
#-------------------------------------------------------------------------------

sub _render_marker_track {
	use constant CHAR_PAD => 4;
	use constant LINE_WIDTH => 20;
	use constant NAME_PAD => 4;
	
	my ($self,$map) = @_;
	
	# get sorted element list and max y (need extra bottolm padding?)
	my @List_element = $self->get_list_element_sorted_location;
	my $max_y = _get_max_y_location ($map,@List_element);
	my $extra_pad = 0;
	if ($max_y > ($map->_height - $map->_pad_bottom)) {
		$extra_pad = ($max_y - $map->_height) + $map->_pad_bottom;
		$self->{_extra_bottom_padding} = $extra_pad;
	}
	
	# create sub-image
	my ($gd,$x,$x_bound) = $self->_create_gd($map,$extra_pad);

	my $black = $self->_translate_color('black');
	my $gray  = $self->_translate_color('gray');
		
	my $last_y = -1;
	
	#define x value for lines and diagonal lines
	my $x_bar1  = $x + (LINE_WIDTH / 4);
	my $x_bar2 = $x_bar1 + (LINE_WIDTH / 2);
	
	foreach my $element (@List_element) {
		my $name  = $element->get_element_name;
		my $loc   = $element->get_element_loc;
		my $color = $self->_translate_color($element->get_element_color);
		my $y = $map->_locate_element($loc);
		my $string_size = _nb_PX_string ($name);

		if (($y - CHAR_PAD) > $last_y) {
			$gd->filledRectangle ($x,$y,$x + LINE_WIDTH,$y,$gray);
			$gd->string (gdTinyFont,$x + LINE_WIDTH + NAME_PAD,$y - CHAR_PAD,$name,$color);
		}
		else {
			$gd->filledRectangle ($x,$y,$x_bar1,$y,$gray);
			my $y_bottom = $last_y + CHAR_PAD;
			$gd->line ($x_bar1, $y, $x_bar2, $y_bottom, $gray);
			$y = $y_bottom;
			$gd->filledRectangle ($x_bar2,$y,$x + LINE_WIDTH,$y,$gray);
			$gd->string (gdTinyFont,$x + LINE_WIDTH + NAME_PAD,$y - CHAR_PAD,$name,$color);
		}
		$last_y = $y + CHAR_PAD;
		my $x_element_width = LINE_WIDTH + NAME_PAD + $string_size;
		$x_bound = $x_element_width if ($x_element_width > $x_bound);
	}
	$x_bound += X_TRACK_PAD;
	$self->{_xbound} = $x_bound;
}

sub _get_max_y_location {
	# simulate Y computation to get the max Y value
	# need for extra_bottom_padding value
	my ($map,@Tab) = @_;
	my $last_y = -1;
	
	foreach my $element (@Tab) {
		my $loc  = $element->get_element_loc;
		my $y = $map->_locate_element($loc);

		if (($y - CHAR_PAD) < $last_y) {
			my $y_bottom = $last_y + CHAR_PAD;
			$y = $y_bottom;
		}
		
		$last_y = $y + CHAR_PAD;
	}
	return $last_y;
}


#-------------------------------------------------------------------------------
# Render sub-image for BLOCK track
#-------------------------------------------------------------------------------

sub _render_block_track {
	my ($self,$map) = @_;
	
	# create sub-image
	my ($gd,$x,$x_bound) = $self->_create_gd($map);
	
	my $black = $gd->colorResolve(0,0,0);

	my @List_element = $self->get_list_element_sorted_location;
	
	my $last_y = -1;
	my %Zone;
	my $x_pad = 0;
	my $MAX_xpad = 0;
	foreach my $element (@List_element) {
		my $name  = $element->get_element_name;
		my $start = $element->get_element_loc;
		my $end   = $element->get_block_end;
		my $color = $self->_translate_color($element->get_element_color);
		my $y1 = $map->_locate_element($start);
		my $y2 = $map->_locate_element($end);
		
		# set the y-axis value to print the interval name
		# note $y_string1 is the lowest y-axis value (as text is rotated counterclockwise)
		my $y_string1 = 0;
		my $y_string2 = 0;
		if (defined $name) {
			my $string_size = _nb_PX_string ($name);
			$y_string1 = $y1 + ( ( ($y2-$y1) + $string_size) / 2 );
			$y_string2 = $y1 + ( ( ($y2-$y1) - $string_size) / 2 );
		}
		
		$x_pad = $MAX_xpad + BLOCK_XPAD;
		my $y_pad1;
		$y_pad1 = $y1;
		$y_pad1 = $y_string2 if ($y_string2 < $y1);
		foreach my $pad (sort {$a <=> $b} keys %Zone) {
			$x_pad = $pad if ($y_pad1 > $Zone{$pad}{y2});
		}

		$gd->filledRectangle ($x+$x_pad, $y1, $x +$x_pad + BLOCK_WIDTH, $y2, $color);
		$gd->stringUp(gdTinyFont,$x + NAME_PAD + $x_pad, $y_string1, $name, $black) if (defined $name);
		
		$Zone{$x_pad}{y1} = $y1;
		$Zone{$x_pad}{y2} = $y2;
		$Zone{$x_pad}{y2} = $y_string1 if ($y_string1 > $y2);
		$Zone{$x_pad}{y1} = $y_string2 if ($y_string2 < $y1);

		my $x_element_width = NAME_PAD + $x_pad;
		$x_bound = $x_element_width if ($x_element_width > $x_bound);
		$MAX_xpad = $x_pad if ($x_pad > $MAX_xpad);
	}
	$x_bound += X_TRACK_PAD;
	$self->{_xbound} = $x_bound;	
}


#-------------------------------------------------------------------------------
# Render sub-image for FEATURE track
#-------------------------------------------------------------------------------

sub _render_feature_track {
	use constant MIN_ALPHA => 127;
	
	my ($self,$map) = @_;
	
	# create sub-image
	my ($gd,$x,$x_bound) = $self->_create_gd($map);
	
	my ($max,$color_name,$thres_color_name,%Feature) = $self->_generate_feature($map);
	my $feature_render = $self->_get_track_feature_render;
	
	my $black       = $self->_translate_color('black');
	my $color       = $self->_translate_color($color_name);
	my $thres_color;
	$thres_color    = $self->_translate_color($thres_color_name) if (defined $thres_color_name);	
	my ($r,$g,$b)   = $self->_color_name_to_rgb($color_name);
	
	if ($feature_render eq 'threshold') {
		my $x_threshold;
		$x_threshold = $self->_get_track_feature_threshold * X_WIDTH_REL if ($self->_get_track_feature_display eq 'relative');
		$x_threshold = $self->_get_track_feature_threshold * X_WIDTH_ABS if ($self->_get_track_feature_display eq 'absolute');
		foreach my $y (keys %Feature) {
			$gd->filledRectangle($x,$y,$x+$Feature{$y},$y,$color) if ($Feature{$y} <  $x_threshold);
			$gd->filledRectangle($x,$y,$x+$Feature{$y},$y,$thres_color) if ($Feature{$y} >= $x_threshold);
			$x_bound = $Feature{$y} if ($Feature{$y} > $x_bound);
		}		
	}
	elsif ($feature_render eq 'gradient') {
		my $color_gradient;
		foreach my $y (keys %Feature) {
			my $alpha_value = MIN_ALPHA - ((MIN_ALPHA * $Feature{$y}) / $max);
			$color_gradient = $gd->colorAllocateAlpha($r,$g,$b,$alpha_value);
			$gd->filledRectangle($x,$y,$x+$Feature{$y},$y,$color_gradient);
			$x_bound = $Feature{$y} if ($Feature{$y} > $x_bound);
		}
		$color_gradient = $gd->colorAllocateAlpha($r,$g,$b,0);
	}
	else {
		foreach my $y (keys %Feature) {
			$gd->filledRectangle($x,$y,$x+$Feature{$y},$y,$color);
			$x_bound = $Feature{$y} if ($Feature{$y} > $x_bound);
		}
	}
	
	$x_bound += X_TRACK_PAD;
	$self->{_xbound} = $x_bound;
	
	# drawing feature grid scale
	my $max_value = $self->{_max_value};
	$self->_draw_feature_grid ($max_value, $map);
}

sub _generate_feature {
	# return the max feature value (in x-axis value and a hash table with y-axis value as key
	# the feature will be return as absolute or relative x-axis value according to
	# $self->_get_track_feature_display
	#	- absolute
	#	- relative
	my ($self,$map) = @_;
	my $track_display = $self->_get_track_feature_display;
	my @List = $self->get_list_element;
	
	my %Hash;
	my $value_type;
	my $max = 0;
	my ($color_name,$thres_color_name);
	
	foreach my $feature (@List) {
		$value_type = $feature->get_feature_value_type || $value_type;
		my $loc = $feature->get_element_loc;
		my $y = int($map->_locate_element($loc));
		
		if ($value_type eq 'absolute') {
			$Hash{$y} += $feature->get_feature_value;
			$max = $Hash{$y} if ($Hash{$y} > $max);
		}
		elsif ($value_type eq 'relative') {
			push (@{$Hash{$y}},$feature->get_feature_value);
		}
		
		$color_name       = $feature->get_element_color || $color_name;
		$thres_color_name = $feature->get_feature_threshold_color if ((!defined $thres_color_name)&&($self->_get_track_feature_render eq 'threshold'));

	}
	
	# computing mean value if $value_type = relative
	if ($value_type eq 'relative') {
		my %Tmp = %Hash;
		foreach my $y (keys %Tmp) {
			my $sum = 0;
			my $nb  = 0;
			foreach my $value (@{$Tmp{$y}}) {
				$sum += $value;
				$nb++;
			}
			$Hash{$y} = $sum / $nb;
		}
		$max = 1;
	}
	
	# re-scaling feature value as relative to max=1
	if (($track_display eq 'relative')&&($value_type eq 'absolute')) {
		foreach my $y (keys %Hash) {
			 $Hash{$y} =  $Hash{$y} / $max;
		}
		$max = 1;
	}
	
	$self->{_max_value} = $max;
	
	# computing x-axis value according to $self->_get_track_feature_display
	foreach my $y (keys %Hash) {
		 $Hash{$y} =  $Hash{$y} * X_WIDTH_ABS if ($track_display eq 'absolute');
		 $Hash{$y} =  $Hash{$y} * X_WIDTH_REL if ($track_display eq 'relative');
	}
	
	$max *= X_WIDTH_ABS if ($track_display eq 'absolute');
	$max *= X_WIDTH_REL if ($track_display eq 'relative');	
	return ($max,$color_name,$thres_color_name,%Hash);
}

sub _get_track_feature_display {
	my ($self) = @_;
	return $self->{_feature_display};
}

sub _get_track_feature_render {
	my ($self) = @_;
	return $self->{_feature_render};
}

sub _get_track_feature_threshold {
	my ($self) = @_;
	return $self->{_feature_threshold};	
}

sub _feature_ticks {
	# calculate major and minor ticks, given a start position
	# modified from Bio::Graphics::Panel module
	# the MIN_GD_VALUE is used when the map scale is too big
	use constant MIN_WIDTH => 40;
	use constant MIN_GD_VALUE => 50;
	
	my $self = shift;
	
	my $max_value = $self->{_max_value};
	my $track_display = $self->_get_track_feature_display;
	my $min_width = MIN_WIDTH;
	
	# figure out tick mark scale
	# we want no more than 1 major tick mark every 40 pixels
	# and enough room for the labels
	
	my $scale = ($self->{_xbound} - X_TRACK_PAD) / $max_value;
	
	$min_width = MIN_GD_VALUE if ($scale > $min_width);

	my $interval = 0.1;
	if ($track_display eq 'absolute') {
		while (1) {
			my $pixels = $interval * $scale;
			last if $pixels >= $min_width;
			$interval *= 10;
		}
	}
	elsif ($track_display eq 'relative') {
		$interval = 1;
	}
	
	return ($interval,$interval/10);
}

sub _draw_feature_grid {
	# WARNING: this code is a bit messy... COULD be optimized...
	# draw a grid scale for feature track
	# modified from Bio::Graphics::Panel module
	use constant GRID_HEIGHT => 3;
	use constant GRID_OFFSCALE => 5;
	
	my ($self,$max_value,$map) = @_;
	
	my $x_grid = 0;
	
	my $gd    = $self->_get_gd;
	my $black = $self->_translate_color('black');
	my $track_display = $self->_get_track_feature_display;

	my @positions;
	my ($major,$minor) = $self->_feature_ticks;
	my $scale = ($self->{_xbound} - X_TRACK_PAD) / $max_value;
	
	for (my $i = 0; $i <= $max_value; $i += $minor) {
		push @positions,$i;
	}
	
	my $y = $map->_get_y_bottom + GRID_OFFSCALE;
	for my $tick (@positions) {
		my $offscale_major = 0;
		my $string_size = 0;
		$x_grid = $tick * $scale;
		
		if (($tick % $major == 0)&&($track_display eq 'absolute')) {
			$offscale_major = GRID_HEIGHT;
			$string_size = _nb_PX_string($tick) if ($tick != 0);
			$gd->string(gdTinyFont, $x_grid - ($string_size/2), $y + GRID_HEIGHT + $offscale_major + 5,$tick,$black);
		}
		elsif ($track_display eq 'relative') {
			if (($tick eq 0)||($tick eq $max_value)||($tick eq ($max_value/2))) {
				$offscale_major = GRID_HEIGHT;
				$string_size = _nb_PX_string($tick) if ($tick != 0);
				$gd->string(gdTinyFont, $x_grid - ($string_size/2), $y + GRID_HEIGHT + $offscale_major + 5,$tick,$black);				
			}
		}
		$gd->line($x_grid, $y, $x_grid, $y + GRID_HEIGHT + $offscale_major, $black);
	}
}


#-------------------------------------------------------------------------------
# meta-METHOD to generate all sub-image track
#-------------------------------------------------------------------------------

sub _render_track {
	my ($self,$map) = @_;
	my $type = $self->get_track_type;
	
	$self->_render_marker_track($map) if ($type eq 'marker');
	$self->_render_block_track($map) if ($type eq 'interval');
	$self->_render_feature_track($map) if ($type eq 'feature');
	
	$self->_add_track_name($map);
}

sub _add_track_name {
	my ($self,$map) = @_;
	
	my $name  = $self->get_track_name;
	my $black = $self->_translate_color('black');
	
	my $x = $self->{_xbound} - (X_TRACK_PAD / 2);
	my $height  = $map->_height;
	my $string_size = _nb_PX_string($name);
	my $gd = $self->_get_gd;
	$gd->stringUp(gdSmallFont,$x, ($height+$string_size)/2, $name, $black)
}


#-------------------------------------------------------------------------------
# Implementation of optimized bubble sort algorithm
#-------------------------------------------------------------------------------

sub _bubble_sort {
	# sort element according to their location
	# Implementation of the optimized bubble sort algorithm
	my ($end,@T) = @_;
	my $messy = 1;
	for (my $i=0;(($i<=$end)&&($messy ==1));$i++) {
		$messy = 0;
		for (my $j=1;$j<=$end-$i;$j++) {
			if ($T[$j-1]->{_loc} > $T[$j]->{_loc}) {
				my $temp = $T[$j-1];
				$T[$j-1] = $T[$j];
				$T[$j] = $temp;
				$messy = 1;
			}
		}
	}
	return (@T);
}


#-------------------------------------------------------------------------------
# get nb of pixel for string
#-------------------------------------------------------------------------------

sub _nb_PX_string {
	my ($string) = @_;
	my $nb = length ($string);
	$nb *= GD->gdTinyFont->width;
	return $nb;
}


#-------------------------------------------------------------------------------
# Colors management
#-------------------------------------------------------------------------------
# colors hex code are copied from Bio::Graphics::Panel module
# these subs have been modified
# AUTHOR: Lincoln Stein
#-------------------------------------------------------------------------------

sub _translate_color {
	my ($self,$color) = @_;
	my $gd    = $self->_get_gd;
	
	my ($r,$g,$b) = $self->_color_name_to_rgb($color);
	$gd->colorResolve($r,$g,$b);
}

sub _color_name_to_rgb {
  my $self = shift;
  my $color_name  = shift;

  $self->_read_colors() unless %COLORS;
  return unless $COLORS{$color_name};
  
  #return an ARRAY (RGB) or a reference to this ARRAY
  return wantarray ? @{$COLORS{$color_name}}
                   : $COLORS{$color_name};
}

sub _read_colors {
	my $class = shift;
	local ($/) = "\n";
	while (my $line = <DATA>) {
		$line =~ s/\s+$//;
		last if $line =~ /^__END__/;
		my ($name,$r,$g,$b) = split (/\s+/,$line);
		@{$COLORS{$name}} = (hex $r,hex $g, hex $b);
	}
}

1;

__DATA__
white                FF           FF            FF
black                00           00            00
aliceblue            F0           F8            FF
antiquewhite         FA           EB            D7
aqua                 00           FF            FF
aquamarine           7F           FF            D4
azure                F0           FF            FF
beige                F5           F5            DC
bisque               FF           E4            C4
blanchedalmond       FF           EB            CD
blue                 00           00            FF
blueviolet           8A           2B            E2
brown                A5           2A            2A
burlywood            DE           B8            87
cadetblue            5F           9E            A0
chartreuse           7F           FF            00
chocolate            D2           69            1E
coral                FF           7F            50
cornflowerblue       64           95            ED
cornsilk             FF           F8            DC
crimson              DC           14            3C
cyan                 00           FF            FF
darkblue             00           00            8B
darkcyan             00           8B            8B
darkgoldenrod        B8           86            0B
darkgray             A9           A9            A9
darkgreen            00           64            00
darkkhaki            BD           B7            6B
darkmagenta          8B           00            8B
darkolivegreen       55           6B            2F
darkorange           FF           8C            00
darkorchid           99           32            CC
darkred              8B           00            00
darksalmon           E9           96            7A
darkseagreen         8F           BC            8F
darkslateblue        48           3D            8B
darkslategray        2F           4F            4F
darkturquoise        00           CE            D1
darkviolet           94           00            D3
deeppink             FF           14            100
deepskyblue          00           BF            FF
dimgray              69           69            69
dodgerblue           1E           90            FF
firebrick            B2           22            22
floralwhite          FF           FA            F0
forestgreen          22           8B            22
fuchsia              FF           00            FF
gainsboro            DC           DC            DC
ghostwhite           F8           F8            FF
gold                 FF           D7            00
goldenrod            DA           A5            20
gray                 80           80            80
grey                 80           80            80
green                00           80            00
greenyellow          AD           FF            2F
honeydew             F0           FF            F0
hotpink              FF           69            B4
indianred            CD           5C            5C
indigo               4B           00            82
ivory                FF           FF            F0
khaki                F0           E6            8C
lavender             E6           E6            FA
lavenderblush        FF           F0            F5
lawngreen            7C           FC            00
lemonchiffon         FF           FA            CD
lightblue            AD           D8            E6
lightcoral           F0           80            80
lightcyan            E0           FF            FF
lightgoldenrodyellow FA           FA            D2
lightgreen           90           EE            90
lightgrey            D3           D3            D3
lightpink            FF           B6            C1
lightsalmon          FF           A0            7A
lightseagreen        20           B2            AA
lightskyblue         87           CE            FA
lightslategray       77           88            99
lightsteelblue       B0           C4            DE
lightyellow          FF           FF            E0
lime                 00           FF            00
limegreen            32           CD            32
linen                FA           F0            E6
magenta              FF           00            FF
maroon               80           00            00
mediumaquamarine     66           CD            AA
mediumblue           00           00            CD
mediumorchid         BA           55            D3
mediumpurple         100          70            DB
mediumseagreen       3C           B3            71
mediumslateblue      7B           68            EE
mediumspringgreen    00           FA            9A
mediumturquoise      48           D1            CC
mediumvioletred      C7           15            85
midnightblue         19           19            70
mintcream            F5           FF            FA
mistyrose            FF           E4            E1
moccasin             FF           E4            B5
navajowhite          FF           DE            AD
navy                 00           00            80
oldlace              FD           F5            E6
olive                80           80            00
olivedrab            6B           8E            23
orange               FF           A5            00
orangered            FF           45            00
orchid               DA           70            D6
palegoldenrod        EE           E8            AA
palegreen            98           FB            98
paleturquoise        AF           EE            EE
palevioletred        DB           70            100
papayawhip           FF           EF            D5
peachpuff            FF           DA            B9
peru                 CD           85            3F
pink                 FF           C0            CB
plum                 DD           A0            DD
powderblue           B0           E0            E6
purple               80           00            80
red                  FF           00            00
rosybrown            BC           8F            8F
royalblue            41           69            E1
saddlebrown          8B           45            13
salmon               FA           80            72
sandybrown           F4           A4            60
seagreen             2E           8B            57
seashell             FF           F5            EE
sienna               A0           52            2D
silver               C0           C0            C0
skyblue              87           CE            EB
slateblue            6A           5A            CD
slategray            70           80            90
snow                 FF           FA            FA
softblue             1B           28            3F
springgreen          00           FF            7F
steelblue            46           82            B4
tan                  D2           B4            8C
teal                 00           80            80
thistle              D8           BF            D8
tomato               FF           63            47
turquoise            40           E0            D0
violet               EE           82            EE
wheat                F5           DE            B3
whitesmoke           F5           F5            F5
yellow               FF           FF            00
yellowgreen          9A           CD            32
__END__