#23456789012345678901234567890123456789012345678901234567890123456789012345
#
# DBD::Chart::Plot -- Plotting engine for DBD::Chart
#
#	Copyright (C) 2001,2002 by Dean Arnold <darnold@presicient.com>
#
#   You may distribute under the terms of the Artistic License, 
#	as specified in the Perl README file.
#
#	Change History:
#
#	0.81	2005-Jan-26		D. Arnold
#		use TITLE instead of ALT in AREAMAPs
#		exit w/ error if compute scales/ranges would fail
#
#	0.80	2002-Sep-13		D. Arnold
#		programmable fonts
#		fix origin alignment for areagraphs w/ linegraphs
#		make image border programmable
#		fix 3-D piecharts where width >> height
#		improved 3-D piechart label positioning
#
#	0.73	2002-Sep-11		D. Arnold
#		fix scaling for 3-D bars w/ < 4 bars
#		fix all plots with single data point
#		add axis labels for 3-D bars
#		improve error reporting for iconic too wide,
#			icon format unsupported
#		fix for odd segmented quadtrees
#		fix scaling for 3-D bars when KEEPORIGIN=1
#		fix SHOWVALUES for 3-D bars when clipped from origin
#
#	0.72	2002-Aug-17		D. Arnold
#		fix showvalues for nonstacked bars/histos/candles
#		fix legend placement
#
#	0.71	2002-Aug-12		D. Arnold
#		add float property for bars/histos/areas
#		fix linewidth to be local property
#		fix bug in stacked areagraphs
#
#	0.70	2002-Jun-10		D. Arnold
#		add stacked bar, histo, area, and candlestick graphs
#		add quadtree graph
#		support new property keywords stack, showvalues
#		consolidated candlestick w/ 2D bars functions
#		add programmable linewidth to linegraph, candlesticks
#		add mapModifier callback
#		support NULL shapes entries
#
#	0.63	2002-May-16		D. Arnold
#		fix for Gantt chart date axis alignment
#
#	0.61	2002-Feb-07		D. Arnold
#		fix for :PLOTNUM imagemap variable in Gantt chart
#		fix for undef range values
#		added 'dot' point shape (contributed by Andrea Spinelli)
#		fix for temporal alignment
#		fix for tick labels overwriting axis labels
#
#	0.60	2002-Jan-12		D. Arnold
#		support temporal datatypes
#		support histograms
#		support composite images
#		support user defined colors
#		scale boxchart vertical offsets
#		support Gantt charts
#
#	0.52	2001-Dec-14		D. Arnold
#		fix for ymax in 2d bars
#
#	0.51	2001-Dec-01		D. Arnold
#		Support multicolor barcharts
#		Support 3D piecharts
#
#	0.50	2001-Oct-14		 D. Arnold
#		Add barchart, piechart engine
#		Add iconic barcharts, pointshapes
#		Add 3D, 3 axis barcharts
#		Add HTML imagemap generation
#		Increase axis label text length
#
#	0.43	2001-Oct-11		 P. Scott
#		Allow a 'gif' (or any future format supported by
#		GD::Image) format to be called in plot().
#
#	0.42	2001-Sep-29		Dean Arnold
#		- fixed xVertAxis handling for candlestick and symbolic domains
#
#	0.30	Jun 1, 2001		Dean Arnold
#		- fixed Y-axis tick problem when no grid used
#
#	0.20	Mar 10, 2001	Dean Arnold
#		- added logrithmic graphs
#		- added area graphs
#		- added image overlays
#
#	0.10	Feb 20, 2001	Dean Arnold
#		- Coded.
#
require 5.6.0;
use strict 'vars';

{
package DBD::Chart::Plot;

use GD;
use GD::Text;
use GD::Text::Align;
use Time::Local;
use GD qw(gdBrushed gdSmallFont gdTinyFont gdMediumBoldFont);

$DBD::Chart::Plot::VERSION = '0.81';

#
#	list of valid colors
#
our @clrlist = qw(
	white lgray	gray dgray black lblue blue dblue gold lyellow	
	yellow	dyellow	lgreen	green dgreen lred red dred lpurple	
	purple dpurple lorange orange pink dpink marine	cyan	
	lbrown dbrown );
#
#	RGB of valid colors
#
our %colors = (
	white	=> [255,255,255], 
	lgray	=> [191,191,191], 
	gray	=> [127,127,127],
	dgray	=> [63,63,63],
	black	=> [0,0,0],
	lblue	=> [0,0,255], 
	blue	=> [0,0,191],
	dblue	=> [0,0,127], 
	gold	=> [255,215,0],
	lyellow	=> [255,255,0], 
	yellow	=> [191,191,0], 
	dyellow	=> [127,127,0],
	lgreen	=> [0,255,0], 
	green	=> [0,191,0], 
	dgreen	=> [0,127,0],
	lred	=> [255,0,0], 
	red		=> [191,0,0],
	dred	=> [127,0,0],
	lpurple	=> [255,0,255], 
	purple	=> [191,0,191],
	dpurple	=> [127,0,127],
	lorange	=> [255,183,0], 
	orange	=> [255,127,0],
	pink	=> [255,183,193], 
	dpink	=> [255,105,180],
	marine	=> [127,127,255], 
	cyan	=> [0,255,255],
	lbrown	=> [210,180,140], 
	dbrown	=> [165,42,42],
	transparent => [1,1,1]
);
#
#	pointshapes
#
our %valid_shapes = (
'fillsquare', 1,
'opensquare', 2,
'horizcross', 3,
'diagcross', 4,
'filldiamond', 5,
'opendiamond', 6,
'fillcircle', 7,
'opencircle', 8,
'icon', 9,
'dot', 10,
'null', 11);

#
#	logarithmic steps for axis scaling
#
our @logsteps = (0, log(2)/log(10), log(3)/log(10), log(4)/log(10), 
	log(5)/log(10), 1.0);
#
#	index of vertex pts for 3-D barchart
#	polygonal visible faces
#
our @polyverts = ( 
[ 1*2, 2*2,	3*2, 4*2 ],	# top face
[ 0*2, 1*2, 4*2, 5*2 ],	# front face
[ 4*2, 3*2, 6*2, 5*2 ]	# side face
);
#
# indices of 3-D projection vertices
#	mapped to line segments
#
our @vert2lines = (
1*2, 4*2, 	# top front l-r
0*2, 1*2,	# left front b-t
0*2, 5*2,	# bottom front l-r
4*2, 5*2,	# right front b-t
1*2, 2*2,	# top left f-r
2*2, 3*2,	# top rear l-r
3*2, 4*2,   # right top r-f
3*2, 6*2,   # right rear t-b
5*2, 6*2,   # right bottom r-f
);

#
#	indices of 3-D projection of axes planes
#
our @axesverts = (
	0*2, 1*2,	# left wall
	1*2, 3*2,
	3*2, 2*2,
	2*2, 0*2,
		
# rear wall
	3*2, 6*2,	# trl to trr
	6*2, 5*2,	# trr to brr
	5*2, 1*2,	# brr to brl

# floor		
	9*2, 10*2,	# brr to brl
	10*2, 7*2,	# brl to brf
	
	9*2, 8*2,	# brr to brf
	7*2, 8*2,	# blf to brf
);
#
#	font sizes
#
our ($sfw,$sfh) = (gdSmallFont->width, gdSmallFont->height);
our ($tfw,$tfh) = (gdTinyFont->width, gdTinyFont->height);

our %valid_attr = qw(
	width 1
	height 1
	genMap 1
	mapType 1
	mapURL 1
	mapScript 1
	horizMargin 1
	vertMargin 1
	xAxisLabel 1
	yAxisLabel 1
	zAxisLabel 1
	xLog 1
	yLog 1
	zLog 1
	title 1
	signature 1
	legend 1
	horizGrid 1
	vertGrid 1
	xAxisVert 1
	keepOrigin 1
	bgColor 1
	threed 1
	icons 1
	symDomain 1
	timeDomain 1
	gridColor 1
	textColor 1
	font 1
	logo 1
	timeRange 1
	mapModifier 1
	border 1
);
our @lines = ( 
[ 0*2, 4*2,	5*2, 1*2 ],	# top face
[ 0*2, 1*2, 3*2, 2*2 ],	# front face
[ 1*2, 5*2, 7*2, 3*2 ]	# side face
);

our %gdfontmap = (
5, gdTinyFont,
6, gdSmallFont,
7, gdMediumBoldFont,
8, gdLargeFont,
9, gdGiantFont
);

our %fontMap = ();

our %month = ( 'JAN', 0, 'FEB', 1, 'MAR', 2, 'APR', 3, 'MAY', 4, 'JUN', 5, 
'JUL', 6, 'AUG', 7, 'SEP', 8, 'OCT', 9, 'NOV', 10, 'DEC', 11);
our @monthmap = qw( JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC );
#
#	URI escape map
#
our %escapes = ();
for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

use constant LINE => 1;
use constant POINT => 2;
use constant AREA => 4;
use constant BOX => 8;
use constant PIE => 16;
use constant HISTO => 32;
use constant BAR => 64;
use constant CANDLE => 128;
use constant GANTT => 256;
use constant QUADTREE => 512;

our %typemap = ( 'BAR', BAR, 'HISTO', HISTO, 'FILL', AREA, 
	'CANDLE', CANDLE, 'BOX', BOX, 'GANTT', GANTT, 'QUADTREE', QUADTREE );

sub new {
    my $class = shift;
    my $obj = {};
    bless $obj, $class;
    $obj->init (@_);

    return $obj;
}
#
#	Plot object members:
#
#	img - GD::Image object
#	width - image width in pixels
#	height - image height in pixels
#	signature - signature string
#	genMap - 1 => generate HTML imagemap
#	horizMargin - image horizontal margins in pixels
#	vertMargin - image vertical margins in pixels
#	data - data points to be plotted
#	props - graph properties
#	plotCnt - number of plots in graph
#	xl, xh, yl, yh, zl, zh - min/max of each axis
#	xscale, yscale, zscale - scaling factors for assoc. axis
#	horizEdge, vertEdge - horizontal/vertical edge location
#	horizStep, vertStep - horizontal/vertical pixel increment
#	haveScale - calculated min/max is valid
#	xAxisLabel, yAxisLabel, zAxisLabel - label for assoc. axis
#	title - title string
#	xLog, yLog, zLog - 1 => assoc axis is logarithmic
#	errmsg - last error msg
#	keepOrigin - force (0,0[,0]) into graph
#	imgMap - HTML imagemap text
#	symDomain - 1 => domain is symbolic
#	timeDomain - 1 => domain is temporal
#	icon - name of icon image file for iconic barcharts/points
#	logo - name of background logo image file
#	mapModifier - ref to callback to modify imagemap entries
#	_legends - arrayref to hold legend info til we render it
#
sub init {
	my ($obj, $w, $h, $colormap) = @_;

	$w = 400 unless $w;
	$h = 300 unless $h;
	my $img = new GD::Image($w, $h);
#
#	if a colormap supplied, copy it into our color list
#
	if ($colormap) {
		foreach my $color (keys(%$colormap)) {
			$colors{lc $color} = $$colormap{$color};
		}
	}
	
	my $white = $img->colorAllocate(@{$colors{white}});
	my $black = $img->colorAllocate(@{$colors{black}}); 

	$obj->{width} = $w;
	$obj->{height} = $h;
	$obj->{img} = $img;

# imagemap attributes
  	$obj->{genMap} = undef;	# name of map
  	$obj->{imgMap} = '';		# contains resulting map text
  	$obj->{mapType} = 'HTML';	# default HTML
  	$obj->{mapURL} = '';		# base URL for hotspots
  	$obj->{mapScript} = '';	# base script call for hotspots
  		
# image margins
	$obj->{horizMargin} = 50;
	$obj->{vertMargin} = 70;

# create an empty array for point arrays and properties
	$obj->{data} = [ ];
	$obj->{props} = [ ];
	$obj->{plotCnt} = 0;
	$obj->{plotTypes} = 0;

# used for pt2pxl()
	$obj->{xl} = undef;
	$obj->{xh} = undef;
	$obj->{yl} = undef;
	$obj->{yh} = undef;
	$obj->{zl} = undef;
	$obj->{zh} = undef;
	$obj->{xscale} = 0;
	$obj->{yscale} = 0;
	$obj->{zscale} = 0;
	$obj->{horizEdge} = 0;
	$obj->{vertEdge} = 0;
	$obj->{horizStep} = 0;
	$obj->{vertStep} = 0;
	$obj->{Xcard} = 0;		# cardinality of 3-axis barcharts
	$obj->{Zcard} = 0;
	$obj->{plotWidth} = 0;	# true plot width; height; depth
	$obj->{plotHeight} = 0;
	$obj->{plotDepth} = 0;
	$obj->{brushWidth} = 0; # width of bars or candlesticks
	$obj->{brushDepth} = 0;
	$obj->{rangeSum} = 0;	# running total for piecharts
	$obj->{haveScale} = 0;	# 1 = last calculated min & max still valid
	$obj->{domainValues} = { };	# map of domain values for bar/histo/candle/sym domains
	$obj->{boxCount} = 0;	# num of boxcharts in plot
	$obj->{barCount} = 0;	# num of barchart/histos in plot
	$obj->{xMaxLen} = 0;	# max length of symbolic X value
	$obj->{yMaxLen} = 0;	# max length of temporal Y value
	$obj->{zMaxLen} = 0;	# max length of symbolic Z value

# axis label strings
	$obj->{xAxisLabel} = '';
	$obj->{yAxisLabel} = '';
	$obj->{zAxisLabel} = '';

	$obj->{xLog} = 0;		# 1 => log10 scaling
	$obj->{yLog} = 0;
	$obj->{zLog} = 0;

	$obj->{title} = '';
	$obj->{signature} = '';
	$obj->{legend} = 0; 	# 1 => render legend
	$obj->{horizGrid} = 0;	# 1 => print y-axis gridlines
	$obj->{vertGrid} = 0;	# 1 => print x-axis gridlines
	$obj->{xAxisVert} = 0;	# 1 => print x-axis label vertically
	$obj->{errmsg} = '';	# error result of last operation
	$obj->{keepOrigin} = 0; # 1 => force origin into graph
	$obj->{threed} = 0;		# 1 => use 3-D effect
	$obj->{logo} = undef;
		
	$obj->{icons} = [ ];	# array of icon filenames
		
	$obj->{symDomain} = 0;	# 1 => use symbolic domain
	$obj->{timeDomain} = undef; # defines format of temporal domain labels
	$obj->{timeRange} = undef; # defines format of temporal range labels

#  allocate some oft used colors
	$obj->{white} = $white;
	$obj->{black} = $black; 
	$obj->{transparent} = $img->colorAllocate(@{$colors{'transparent'}});

	$obj->{bgColor} = $white; # background color
	$obj->{gridColor} = $black;
	$obj->{textColor} = $black;
	$obj->{border} = 1;

	$obj->{mapModifier} = undef;
	
#	for now these aren't used, but someday we'll let them be configured
	$obj->{font} = 'gd';

	$obj->{_legends} = [ ];

# set image basic properties
	$img->transparent($obj->{transparent});
	$img->interlaced('true');
#	$img->rectangle( 0, 0, $w-1, $h-1, $obj->{black});
}

#
#	compare function for numeric sort
#
sub numerically { $a <=> $b }

sub convert_temporal {
	my ($value, $format) = @_;
#
#	use Perl funcs to compute seconds from date
	my $t;
	$t = timegm(0, 0, 0, $3, $2 - 1, $1),
	$t -= ($t%86400), #	timelocal isn't behaving quite right
	return $t
		if (($format eq 'YYYY-MM-DD') &&
			($value=~/^(\d+)[\-\.\/](\d+)[\-\.\/](\d+)$/));

	$t = timegm(0, 0, 0, $3, $month{uc $2}, $1),
	$t -= ($t%86400), #	timelocal isn't behaving quite right
	return $t
		if (($format eq 'YYYY-MM-DD') &&
			($value=~/^(\d+)[\-\.\/](\w+)[\-\.\/](\d+)$/) &&
			defined($month{uc $2}));

	return timegm($6, $5, $4, $3, $2 - 1, $1) + ($7 ? $7 : 0)
		if (($format eq 'YYYY-MM-DD HH:MM:SS') &&
			($value=~/^(\d+)[\-\.\/](\d+)[\-\.\/](\d+)\s+(\d+):(\d+):(\d+)(\.\d+)?$/));

	return timegm($6, $5, $4, $3, $month{uc $2}, $1) + ($7 ? $7 : 0)
		if (($format eq 'YYYY-MM-DD HH:MM:SS') &&
			($value=~/^(\d+)[\-\.\/](\w+)[\-\.\/](\d+)\s+(\d+):(\d+):(\d+)(\.\d+)?$/) &&
			(defined($month{uc $2})));

	return (($1 ? (($1 eq '-') ? -1 : 1) : 1) * (($3 ? ($3 * 3600) : 0) + ($5 ? ($5 * 60) : 0) + 
		$6 + ($7 ? $7 : 0)))
		if ((($format eq '+HH:MM:SS') || ($format eq 'HH:MM:SS')) && 
			($value=~/^([\-\+])?((\d+):)?((\d+):)?(\d+)(\.\d+)?$/));

	return undef; # for completeness, shouldn't get here
}
#
#	restore the readable datetime form from 
#	the input numeric value
sub restore_temporal {
	my ($value, $format) = @_;

	my ($sign, $subsec, $sec, $min, $hour, $mday, $mon, $yr, $wday, $yday, $isdst);
	$sign = ($value < 0);
	$value = abs($value);
	if (($format eq '+HH:MM:SS') || ($format eq 'HH:MM:SS')) {
		$hour = int($value/3600);
		$min = int(($value%3600)/60);
		$sec = int($value%60);
		$hour = "0$hour" if ($hour < 10);
		$min = "0$min" if ($min < 10);
		$sec = "0$sec" if ($sec < 10);
		$subsec = int(($value - int($value)) * 100);
		return ($sign ? '-' : '') . "$hour:$min:$sec" . 
			($subsec ? ".$subsec" : '');
	}

	($sec, $min, $hour, $mday, $mon, $yr, $wday, $yday, $isdst) = gmtime($value);
	$yr += 1900;
	$mon++;
	$mon = "0$mon" if ($mon < 10);
	$min = "0$min" if ($min < 10);
	$sec = "0$sec" if ($sec < 10);
	$mday = "0$mday" if ($mday < 10);
	
	return "$yr\-$mon\-$mday"
		if ($format eq 'YYYY-MM-DD');

	$mon = $monthmap[$mon-1],
	return "$yr\-$mon\-$mday"
		if ($format eq 'YYYY-MMM-DD');

	return "$yr\-$mon\-$mday $hour:$min:$sec"
		if ($format eq 'YYYY-MM-DD HH:MM:SS');

	$mon = $monthmap[$mon-1],
	return "$yr\-$mon\-$mday $hour:$min:$sec"
		if ($format eq 'YYYY-MMM-DD HH:MM:SS');

	return undef; # for completeness, shouldn't get here
}

sub set3DBarPoints {
	my ($obj, $xary, @ranges) = @_;
	my $type = pop @ranges;
	my $props = pop @ranges;
	my ($yary, $zary);
	my ($ymin, $ymax) = ($obj->{yl}, $obj->{yh});
	my $ymaxlen = 0;
#
#	verify:
#		2 range sets if 3-axis
#		each rangeset has same number of elements as domain
#
	my $hasZaxis = ($obj->{zAxisLabel});
	$zary = pop @ranges
		if $hasZaxis;
	
	my @zs = ();
	my %zhash = ();
	my %xhash = ();
	my @xs = ();
	my @xvals = @$xary;
	my $ys;
	my ($xval, $zval) = (0,1);
	my $i = 0;
	my ($x, $y, $z);
	my $maxlen = 0;
#
#	collect all X's and convert if needed
	foreach (0..$#xvals) {
		$xvals[$_] = convert_temporal($xvals[$_], $obj->{timeDomain})
			if $obj->{timeDomain};
		next if $xhash{$xvals[$_]};
		push(@xs, $xvals[$_]);
		$xhash{$xvals[$_]} = 1;
		$maxlen = length($xvals[$_]) if (length($xvals[$_]) > $maxlen);
	}
	$obj->{xMaxLen} = $maxlen;

	foreach (@ranges) {
		$obj->{errmsg} = 'Unbalanced dataset.',
		return undef
			if ($#$xary != $#$_);
	}

	if ($hasZaxis) {
#
#	only 1 3-axis dataset permitted
		$obj->{errmsg} = 'Incompatible plot types.', return undef
			if $obj->{plotTypes};

		$obj->{errmsg} = 'Unbalanced dataset.',
		return undef
			if ($#$xary != $#$zary);
#
#	collect distinct Z and X values, and correlate them
#	with the assoc. Y value via hashes
#
		$maxlen = 0;
		foreach $z (0..$#$zary) {
			$zval = $$zary[$z];
			push(@zs, $zval),
			$zhash{$zval} = { }
				unless $zhash{$zval};
			$zhash{$zval}->{$xvals[$z]} = [ 0 ] unless $zhash{$zval}->{$xvals[$z]};
			$ys = $zhash{$zval}->{$xvals[$z]};
			foreach (@ranges) {
				$ymaxlen = length($$_[$z]) if (length($$_[$z]) > $ymaxlen);
				push(@$ys, $$_[$z]);
			}
			$maxlen = length($zval) if (length($zval) > $maxlen);
		}
		$obj->{zMaxLen} = $maxlen;
	}
	else {
		$obj->{errmsg} = 'Incompatible plot types.', return undef
			unless (($obj->{plotTypes} == 0) || ($obj->{plotTypes} & $type));
#
#	synthesize Z axis values so we can process same as true 3 axis
#
		push(@zs, 1);
		$zhash{1} = { };
		foreach $x (0..$#$xary) {
			$zhash{1}->{$xvals[$x]} = [ 0 ] unless $zhash{1}->{$xvals[$x]};
			$ys = $zhash{1}->{$xvals[$x]};
			foreach (@ranges) {
				$ymaxlen = length($$_[$x]) if (length($$_[$x]) > $ymaxlen);
				push(@$ys, $$_[$x]);
			}
		}
		$obj->{zMaxLen} = 0;
	}
	
	@xs = sort numerically @xs
		if $obj->{timeDomain};

	$obj->{plotTypes} |= $type;
	$obj->{zValues} = \@zs;
	$obj->{xValues} = \@xs;
#
#	sort datapoints in order Z from back to front,
#		X from left to right
#	(i.e., GROUP BY Z, X ORDER BY Z DESCENDING, X ASCENDING)
#	the order of appearance in the input arrays determines
#	what "front, back, left, and right" mean
#
#	Since X and Z are always symbolic, we generate numeric pseudo values
#	for them based on order of appearance in the input arrays
#
	my $zCard = scalar @zs;	# go from last Z value forward
	my $xCard = scalar @xs;
	my ($znum, $xnum) = (0,0,0);
	my @ary = ();
	my $lasty;
	my $j;
	for (my $z = $zCard; $z > 0; $z--) {
		foreach $x (1..$xCard) {
			$ys = $zhash{$zs[$z-1]}->{$xs[$x-1]};
#
#	adapt for neg to pos swings
#
			if (($$ys[1] < 0) && (($#$ys == 1) || ($$ys[$#$ys] >= 0))) {
				$i = 1;
				$$ys[$i-1] = $$ys[$i], 
				$i++ 
					while (($i <= $#$ys) && ($$ys[$i] < 0));
				$$ys[$i-1] = 0;
			}
#
#	data is stored in output array as (X, [ Ymin..Ymax ], Z, ...)
#
			$lasty = 0;
			my $starts = ($$ys[0] == 0) ? 1 : 0;
			foreach $i ($starts..$#$ys) {
				$y = $$ys[$i];
				$y = convert_temporal($y, $obj->{timeRange}) 
					if $obj->{timeRange};

				$obj->{errmsg} = "Non-numeric range value $y.",
				return undef
					unless ($obj->{timeRange} || 
						($y=~/^[+-]?\.?\d\d*(\.\d*)?([Ee][+-]?\d+)?$/));
		
				$obj->{errmsg} = 
					'Negative value supplied for logarithmic axis.',
				return undef
					if (($obj->{yLog}) && ($y <= 0));
#
#	on - to + transition, reset increment
				$lasty = 0 if (($lasty < 0) && ($y >= 0));

				$y += $lasty;
				$y = log($y)/log(10) if ($obj->{yLog});
				$$ys[$i] = $y;
				$lasty = $y;

				$ymin = $y unless (defined($ymin) && ($ymin <= $y));
				$ymax = $y unless (defined($ymax) && ($ymax >= $y));
			}
			push(@ary, $x, $ys, $z);
		}
	}
# record the dataset; use stack to support multi-graph images
	push(@{$obj->{data}}, \@ary);
	push(@{$obj->{props}}, $props);
	$obj->{xl} = 1;
	$obj->{xh} = $xCard;
	$obj->{yl} = $ymin;
	$obj->{yh} = $ymax;
	$obj->{zl} = 1;
	$obj->{zh} = $zCard;
	$obj->{Xcard} = $xCard;
	$obj->{Zcard} = $zCard;
	$obj->{haveScale} = 0;	# invalidate prior min-max calculations
	$obj->{barCount}++;
	$obj->{symDomain} = 0;	# to avoid a later sort
	$obj->{yMaxlen} = $ymaxlen;
	return 1;
}

sub set2DBarPoints {
	my ($obj, $xary, @ranges) = @_;

	my $type = pop @ranges;
	my $props = pop @ranges;
	my $lwidth = 2;
	$lwidth = $1 if ($props=~/\bwidth:(\d+)/i);
	my $unanchored = ($props=~/\bfloat\b/i);
	
	foreach (@ranges) {
		$obj->{errmsg} = 'Unbalanced dataset.',
		return undef
			if ($#$xary != $#$_);
	}
#
#	validate environment
#
	$obj->{errmsg} = 'Candlesticks require a minimum and maximum range value.', 
	return undef
		unless (($type != CANDLE) || ($#ranges > 0));

	$obj->{errmsg} = 'Unanchored charts require a minimum and maximum range value.', 
	return undef
		if ($unanchored && ($#ranges <= 0));

	$obj->{errmsg} = 'Incompatible plot types.', return undef
		if ((($type == HISTO) && $obj->{plotTypes} && ($obj->{plotTypes}^HISTO)) ||
			(($type != HISTO) && ($obj->{plotTypes} & HISTO)));

	$obj->{errmsg} = 'Incompatible plot domain types.', return undef
		if (($obj->{plotTypes} & (BOX|PIE|GANTT|QUADTREE)) ||
			(($obj->{plotTypes} & (LINE|POINT|AREA)) && (! $obj->{symDomain})));

	$obj->{symDomain} = 1;
	$obj->{plotTypes} |= $type;
	
	my ($x, $y) = (0,0,0,0);
	my $ty = 0;
	my ($ymin, $ymax) = ($obj->{yl}, $obj->{yh});
	$ymin = 1E38 unless $ymin;
	$ymax = -1E38 unless $ymax;
#
# record/merge the dataset
	my $domVals = $obj->{domainValues};
	my @data = ();
	my $idx = 0;
	my $i;
	for ($i = 0; $i <= $#$xary; $i++) {
#
#	eliminate undefined data points
#
		next unless defined($$xary[$i]);
		next if (($type == CANDLE) && (! defined($ranges[0]->[$i])));

		$x = $$xary[$i];
		$x = convert_temporal($x, $obj->{timeDomain}) if $obj->{timeDomain};

		$domVals->{$x} = defined($domVals) ? scalar(keys(%$domVals)) : 0
			unless defined($domVals->{$x});
#
#	force data into array in same order as any prior definition
		$idx = $domVals->{$x} * 3;
		$data[$idx++] = $x;
		$data[$idx] = [ ];
		my $yary = $data[$idx];

		$obj->{xMaxLen} = length($x) 
			unless ($obj->{xMaxLen} && ($obj->{xMaxLen} >= length($x)));
#
#	validate the range values
		my $lasty = 0;
#
#	reserve the first element for our 'base' value
#	to be determined after we compute the first 2 range elements
		push(@$yary, undef) unless (($type == CANDLE) || $unanchored);
		my $first_valid = 0;
		foreach (@ranges) {
			$y = $_->[$i];
#
#	to support skipping some ranges
			push(@$yary, undef), next unless defined($y);
			
			$y = convert_temporal($y, $obj->{timeRange})
				if $obj->{timeRange};
			$first_valid++;

			$obj->{errmsg} = 'Non-numeric range value ' . $y . '.',
			return undef
				unless ($obj->{timeRange} || 
					($y=~/^[+-]?\d+\.?\d*([Ee][+-]?\d+)?$/));

			$obj->{errmsg} = 'Invalid value supplied for logarithmic axis.',
			return undef
				if ($obj->{yLog} && ($y <= 0));
#
#	compute cumulative range value
			push(@$yary, 0), $lasty = 0
				if (($lasty < 0) && ($y >= 0) && (! $unanchored));
			$y += $lasty;
			push(@$yary, ($obj->{yLog} ? log($y)/log(10) : $y));
			$lasty = $y unless (($unanchored || ($type == CANDLE)) && ($first_valid == 1));
			$ymin = $y unless (defined($ymin) && ($y >= $ymin));
			$ymax = $y unless (defined($ymax) && ($y <= $ymax));
		}
#
#	now determine the base value:
#	if we start negative, but go positive, then just use first
#	range value as base
#
		unless ($unanchored || ($type == CANDLE)) {
			if (($$yary[1] < 0) && (($#$yary == 1) || ($$yary[2] > $$yary[1]))) {
				push @$yary, 0
					if ($#$yary == 1);

				shift @$yary;	# no need for placeholder
				next;
			}
#
#	everything else starts from zero
#
			$$yary[0] = 0;
		}
	}
	push(@{$obj->{data}}, \@data);
	push(@{$obj->{props}}, $props);
	$obj->{yl} = $ymin;
	$obj->{yh} = $ymax;
	$obj->{xl} = 1;
	$obj->{xh} = scalar(keys(%$domVals));
	
	$obj->{haveScale} = 0;	# invalidate any prior min-max calculations
	$obj->{barCount}++;
	$obj->{brushWidth} = $lwidth
		if ($type == CANDLE);

	return 1;
}

sub setPiePoints {
	my ($obj, $xary, $yary, $props) = @_;
		
	my @ary = ();

	$obj->{errmsg} = 'Incompatible plot types.', return undef
		if $obj->{plotTypes};

	$obj->{errmsg} = 'Unbalanced dataset.',
	return undef
		if ($#$xary != $#$yary);
	
	my $xtotal = 0;
	my ($i, $y);
	foreach (0..$#$xary) {
		next unless (defined($$xary[$_]) && defined($$yary[$_]));
		$y = $$yary[$_];
		$y = convert_temporal($y, $obj->{timeRange}) if $obj->{timeRange};

		$obj->{errmsg} = 'Non-numeric range value ' . $y . '.',
		return undef
			unless ($obj->{timeRange} || 
				($y=~/^[+-]?\.?\d+\.?\d*([Ee][+-]?\d+)?$/));

		$obj->{errmsg} = 
			'Negative range values not permitted for piecharts.',
		return undef
			if ($y < 0);

		$xtotal += $y;
		push(@ary, $$xary[$_], $y);
	}
	$obj->{plotTypes} |= PIE;
	push(@{$obj->{data}}, \@ary);
	push(@{$obj->{props}}, $props);
	$obj->{rangeSum} = $xtotal;
	$obj->{haveScale} = 0; # invalidate any prior min-max calculations
	return 1;
}

sub setBoxPoints {
	my ($obj, $xary, $props) = @_;

	$obj->{errmsg} = 'Incompatible plot types.', return undef
		if ($obj->{plotTypes} & (PIE|HISTO|BAR|CANDLE|GANTT|QUADTREE));
		
	$obj->{errmsg} = 'Boxchart not compatible with 3-D plot types.', return undef
		if ($obj->{threed} || $obj->{zAxis});
		
	$obj->{errmsg} = 'Boxchart not compatible with symbolic domains.', return undef
		if $obj->{symDomain};
		
	my @data = ();
	foreach (@$xary) {
		next unless defined($_);
		$_ = convert_temporal($_, $obj->{timeDomain}) if $obj->{timeDomain};
		$obj->{errmsg} = 'Non-numeric value ' . $_ . '.',
		return undef
			unless ($_=~/^[+-]?\d+\.?\d*([Ee][+-]?\d+)?$/);
		push(@data, $_);
	}
	@data = sort numerically @data;
	$obj->{xl} = $data[0] 
		unless (defined($obj->{xl}) && ($data[0] >= $obj->{xl}));
	$obj->{xh} = $data[$#data] 
		unless (defined($obj->{xh}) && ($data[$#data] <= $obj->{xh}));
	push(@{$obj->{data}}, \@data);
	push(@{$obj->{props}}, $props);
	$obj->{boxCount}++;
	$obj->{plotTypes} |= BOX;
	$obj->{numRanges} = 0;
	$obj->{haveScale} = 0; # invalidate any prior min-max calculations
	return 1;
}
#
#	variable arglist:
#
#	for line/point/area graphs, 2-axis barcharts:
#		setPoints($plotobj, \@xarray, \@yarray1, $props)
#	for 3-axis barcharts, surfacemaps:
#		setPoints($plotobj, \@xarray, \@yarray, \@zarray, $props)
#	for candlesticks, barcharts:
#		setPoints($plotobj, \@xarray, \@ylow, \@yhigh, $props)
#	for piecharts:
#		setPoints($plotobj, \@xarray, \@yarray, $props)
#	for box&whisker:
#		setPoints($plotobj, \@xarray, $props)
#	for Gantt:
#		setPoints($plotobj, \@tasks, \@start,\@end, \@assigned, \@pctcomplete,
#		\@depend1, [\@dependent2...], $props)
#
#	NOTE: graph type properties must be set prior to setting graph points
#	Each domain/rangeset must be separately defined with its properties
#	(e.g., a barchart with N domains requires N setPoints calls)
#
sub setPoints {
	my ($obj, $xary, @ranges) = @_;
	my $props = pop @ranges;
#
#	new stacked bars/candlesticks/histos
#
	return $obj->set3DBarPoints($xary, @ranges, $props, $typemap{uc $1})
		if (($props=~/\b(bar|histo)\b/i) && 
			($obj->{zAxisLabel} || $obj->{threed}));

	return $obj->set2DBarPoints($xary, @ranges, $props, $typemap{uc $1})
		if ($props=~/\b(bar|histo|candle)\b/i);

	return $obj->setPiePoints($xary, @ranges, $props)
		if ($props=~/\bpie\b/i);

	return $obj->setBoxPoints($xary, @ranges, $props)
		if ($props=~/\bbox\b/i);

	return $obj->setGanttPoints($xary, @ranges, $props)
		if ($props=~/\bgantt\b/i);

	return $obj->setQuadPoints($xary, @ranges, $props)
		if ($props=~/\bquadtree\b/i);
#
#	must be line/point/area, verify ranges have same num of elements
#	as domain
#
	$obj->{errmsg} = 'Incompatible plot types.', return undef
		if ($obj->{plotTypes} & (PIE|HISTO|GANTT|QUADTREE));
		
	$obj->{errmsg} = 
		'Line/point/area graph not compatible with 3-D plot types.', return undef
		if ($obj->{threed} || $obj->{zAxis});

	my ($x, $y, $yary) = (0,0, [ ]);
	my ($xmin, $xmax, $ymin, $ymax) = 
		($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh});
	my $is_symbolic = $obj->{symDomain};
	$xmin = $is_symbolic ? 1 : 1E38 unless defined($xmin);
	$xmax = $is_symbolic ? $#$xary + 1 : -1E38 unless defined($xmax);
	$ymin = 1E38 unless defined($ymin);
	$ymax = -1E38 unless defined($ymax);
	
	if (($props=~/\bstack\b/i) && ($props=~/\bfill\b/i)) {

		foreach (@ranges) {
			$obj->{errmsg} = 'Unbalanced dataset.',
			return undef
				if ($#$xary != $#$_);
		}
#
#	condense the stacked values
#
		foreach my $i (0..$#$xary) {
			$$yary[$i] = [ ];
			my $ys = $$yary[$i];
			my $lasty = 0;
			my $first_valid = 0;
			foreach (@ranges) {

				$y = $$_[$i];
				next unless defined($y);
				$y = convert_temporal($y, $obj->{timeRange}) 
					if $obj->{timeRange};
#
#	validate the range values
				$obj->{errmsg} = 'Non-numeric range value ' . $y . '.',
				return undef
					unless ($y=~/^[+-]?\.?\d+\.?\d*([Ee][+-]?\d+)?$/);
		
				$obj->{errmsg} = 
					'Invalid value supplied for logarithmic axis.',
				return undef
					if ($obj->{yLog} && ($y <= 0));

				$first_valid++;
				
				$y += $lasty;
				$y = log($y)/log(10) if $obj->{yLog};
				$ymin = $y if ($y < $ymin);
				$ymax = $y if ($y > $ymax);
				push @$ys, $y;
				$lasty = $y unless (($props=~/\bfloat\b/i) && ($first_valid == 1));
			}
		}
	}
	else {
		$yary = $ranges[0];

		$obj->{errmsg} = 'Unbalanced dataset.',
		return undef
			if ($#$xary != $#$yary);
	}
#
# record/merge the dataset
	my $domVals = $obj->{domainValues};
	my @data = ();
	my $idx = 0;
	my @xs = ();
	my @ys = ();
#
#	sort numeric/temporal domain into asc. order
#
	my %xhash = ();
	my $needsort = 0;
	foreach (0..$#$xary) {
#
#	eliminate undefined data points
#
		$x = $$xary[$_];
		next unless defined($x);
		
		$x = convert_temporal($x, $obj->{timeDomain}) if $obj->{timeDomain};

		$obj->{errmsg} = "Non-numeric domain value $x.",
		return undef
			unless ($is_symbolic ||
				($x=~/^[+-]?\.?\d+\.?\d*([Ee][+-]?\d+)?$/));

		$obj->{errmsg} = "Invalid value for logarithmic axis.",
		return undef
			unless ($is_symbolic || (! $obj->{xLog}) ||	($x > 0));

		$obj->{xMaxLen} = length($x) 
			if ($is_symbolic && ((! $obj->{xMaxLen}) || (length($x) > $obj->{xMaxLen})));
		push(@xs, $x),
		$xhash{$x} = $#xs,
		next
			if $is_symbolic;

		$x = log($x)/log(10) if $obj->{xLog};
		$needsort = 1 if (($#xs >= 0) && ($xs[$#xs] > $x));
		push @xs, $x;
		$xhash{$x} = $#xs;
	}
#
#	optimize for presorted domains
	@ys = @$yary 
		unless $needsort;

	if ($needsort) {
		@xs = sort numerically @xs ;
		push @ys, $$yary[$xhash{$_}]
			foreach (@xs);
	}
#
#	first and last domain values are smallest and biggest now
	$xmin = $xs[0] unless ($is_symbolic || ($xs[0] >= $xmin));
	$xmax = $xs[$#xs] unless ($is_symbolic || ($xs[$#xs] <= $xmax));
	$xmax = 1 + $#xs  if ($is_symbolic && ($#xs >= $xmax));

	foreach (0..$#xs) {
		($x, $y) = ($xs[$_], $ys[$_]); # maybe shift instead ?
		next unless (defined($x) && defined($y));
		
		unless (ref $y) {
			$y = convert_temporal($y, $obj->{timeRange}) if $obj->{timeRange};
#
#	validate the range values
			$obj->{errmsg} = 'Non-numeric range value ' . $y . '.',
			return undef
				unless ($y=~/^[+-]?\.?\d+\.?\d*([Ee][+-]?\d+)?$/);
		
			$obj->{errmsg} = 
				'Invalid value supplied for logarithmic axis.',
			return undef
				if ($obj->{yLog} && ($y <= 0));

			$y = log($y)/log(10) if $obj->{yLog};
			$ymin = $y if ($y < $ymin);
			$ymax = $y if ($y > $ymax);
		}		
		push(@data, $x, $y), next
			unless $obj->{symDomain};
#
#	symbolic domain is mapped according to prior order (if any)
		$domVals->{$x} = defined($domVals) ? scalar(keys(%$domVals)) : 0
			unless defined($domVals->{$x});
		$idx = $domVals->{$x} * 2;
		$data[$idx++] = $x;
		$data[$idx++] = $y;
	}
	push(@{$obj->{data}}, \@data);
	$props .= ' line' unless ($props=~/\bnoline|line|fill\b/i);
	$props=~s/\bnoline\b/line/i if ($props=~/\bfill\b/i);
#	$props .= ' nopoints' 
#		unless (($props=~/\b(no)?points\b/i) || ($props!~/\bline\b/i));
	push(@{$obj->{props}}, $props);
	$obj->{haveScale} = 0;	# invalidate any prior min-max calculations
	$obj->{plotTypes} |= ($props=~/\bfill\b/i) ? AREA : 
		($props=~/\bline\b/i) ? LINE : POINT;
	($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh}) = 
		($xmin, $xmax, $ymin, $ymax);
	return 1;
}
#
#	wait until plot time to sort domain for bars/histos/candles
#
sub sortData {
	my ($obj) = @_;
#
#	make sure domain values are in ascending order
#
	my $xhash = $obj->{domainValues};
	my @xsorted = ();
	if ($obj->{timeDomain}) {
		@xsorted = sort numerically keys(%$xhash);
	}
	else {
		$xsorted[$$xhash{$_}] = $_
			foreach (keys(%$xhash));
	}
	$obj->{domain} = \@xsorted;
	$obj->{xh} = scalar @xsorted;
	return 1;
}

sub error {
  my $obj = shift;
  return $obj->{errmsg};
}

sub setOptions {
	my ($obj, %hash) = @_;

	foreach (keys (%hash)) {
#
#	we need a lot more error checking here!!!
#
		$obj->{errmsg} = "Unrecognized attribute $_.",
		return undef
			unless ($valid_attr{$_});
		
		if (/^(bg|grid|text)Color$/) {
			$obj->{errmsg} = "Unrecognized color $hash{$_} for $_.",
			return undef
				unless $colors{$hash{$_}};
			my $color = $hash{$_};
#
#	if its a predefined color, reuse it
#	else allocate it
#
			$obj->{$color} = $obj->{img}->colorAllocate(@{$colors{$color}})
				unless $obj->{$color};
			$obj->{$_} = $obj->{$color};
			next;
		}
		
		if ($_ eq 'font') {
#
#	locate first available font and use it
#
			delete $obj->{font};
			foreach my $f (@{$hash{font}}) {
				$obj->{font} = $f, last
					if $obj->loadFont($f);
			}
			$obj->{errmsg} = "No specified font available.",
			return undef
				unless $obj->{font};
			next;
		}

		$obj->{$_} = $hash{$_};
	}
	return 1;
}

sub plot {
	my ($obj, $format) = @_;
	$format = lc $format;
	
	$obj->{errmsg} = 'No plots defined.' unless $obj->{plotTypes};
#
#	first fill with bg color
#
	my $color;
	$obj->{img}->fill(1, 1, $obj->{bgColor} );
	$obj->{img}->rectangle( 0, 0, $obj->{width}-1, $obj->{height}-1,
	 ($obj->{border} ? $obj->{black} : $obj->{bgColor}));
#
#	then add any defined logo
	$obj->addLogo if $obj->{logo};

	$obj->drawTitle if $obj->{title}; # vert offset may be increased
	$obj->drawSignature if $obj->{signature};

#	$obj->{numRanges} = scalar @{$obj->{data}};
	my $rc = 1;
#
#	sort the domain values if temporal domain
#
	$obj->sortData if $obj->{symDomain};

	my $plottypes = $obj->{plotTypes};
	my $props = $obj->{props};
	my $prop;
#
#	if its boxchart only, then establish dummy yl, yh
	($obj->{yl}, $obj->{yh}) = (1, 100) if ($plottypes == BOX);
#
#	get scale of all included plots
#
	$rc = $obj->computeScales()
		unless ($obj->{haveScale} || 
			($plottypes == PIE) || ($plottypes == QUADTREE));
	return undef unless $rc;
#
#	if boxchart included, distribute the range values among the
#	plots
	$obj->{boxHeight} = int($obj->{plotHeight}/($obj->{boxCount}+1))
		if $obj->{boxCount};
#
#	pies are always solo, get em out of the way...
	$rc = $obj->plotPie,
	return ($rc ? (($format) && $obj->{img}->$format) : undef)
		if ($plottypes == PIE);
#
#	plot axes based on plot type
#
	$rc = ($plottypes == BOX) ? $obj->plotBoxAxes :
		($plottypes & (HISTO|GANTT)) ? $obj->plotHistoAxes :
		$obj->plotAxes
		unless ($plottypes == QUADTREE);
	return undef unless $rc;
#
#	now we can plot each dataset
#
	my @proptypes = ();
	foreach (@{$obj->{props}}) {
		push(@proptypes, $typemap{uc $1}), next 
			if /\b(candle|fill|box|bar|histo|gantt|quadtree)\b/i;
		push(@proptypes, POINT),next if /\bnoline\b/i;
		push(@proptypes, LINE);
	}
	my $plotcnt = $#{$obj->{props}} + 1;
#
#	hueristically render plots in "best" visible order
#
	if ($obj->{zAxisLabel} || $obj->{threed}) {
		return undef	# since 3-D only compatible with 3-D 
			if (! $obj->plot3DBars);

		return undef
			unless (($#{$obj->{_legends}} < 0) || $obj->drawLegend);

		$obj->plot3DTicks;
		return (($format) && $obj->{img}->$format);
	}

	return undef	# since quadtree must be solo
		if (($plottypes & QUADTREE) && (! $obj->plotQuadtree(\@proptypes)));

	return undef	# since histo only compatible with histo
		if (($plottypes & HISTO) && (! $obj->plot2DBars(HISTO, \@proptypes)));

	return undef	# since Gantt only compatible with Gantt
		if (($plottypes & GANTT) && (! $obj->plotGantt));

	return undef 
		if (($plottypes & AREA) && (! $obj->plotAll(AREA,\@proptypes)));
		
	return undef
		if (($plottypes & BAR) && (! $obj->plot2DBars(BAR, \@proptypes)));

	return undef
		if (($plottypes & CANDLE) && (! $obj->plot2DBars(CANDLE, \@proptypes)));

	return undef
		if (($plottypes & BOX) && (! $obj->plotBox(\@proptypes)));

	return undef 
		if (($plottypes & LINE) && (! $obj->plotAll(LINE,\@proptypes)));
		
	return undef 
		if (($plottypes & POINT) && (! $obj->plotAll(POINT,\@proptypes)));
#
#	add any accumulated legends
#
	return undef
		unless (($#{$obj->{_legends}} < 0) || $obj->drawLegend);
#
#	now render it in the requested format
#
	return (($format) && $obj->{img}->$format);
}

sub getMap {
	my ($obj) = @_;
	my $mapname = $obj->{genMap};

	return "\$$mapname = [\n" . $obj->{imgMap} . " ];"
		if (uc $obj->{mapType} eq 'PERL');

	return 	"<MAP NAME=\"$mapname\">" . 
		$obj->{imgMap} . "\n</MAP>\n";
}

# 
# sets xscale, yscale, and edge values used in pt2pxl
#	also adjusts min or max of barcharts to clip away origin
#
sub computeScales {
	my $obj = shift;
	my ($xl, $yl, $zl, $xh, $yh, $zh) = 
		($obj->{xl}, $obj->{yl}, $obj->{zl}, $obj->{xh}, $obj->{yh}, 
			$obj->{zh});
	my $i;
#
#	if keepOrigin, make sure (0,0) is included
#	(but only if not in logarithmic mode)
#
	if ($obj->{keepOrigin}) {
		unless ($obj->{xLog} || $obj->{symDomain} ||
			$obj->{zAxisLabel} || $obj->{threed}) {
			$xl = 0 if ($xl > 0);
			$xh = 0 if ($xh < 0);
		}
		unless ($obj->{yLog}) {
			$yl = 0 if ($yl > 0);
			$yh = 0 if ($yh < 0);
		}
#
#	doesn't apply to Z axis (yet)
#
	}
	
	my $plottypes = $obj->{plotTypes};
# set axis ranges for widest/tallest/deepest dataset
	$obj->{errmsg} = 'Invalid dataset.',
	return undef
		unless $obj->computeRanges($xl, $xh, $yl, $yh, $zl, $zh);
	$obj->{yl} = 0 if (($plottypes & (BAR|HISTO)) && ($yl == 0));
	if ($obj->{keepOrigin}) {
		unless ($obj->{xLog} || $obj->{symDomain} ||
			$obj->{zAxisLabel} || $obj->{threed}) {
			$obj->{xl} = 0 if ($xl >= 0);
			$obj->{xh} = 0 if ($xh <= 0);
		}
		unless ($obj->{yLog}) {
			$obj->{yl} = 0 if ($yl >= 0);
			$obj->{yh} = 0 if ($yh <= 0);
		}
	}

	($xl, $xh, $yl, $yh, $zl, $zh) = 
		($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh}, 
			$obj->{zl}, $obj->{zh});

	if (($plottypes & (BAR|HISTO)) && ($yl > 0) 
		&& (! $obj->{keepOrigin})) {
#
#	adjust mins to clip away from origin
#
		foreach (0..$#{$obj->{props}}) {
			next unless ($obj->{props}->[$_]=~/\b(bar|histo)\b/i);
			my $datastack = $obj->{data}->[$_];
			my $j = 1;

			$datastack->[$j]->[0] = $yl, $j += 3
				while ($j <= $#$datastack);
		}
	}
#
#	heuristically adjust image margins to fit labels
#
	my ($botmargin, $topmargin, $ltmargin, $rtmargin) = (40, 40, 0, 5*$sfw);
	$botmargin += (3 * $tfh) if $obj->{legend};
#
#	compute space needed for X axis labels
#
	my $maxlen = 0;
	my ($tl, $th) = (0, 0);
	($tl, $th) = ($obj->{xLog}) ? (10**$xl, 10**$xh) : ($xl, $xh)
		unless $obj->{symDomain};
	$maxlen = $obj->{symDomain} ? $obj->{xMaxLen} : 
		$obj->{timeDomain} ? length($obj->{timeDomain}) :
		(length($th) > length($tl)) ? length($th) : length($tl);
	$maxlen = 25 if ($maxlen > 25);
	$maxlen = 7 if ($maxlen < 7);
	$botmargin += (($sfw * $maxlen) + 10) unless ($plottypes & (HISTO|GANTT));
	$ltmargin = (($sfw * $maxlen) + 20) if ($plottypes & (HISTO|GANTT));
#
#	compute space needed for Y axis labels
#
	($tl, $th) = ($obj->{yLog}) ? (10**$yl, 10**$yh) : ($yl, $yh);
	$maxlen = $obj->{timeRange} ? length($obj->{timeRange}) :
		(length($th) > length($tl)) ? length($th) : length($tl);
	$maxlen = 25 if ($maxlen > 25);
	$maxlen = 7 if ($maxlen < 7);
	$botmargin += (($sfw * $maxlen) + 10) if ($plottypes & (HISTO|GANTT));
	$ltmargin = (($sfw * $maxlen) + 20) unless ($plottypes & (HISTO|GANTT));
#
#	compute space needed for Z axis labels
#
	if ($obj->{zAxisLabel}) {
		$maxlen = $obj->{zMaxLen};
		$maxlen = 25 if ($maxlen > 25);
		$maxlen = 7 if ($maxlen < 7);
		$rtmargin = ($sfw * $maxlen) + 10;
	}
#
# calculate axis scales 
	if ($obj->{zAxisLabel} || $obj->{threed}) {
		my $tht = $obj->{height} - $topmargin - $botmargin;
		my $twd = $obj->{width} - $ltmargin - $rtmargin;
#
#	compute ratio of Z values to X values
#	to adjust percent of plot area reserved for
#	depth. Max is 40%, min is 10%
#
		my $xzratio = 
			$obj->{Zcard}/($obj->{Xcard}*(scalar @{$obj->{data}}));
#		$xzratio = 0.1 if ($xzratio < 0.1);
#
#	compute actual height as adjusted height x (1 - depth ratio)
#	actual depth is based on 30 deg. rotation of adjusted
#	width x depth ratio
#	actual width is adjust width - the 30 deg. rotation effect
#
		$xh = 0.5 + int($xh), $xl = 0.5,
		$obj->{xh} = $xh, $obj->{xl} = $xl
			if ($xh - $xl < int($xh));
		$obj->{plotWidth} = int($twd / ($xzratio*sin(3.1415926/6) + 1)),
		$obj->{plotDepth} = int(($twd - $obj->{plotWidth})/sin(3.1415926/6)),
		$obj->{plotHeight} = int($tht - ($obj->{plotDepth}*cos(3.1415926/3))),
#		$obj->{xscale} = $obj->{plotWidth}/($xh - $xl),
		$obj->{xscale} = $obj->{plotWidth}/int($xh),
		$obj->{yscale} = $obj->{plotHeight}/($yh - $yl),
		$obj->{zscale} = $obj->{plotDepth}/($zh - $zl)
			unless ($plottypes & (HISTO|GANTT));

		$obj->{plotHeight} = int($tht / ($xzratio*cos(3.1415926/6) + 1)),
		$obj->{plotDepth} = int(($tht - $obj->{plotHeight})/cos(3.1415926/6)),
		$obj->{plotWidth} = int($twd - ($obj->{plotDepth}*sin(3.1415926/6))),
		$obj->{yscale} = $obj->{plotWidth}/($yh - $yl),
		$obj->{xscale} = $obj->{plotHeight}/($xh - $xl),
		$obj->{zscale} = $obj->{plotDepth}/($zh - $zl)
			if ($plottypes & (HISTO|GANTT));
	}
	else {
#	keep true width/height for future reference
		$obj->{xscale} = ($obj->{width} - $ltmargin - $rtmargin)/($xh - $xl),
		$obj->{yscale} = ($obj->{height} - $topmargin - $botmargin)/($yh - $yl),
		$obj->{plotWidth} = $obj->{width} - $ltmargin - $rtmargin,
		$obj->{plotHeight} = $obj->{height} - $topmargin - $botmargin
			unless ($plottypes & (HISTO|GANTT));

		$obj->{yscale} = ($obj->{width} - $ltmargin - $rtmargin)/($yh - $yl),
		$obj->{xscale} = ($obj->{height} - $topmargin - $botmargin)/($xh - $xl),
		$obj->{plotWidth} = $obj->{width} - $ltmargin - $rtmargin,
		$obj->{plotHeight} = $obj->{height} - $topmargin - $botmargin
			if ($plottypes & (HISTO|GANTT));
	}

	$obj->{horizEdge} = $ltmargin;
	$obj->{vertEdge} = $obj->{height} - $botmargin;
#
#	compute spacing info for bar/candles
#
	return undef
		if (($plottypes & (BAR|HISTO)) && 
			(! $obj->{zAxisLabel}) &&
			(! $obj->computeSpacing($plottypes)));
	
	$obj->{haveScale} = 1;
	return 1;
}

# computes the axis ranges for the input (min,max) tuple
# also computes axis step size for ticks
sub computeRanges {
 	my ($obj, $xl, $xh, $yl, $yh, $zl, $zh) = @_;
 	my ($tmp, $om) = (0,0);
 	my @sign = ();

	($obj->{horizStep}, $obj->{vertStep}, $obj->{depthStep}) = (1,1,1),
	($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh}, $obj->{zl}, $obj->{zh}) = 
		(0,1,0,1, 0,1)
		if (($xl == $xh) || ($yl == $yh) || 
			(defined($zl) && ($zl == $zh)) );
		
	foreach ($xl, $xh, $yl, $yh, $zl, $zh) {
		push @sign, (($_ < 0) ? -1 : (! $_) ? 0 : 1)
			if defined($_);
	}
	$xh = 2 if (($xh == 1) && ($xl == 1));
#
#	tick increment/value algorithm:
#	z = (log(max - min))/log(10);
#	y = z - int(z);
#	scale = (y < 0.4) ? 10 ** (int(z) - 1) :
#		((y >= 0.87) ? 10 ** int(z)) : 5 * ( 10 ** (int(z) - 1));
#	num_of_ticks = int((max - min)/scale) + 2;
#	step_pixels = int(image_width/num_of_ticks)
#
	my ($xr, $xd, $xs);
	$xl = int($xl) - ($xl < 0 ? 1 : 0),
	$xh = int($xh) + 1
		if ($obj->{xLog});
	return undef if ($xh == $xl);
	$xr = (log($xh - $xl))/log(10),
	$xd = $xr - int($xr)
		unless $obj->{symDomain};
	$obj->{horizStep} = $obj->{symDomain} ? 1 : 
		($xd < 0.4) ? (10 ** (int($xr) - 1)) :
		(($xd >= 0.87) ? (10 ** int($xr)) : (5 * (10 ** (int($xr) - 1))));
#
#	align date domain steps on 12:00 AM (zero hour) of a day
#	align timestamps on days if total interval > 3 days
#	else align timestamps on hours if total interval > 3 hours
#	else align timestamps on minutes
#
	if ((! $obj->{symDomain}) && $obj->{timeDomain} 
		&& ($obj->{timeDomain}=~/YYYY/i)) {
		my $align = 
			(($obj->{timeDomain}!~/HH/i) || 
				($xh - $xl > (3 * 24 * 60 * 60))) ? 86400 :
			($xh - $xl > (3 * 60 * 60)) ? 3600 : 60;

		$obj->{horizStep} += ($align - $obj->{horizStep}%$align)
			if ($obj->{horizStep}%$align != 0);
	}
	
	($yl, $yh) = (($yl * 0.75), ($yl * 1.25)) if ($yh == $yl);
	$yl = int($yl) - ($yl < 0 ? 1 : 0),
	$yh = int($yh) + 1
		if ($obj->{yLog});
	return undef if ($yh == $yl);
	$xr = (log($yh - $yl))/log(10);
	$xd = $xr - int($xr);
	$obj->{vertStep} = ($xd < 0.4) ? (10 ** (int($xr) - 1)) :
		(($xd >= 0.87) ? (10 ** int($xr)) : (5 * (10 ** (int($xr) - 1))));
#
#	align time range steps on 12:00 AM (zero hour) of a day
#	if histo/gantt
#
	if (($obj->{plotTypes} & (HISTO|GANTT)) && 
		$obj->{timeRange} && ($obj->{timeRange}=~/^YYYY/i)) {
		my $align = 
		(($obj->{timeRange}!~/HH/i) || 
			($yh - $yl > (3 * 24 * 60 * 60))) ? 86400 :
		($yh - $yl > (3 * 60 * 60)) ? 3600 : 60;

		$obj->{vertStep} += ($align - $obj->{vertStep}%$align)
			if ($obj->{vertStep}%$align != 0);
	}
#
#	histos switch things
	$xs = $obj->{horizStep}, 
	$obj->{horizStep} = $obj->{vertStep}, 
	$obj->{vertStep} = $xs
		if ($obj->{plotTypes} & (HISTO|GANTT));

	if (($obj->{zAxisLabel} || $obj->{threed}) && ($zh != $zl)) {
		return undef if ($zh == $zl);
		$xr = (log($zh - $zl))/log(10),
		$xd = $xr - int($xr)
			unless $obj->{symDomain};
		$obj->{depthStep} = $obj->{symDomain} ? 1 : 
			($xd < 0.4) ? (10 ** (int($xr) - 1)) :
			(($xd >= 0.87) ? (10 ** int($xr)) : (5 * (10 ** (int($xr) - 1))));
	}
	my ($xm, $ym, $zm) = ($obj->{plotTypes} & (HISTO|GANTT)) ?
		($obj->{vertStep}, $obj->{horizStep}, $obj->{depthStep}) :
		($obj->{horizStep}, $obj->{vertStep}, $obj->{depthStep});

	($zl, $zh) = (0.5, 1.5) if ($obj->{symDomain} && defined($zl) && ($zl == $zh));
	($xl, $xh) = (0.5, 1) if ($obj->{symDomain} && ($xl == $xh));
# fudge a little in case limit equals min or max
	$obj->{zl} = ((! $zm) ? 0 : $zm * (int(($zl-0.00001*$sign[4])/$zm) + $sign[4] - 1)),
	$obj->{zh} = ((! $zm) ? 0 : $zm * (int(($zh-0.00001*$sign[5])/$zm) + $sign[5] + 1))
		if defined($zl);
	$obj->{xl} = (! $xm) ? 0 : $xm * (int(($xl-0.00001*$sign[0])/$xm) + $sign[0] - 1);
	$obj->{xh} = (! $xm) ? 0 : $xm * (int(($xh-0.00001*$sign[1])/$xm) + $sign[1] + 1);
#
#	day align here too
	if ((! $obj->{symDomain}) && 
		$obj->{timeDomain} && ($obj->{timeDomain}=~/^YYYY/i)) {
		my $align = 
			(($obj->{timeDomain}!~/HH/i) || 
				($obj->{xh} - $obj->{xl} > (3 * 24 * 60 * 60))) ? 86400 :
			($obj->{xh} - $obj->{xl} > (3 * 60 * 60)) ? 3600 : 60;

		$obj->{xl} = $obj->{xl} - ($obj->{xl}%$align);
		$obj->{xh} += ($align - ($obj->{xh}%$align));
	}

	$obj->{yl} = ($obj->{yLog}) ? $yl : (! $ym) ? 0 : $ym * (int(($yl-0.00001*$sign[2])/$ym) + $sign[2] - 1);
	$obj->{yh} = ($obj->{yLog}) ? $yh : (! $ym) ? 0 : $ym * (int(($yh-0.00001*$sign[3])/$ym) + $sign[3] + 1);
#
#	day align here too
	if ($obj->{timeRange} && ($obj->{timeRange}=~/^YYYY/i)) {
		my $align = 
			(($obj->{timeRange}!~/HH/i) || 
				($obj->{yh} - $obj->{yl} > (3 * 24 * 60 * 60))) ? 86400 :
			($obj->{yh} - $obj->{yl} > (3 * 60 * 60)) ? 3600 : 60;

		$obj->{yl} = $obj->{yl} - ($obj->{yl}%$align);
		$obj->{yh} += ($align - ($obj->{yh}%$align));
	}
	return 1;
}
#
#	compute bar spacing
#
sub computeSpacing {
	my ($obj, $type) = @_;
#
#	compute number of domain values
#
	my $domains = 0;
	$domains = ($obj->{Xcard}) ? 1 : scalar(@{$obj->{domain}});

	my $bars = $obj->{barCount};
	$bars = $obj->{Xcard} if ($obj->{Xcard});
	my $spacer = 10;
	my $width = ($type & HISTO) ? $obj->{plotHeight} : $obj->{plotWidth};
	my $pxlsperdom = int($width/($domains+1)) - $spacer;

	$obj->{errmsg} = 'Insufficient width for number of domain values.',
	return undef
		if ($pxlsperdom < 2);
#
#	compute width of each bar from number of bars per domain value
#
	my $pxlsperbar = int($pxlsperdom/$bars);

	$obj->{errmsg} = 'Insufficient width for number of ranges or values.',
	return undef
		if ($pxlsperbar < 2);

	$obj->{brushWidth} = $pxlsperbar;
	return 1;
}

sub plot2DBars {
	my ($obj, $type, $typeary) = @_;
	my ($i, $j, $k, $x, $n, $ary, $pxl, $pxr, $py, $pyt, $pyb);
	my ($color, $prop, $s, $colorcnt);
	my @barcolors = ();
	my @brushes = ();
	my @markers = ();
	my @props = ();
	my $legend = $obj->{legend};
	my ($xl, $xh, $yl, $yh) = ($obj->{xl}, $obj->{xh}, $obj->{yl}, 
		$obj->{yh});
	my ($brush, $ci, $t);
	my ($useicon, $marker);
	my $img = $obj->{img};
	my $plottypes = $obj->{plotTypes};
	my @tary = ();
	my $bars = $obj->{barCount};
	my $boff = int($obj->{brushWidth}/2);
	my $ttlw = int($bars * $boff);
	my $domain = $obj->{domain};
	my $xhash = $obj->{domainValues};
	my ($prtX,$prtYH,$prtYL);
	my ($iconw, $iconh) = (0,0);
#
#	get indexes of all same type
	foreach (0..$#$typeary) {
		push(@tary, $_)
			if ($$typeary[$_] == $type);
	}

	for ($n = 0; $n <= $#tary; $n++) {
		@barcolors = ();
		@brushes = ();
		@markers = ();
		$marker = undef;
		$color = 'black';
		$k = $tary[$n];
		$ary = $obj->{data}->[$k];
		$t = $obj->{props}->[$k];
		$t=~s/\s+/ /g;
#		$t = lc $t;
		@props = split (' ', $t);
		my $showvals;
		my $stacked = 0;
		foreach (@props) {
#
#	if its iconic, load the icon image
#
			push(@markers,$1),
			push (@barcolors, undef),
			next
				if /^icon:(\S+)$/i;

			$_ = lc $_;
			$showvals = $1, next
				if /^showvalues:(\d+)/;

			$stacked = 1, next
				if ($_ eq 'stack');

			push (@barcolors, $_), 
			push (@markers, undef),
			next
				if (($type != CANDLE) && $colors{$_});
			
			next unless ($type == CANDLE);
#
#	for candlesticks we rely on the DBD::Chart layer to provide
#	sufficient colors and shapes as needed
			push (@barcolors, $_), 
			next
				if ($colors{$_});
#
#	generate pointshape if requested
#
			push(@markers, $_),
			next
				if ($valid_shapes{$_} && ($_ ne 'null'));
		} # end for each property
#
#	allocate each color we're using
		$colorcnt = 0;
		my ($bw, $bh, $bbasew, $bbaseh) = ($plottypes & HISTO) ?
			(1, $obj->{brushWidth}, 0, $obj->{brushWidth}) :
			($obj->{brushWidth}, 1, $obj->{brushWidth}, 0);

		foreach (@barcolors) {
			$colorcnt++;
			push(@brushes, undef),
			next 
				unless $_;
			$obj->{$_} = $obj->{img}->colorAllocate(@{$colors{$_}})
				unless $obj->{$_};
#
#	generate brushes to draw bars
#
			$brush = new GD::Image($bw, $bh),
			$ci = $brush->colorAllocate(@{$colors{$_}}),
			$brush->filledRectangle(0,0,$bbasew, $bbaseh,$ci),
			push(@brushes, $brush);
		}
#
#	load each icon we're using
#
		foreach (0..$#markers) {
			next unless $markers[$_];
			$markers[$_] = ($valid_shapes{$markers[$_]} && ($markers[$_] ne 'null')) ? 
				$obj->make_marker($markers[$_], $barcolors[$_]) : 
				$obj->getIcon($markers[$_], 1);
			return undef unless $markers[$_];
		}
#
#	render legend if requested
#	(a bit confusing here for multicolor single range charts?)
		$obj->addLegend($barcolors[0], $markers[0], $$legend[$k], undef)
			if ((! $stacked) && $legend && $$legend[$k]);

		if ($stacked && $legend && $$legend[$k]) {
#
#	there may be alignment problems here, due to the
#	possibility of drawing multiple stacked bars in the same image
#
			$obj->addLegend($barcolors[$_], $markers[$_], $$legend[$k]->[$_], undef)
				foreach (0..$#{$$legend[$k]});
		}
#
#	heuristically determine whether to print Y values vert or horiz.
		my $yorient = (length($yl) > length($yh)) ? length($yl) : length($yh);
		$yorient *= $tfw;
#
#	compute the center data point, then
#	adjust horizontal location based on brush width
#	and data set number
#
		my $xoffset = ($n * $obj->{brushWidth}) - $ttlw 
			+ $boff;
		my @val_palette = ();
		my ($px, $py);
		$j = 0;
		for ($x = 0; $x <= $#$domain; $x++) {
			($iconw,$iconh) = (0,0);
			$i = $$xhash{$$domain[$x]} * 3;	# get actual index for the current point
			next unless defined($$ary[$i+1]);

# compute top and bottom (left/right) points, and stuff into
#	array with printable x,y and either the brush or marker we use to draw
#	NOTE: this implementation supports stacked and unstacked
			my @ppts = ();
			my $ys = $$ary[$i+1];
			$j = 0 if ($#$ys > 1);
			foreach (0..$#$ys) {
				($pxl, $pyb) = $obj->pt2pxl ( $x+1, $$ys[$_] );
				($pxr, $pyt) = $obj->pt2pxl ( $x+1, $$ys[$_+1] );
				push @ppts, $pxl, $pyb, $pxr, $pyt, $x+1, $$ys[$_], $$ys[$_+1], $j;
				$j++;
				$j = 0 if ($j >= $colorcnt);
				last if ($_+1 == $#$ys);
			}
#
#	render each bar segment
			while ($#ppts > 0) {
				$pxl = shift @ppts;
				$pyb = shift @ppts;
				$pxr = shift @ppts;
				$pyt = shift @ppts;
				$prtX = shift @ppts;
				$prtYL = shift @ppts;
				$prtYH = shift @ppts;
				my $bidx = shift @ppts;
#
#	adjust for bar location
				$pxl += $xoffset,
				$pxr += $xoffset
					unless ($plottypes & HISTO);
				$pyb += $xoffset,
				$pyt += $xoffset
					if ($plottypes & HISTO);
				
# draw line between top and bottom(left and right)
				$img->setBrush($brushes[$bidx]),
				$img->line($pxl, $pyb, $pxr, $pyt, gdBrushed)
					if $brushes[$bidx];
#
#	unless its iconic
#
				$obj->drawIcons($markers[$bidx], $pxl, $pyb, $pxr, $pyt)
					if (($type != CANDLE) && $markers[$bidx]);
#
#	check for shapes if its a CANDLE
#
# draw pointshape if requested
				$obj->drawIcons($markers[$bidx], $pxl, $pyb, $pxl, 0),
				$obj->drawIcons($markers[$bidx], $pxl, $pyt, $pxl, 0),
				($iconw, $iconh) = $markers[$bidx]->getBounds()
					if ($markers[$bidx] && ($type == CANDLE));
#
#	optimization
				next unless ($obj->{genMap} || $showvals);
#
# draw top/bottom values if requested
				if ($type == CANDLE) {
					$prtYH = 10**$prtYH if $obj->{yLog};
					$prtYL = 10**$prtYL if $obj->{yLog};
					$prtYH = restore_temporal($prtYH, $obj->{timeRange}),
					$prtYL = restore_temporal($prtYL, $obj->{timeRange}) 
						if $obj->{timeRange};
					$prtX = restore_temporal($prtX, $obj->{timeDomain}) 
						if $obj->{timeDomain};

# update imagemap if requested
					$obj->updateImagemap('CIRCLE', $prtYH, $k, $prtX, 
						$prtYH, undef, $pxl, $pyt, 4),
					$obj->updateImagemap('CIRCLE', $prtYL, $k, $prtX,
						$prtYL, undef, $pxl, $pyb, 4)
						if ($obj->{genMap});

					next unless ($showvals);
#
#	we need a better way to position the values for stacked candles
#
					$iconh >>= 1;
					$obj->string($showvals, 0, $pxl-(length($prtYL) * ($tfw>>1)),
						$pyb+4+$iconh, $prtYL, $tfw);
					$obj->string($showvals, 0, $pxl-(length($prtYH) * ($tfw>>1)),
						$pyt-$tfh-$iconh, $prtYH, $tfw);
					next;
				}
#
#	convert range/domain values for printing
				$prtYH -= $prtYL if ($stacked && ($prtYL > 0));
				$prtYH = 10**($prtYH) if $obj->{yLog};
				$prtYH = restore_temporal($prtYH, $obj->{timeRange}) 
					if $obj->{timeRange};
				$prtYH = $prtYL if ($prtYL < 0);
				$prtX = restore_temporal($prtX, $obj->{timeDomain}) 
					if $obj->{timeDomain};
#
# update imagemap if requested
				$obj->updateImagemap('RECT', $prtYH, $k, $prtX, 
					$prtYH, undef, $pxl-$boff, $pyt, $pxl+$boff, $pyb)
					if (($plottypes & BAR) && $obj->{genMap});

				$obj->updateImagemap('RECT', $prtYH, $k, $prtX, 
					$prtYH, undef, $pxl, $pyt-$boff, $pxr, $pyt+$boff)
					if (($plottypes & HISTO) && $obj->{genMap});
				
				next unless $showvals;
#
#	draw vertical values for bars
				$py = ($stacked) ?
					(($prtYL < 0) ? $pyb - 4 : 
						$pyt + 4 + int(length($prtYH) * $tfw)) :
					(($prtYL < 0) ? $pyb + 4 + int(length($prtYH) * $tfw) :
						$pyt - 4);
#
#	push info on value stack to draw after rendering bars,
#	since stacked bars may obscure any value we write now
				push(@val_palette, $pxl-int($tfw/2), $py, $prtYH), next
					if (($plottypes & BAR) &&
						($obj->{yLog} || ($yorient >= $obj->{brushWidth})));
#
#	unless they'll fit horiz.
				$py = ($stacked) ? 
					(($prtYL < 0) ? $pyb - $tfh - 4 : $pyt + 4) :
					(($prtYL < 0) ? $pyb + 4 : $pyt - $tfh - 4);
				push(@val_palette, $pxl-int(length($prtYH) * $tfw/2), $py, $prtYH),
				next
					if (($plottypes & BAR) &&
						($yorient < $obj->{brushWidth}));

				$px = ($stacked) ?
					(($prtYL < 0) ? $pxl + $tfw : $pxr - (length($prtYH) * $tfw) - 4) :
					(($prtYL < 0) ? $pxl - (length($prtYH) * $tfw) : $pxr + $tfw);
				push(@val_palette, $px, $pyt-4, $prtYH), next
					if ($plottypes & HISTO);
			} # end while values to plot
		} # end for each bar
#
#	now render values...note that candlesticks still use old method;
#	eventually we'll clean them up as well.
#	We need to compute complementary colors for rendering the text
#	inside bars!!!
#
		while ($#val_palette >= 0) {
			$px = shift @val_palette;
			$py = shift @val_palette;
			$prtYH = shift @val_palette;

			$obj->string($showvals, 90, $px, $py, $prtYH, $tfw), 
			next
				if (($plottypes & BAR) &&
					($obj->{yLog} || ($yorient >= $obj->{brushWidth})));

			$obj->string($showvals, 0, $px, $py, $prtYH, $tfw);
		}
	} # end for each plot
	return 1;
}

sub computeMedian {
	my ($ary, $lo, $hi) = @_;
	my $size = $hi - $lo +1;
	my $midi = $size>>1;
	$midi-- unless ($size & 1);
	$midi += $lo;
	return ($size & 1) ? $$ary[$midi] : (($$ary[$midi] + $$ary[$midi+1])/2);
}

sub computeBox {
	my ($obj, $k) = @_;
	my ($median, $uq, $lq, $lex, $uex, $midpt, $iqr, $val);
	
	my $ary = $obj->{data}->[$k];
	my $size = $#$ary;
#
#	compute median
	$median = computeMedian($ary, 0, $size);
#
#	compute quartiles
	$midpt = ($size)>>1;
	$midpt-- unless ($size & 1);
	$lq = computeMedian($ary, 0, $midpt);
	$midpt += ($size & 1) ? 1 : 2;
	$uq = computeMedian($ary, $midpt, $size);
#
#	compute extremes within 1.5 IQR of median
	$iqr = $uq - $lq;
	$lex = $lq - ($iqr*1.5);
	$uex = $uq + ($iqr*1.5);
	$lex = $$ary[0] if ($lex < $$ary[0]);
	$uex = $$ary[$#$ary] if ($uex > $$ary[$#$ary]);
	
	return ($median, $lq, $uq, $lex, $uex);
}

sub plotBox {
	my ($obj, $typeary) = @_;

	my $legend = $obj->{legend};
	my ($i, $j, $k, $n, $x);
	my @tary = ();

	for ($i = 0; $i <= $#$typeary; $i++) {
		next unless ($$typeary[$i] == BOX);
		push @tary, $i;
	}
#
#	compute the height of each box based range max and min
	my $boxht = ($obj->{yh} - $obj->{yl})/($i+1);

	for ($n = 0; $n <= $#tary; $n++) {
		$k = $tary[$n];

		my $ary = $obj->{data}->[$k];
		my $t = lc $obj->{props}->[$k];
		$t=~s/\s+/ /g;
		my @props = split(' ', $t);
		my $color = 'black';
		my ($val, $xoff);
		my $showvals;
		foreach (@props) {
			$showvals = $1, next if /^showvalues:(\d+)/i;

			$color = $_
				if ($colors{$_});
		}
		$obj->{$color} = $obj->{img}->colorAllocate(@{$colors{$color}})
			unless $obj->{$color};
			
		$obj->addLegend($color, undef, $$legend[$k], undef)
			if (($legend) && ($$legend[$k]));
#
#	compute median, quartiles, and extremes
#
		my ($median, $lq, $uq, $lex, $uex) = $obj->computeBox($k);
#
#	compute box bounds
		my $ytop = $obj->{yl} + ($boxht * ($n + 1));
		my $ybot = $ytop - $boxht;
		my $dumy = ($ytop + $ybot)/2;
		my $py = 0;
#
#	draw the box
		my ($p1x, $p1y) = $obj->pt2pxl($lq, $ytop);
		my ($p2x, $p2y) = $obj->pt2pxl($uq, $ybot);
		my $yoff = (($n+1) * (15 + $tfh));
		$p1y -= $yoff;
		$p2y -= $yoff;
		my $img = $obj->{img};
#
#	double up the box border
		$img->rectangle($p1x, $p1y, $p2x, $p2y, $obj->{$color});
		$img->rectangle($p1x+1, $p1y+1, $p2x-1, $p2y-1, $obj->{$color});

		my ($tmed, $tlex, $tuex) = ($median, $lex, $uex);
		$tmed = restore_temporal($tmed, $obj->{timeDomain}),
		$lq = restore_temporal($lq, $obj->{timeDomain}),
		$uq = restore_temporal($uq, $obj->{timeDomain}) ,
		$tlex = restore_temporal($tlex, $obj->{timeDomain}),
		$tuex = restore_temporal($tuex, $obj->{timeDomain}) 
			if ($obj->{timeDomain} && ($obj->{genMap} || $showvals));

		$xoff = int(length($lq) * $tfw/2),
		$obj->string($showvals,0,$p1x-$xoff,$p1y-$tfh, $lq, $tfw),
		$xoff = int(length($uq) * $tfw/2),
		$obj->string($showvals,0,$p2x-$xoff,$p1y-$tfh, $uq, $tfw)
			if ($showvals);
	
		$obj->updateImagemap('RECT', "$tmed\[$lq..$uq\]", 0, $tmed, 
			$lq, $uq, $p1x, $p1y, $p2x, $p2y)
			if ($obj->{genMap});
#
#	draw median line
		($p1x, $py) = $obj->pt2pxl($median, $dumy);
		$p1y -= 5;
		$p2y += 5;
		$img->line($p1x, $p1y, $p1x, $p2y, $obj->{$color});

		$xoff = int(length($median) * $tfw/2),
		$obj->string($showvals,0,$p1x-$xoff,$p1y-$tfh, $tmed , $tfw)
			if $showvals;
#
#	draw whiskers
		($p1x, $p1y) = $obj->pt2pxl($lex, $dumy);
		($p2x, $py) = $obj->pt2pxl($lq, $dumy);
		$p1y -= $yoff;
		$img->line($p1x, $p1y, $p2x, $p1y, $obj->{$color});

		$tmed = restore_temporal($tmed, $obj->{timeDomain}),
		$lq = restore_temporal($lq, $obj->{timeDomain}),
		$uq = restore_temporal($uq, $obj->{timeDomain}) 
			if ($obj->{timeDomain} && ($obj->{genMap} || $showvals));

		$xoff = int(length($lex) * $tfw/2),
		$obj->string($showvals,0,$p1x-$xoff,$p1y-$tfh, $tlex, $tfw)
			if $showvals;
		$obj->updateImagemap('CIRCLE', $tlex, 0, $tlex, undef, undef, 
			$p1x, $p1y, 4)
			if ($obj->{genMap});

		($p1x, $p1y) = $obj->pt2pxl($uq, $dumy);
		($p2x, $py) = $obj->pt2pxl($uex, $dumy);
		$p1y -= $yoff;
		$img->line($p1x, $p1y, $p2x, $p1y, $obj->{$color});

		$xoff = int(length($uex) * $tfw/2),

		$obj->string($showvals,0,$p2x-$xoff,$p1y-$tfh, $tuex, $tfw)
			if $showvals;
		$obj->updateImagemap('CIRCLE', $tuex, 0, $tuex, undef, undef, 
			$p2x, $p1y, 4)
			if ($obj->{genMap});
#
#	plot outliers; we won't show values here
#	NOTE: we should us pointshape provided by props!!!
#
		my $marker = $obj->make_marker('filldiamond', $color);
		foreach (@$ary) {
			last if ($_ >= $lex);
			($p1x, $p1y) = $obj->pt2pxl($_, $dumy);
			$p1y -= $yoff;
			$img->copy($marker, $p1x-4, $p1y-4, 0, 0, 9, 9);
		}
		for (my $i = $#$ary; ($i > 0) && ($uex < $$ary[$i]); $i--) {
			($p1x, $p1y) = $obj->pt2pxl($$ary[$i], $dumy);
			$p1y -= $yoff;
			$img->copy($marker, $p1x-4, $p1y-4, 0, 0, 9, 9);
		}
	}	# end for each box plot
	return 1;
}

sub plotBoxAxes {
	my $obj = shift;
	my ($p1x, $p1y, $p2x, $p2y);
	my $img = $obj->{img};
	my ($xl, $xh, $yl, $yh) = ($obj->{xl}, $obj->{xh}, 
		$obj->{yl}, $obj->{yh});

	my $yaxpt = ((! $obj->{yLog}) && ($yl < 0) && ($yh > 0)) ? 0 : $yl;
	my $xaxpt = ((! $obj->{xLog}) && ($xl < 0) && ($xh > 0)) ? 0 : $xl;
#
#	X axis
	($p1x, $p1y) = $obj->pt2pxl($xl, $yaxpt);
	($p2x, $p2y) = $obj->pt2pxl($xh, $yaxpt);
	$img->line($p1x, $p1y, $p2x, $p2y, $obj->{gridColor});
#
#	draw X axis label
	my ($len, $xStart);
	($p2x, $p2y) = $obj->pt2pxl($xh, $yl),
	$len = $sfw * length($obj->{xAxisLabel}),
	$xStart = ($p2x+$len/2 > $obj->{width}-10)
		? ($obj->{width}-10-$len) : ($p2x-$len/2),
	$obj->string(6, 0, $xStart, $p2y+ int(4*$sfh/3), $obj->{xAxisLabel}, $sfw)
		if ($obj->{xAxisLabel});
#
# draw ticks and labels
# 
	my ($i,$px,$py);
#
#	for LOG(X):
#
	my $powk;
	if ($obj->{xLog}) {
		$i = $xl;
		my $n = 0;
		my $k = $i;
		while ($i < $xh) {
			$k = $i + $logsteps[$n++];

			($px,$py) = $obj->pt2pxl($k, $yl);
			($p1x, $p1y) = ($obj->{vertGrid}) ? 
				$obj->pt2pxl($k, $yh) : ($px, $py+2);
			$img->line($px, ($obj->{vertGrid} ? $py : $py-2), 
				$px, $p1y, $obj->{gridColor});

			$powk = ($obj->{timeDomain}) ? 
				restore_temporal(10**$k, $obj->{timeDomain}) : 10**$k,
			$obj->string(6, 90, $px-$sfh/2, $py+length($powk)*$sfw, $powk, $sfw)
				if (($n == 1) && ($px+$sfh < $xStart));

			($n, $i)  = (0, $k)
				if ($n > $#logsteps);
		}
		return 1;
	}

    my $step = $obj->{horizStep}; 
   	my $prtX;
	for ($i = $xl; $i <= $xh; $i += $step ) {
		($px,$py) = $obj->pt2pxl($i, 
			((($obj->{yLog}) || 
			($obj->{vertGrid}) || ($yl > 0) || ($yh < 0)) ? $yl : 0));
		($p1x, $p1y) = ($obj->{vertGrid}) ? 
			$obj->pt2pxl($i, $yh) : ($px, $py+2);
		$img->line($px, ($obj->{vertGrid} ? $py : $py-2), $px, $p1y, $obj->{gridColor});

		next if ($obj->{xAxisVert} && ($px+$sfh >= $xStart));
		$prtX = $obj->{timeDomain} ? restore_temporal($i, $obj->{timeDomain}) : $i;
		$obj->string(6, 90, $px-($sfh>>1), $py+2+length($prtX)*$sfw, $prtX, $sfw), next
			if ($obj->{xAxisVert});

		$obj->string(6, 0, $px-length($prtX)*($sfw>>1), $py+($sfh>>1), $prtX, $sfw);
	}
	return 1;
}

sub plotAll {
	my ($obj, $type, $typeary) = @_;
	my ($i, $n, $k);
	my @tary = ();
	
	foreach (0..$#$typeary) {
		push(@tary, $_) 
			if ($$typeary[$_] == $type);
	}

	foreach $n (@tary) {
		my $ary = $obj->{data}->[$n];
		my $t = $obj->{props}->[$n];
		$t=~s/\s+/ /g;
#		$t = lc $t;
		my @props = split (' ', $t);
		my $color = 'black';
		my $marker = undef;
		my $line = 'line';
		my @areacolors = ();
		my $stacked = 0;
		my $coloridx = 0;
		my $legend;
		my $lwidth = 1;
		my $anchor = 1;
		my $showvals = 0;
		foreach (@props) {
#
#	if its iconic, load the icon image
#
			$marker = $1,
			next
				if /^icon:(\S+)/i;

			$_ = lc $_;
			push(@areacolors, $_), next
				if ($colors{$_});

			$stacked = 1, next
				if ($_ eq 'stack');

			$showvals = $1, next
				if /^showvalues:(\d+)/i;

			$marker = $_,
			next
				if ($valid_shapes{$_} && ($_ ne 'null'));

			$marker = 'fillcircle',
			next
				if ((! $marker) && ($_ eq 'points'));
					
			$marker = undef, next 
				if ($_ eq 'nopoints');

			$line = $_, next
				if /^(line|noline|fill)$/;

			$lwidth = $1, next if /width:(\d+)/;
			
			$anchor = undef if ($_ eq 'float');
		}

		if (($line eq 'fill') && $stacked) {
#
#	pull apart the datapoint arrays and plot them individually from the top
#	to the bottom
			my @newary = ();
			my $j = $#{$ary->[1]};
#
#	in case our color list is short
			my $k = 0;
			my $colorcnt = @areacolors;
			while ($#areacolors < $j) {
				push @areacolors, $areacolors[$k];
				$k++;
				$k = 0 if ($k == $colorcnt);
			}
			my $looplim = ($anchor ? 0 : 1);
			my $ylo = $obj->{yl};
			$ylo = 0 if ($ylo < 0);
			for (; $j >= $looplim; $j--) {
				@newary = ();
				$color = $areacolors[$j-$looplim];
				$i = 0;
				push(@newary, $$ary[$i], ($anchor ? $ylo : $ary->[$i+1]->[0]), $ary->[$i+1]->[$j]),
				$i += 2
					while ($i <= $#$ary);
				$legend = $obj->{legend} ? $obj->{legend}->[$n]->[$j] : undef;
				return undef unless $obj->plotData($n, \@newary, $color, 'fill', $marker,
					$legend, $lwidth, $anchor, $showvals);
			}
			next;
		}

		$legend = $obj->{legend} ? $obj->{legend}->[$n] : undef;

		if (($line eq 'fill') && $anchor) {
#
#	if its anchored, then add the origin points
#
			my @newary = ();
			$i = 0;
			my $yl = $obj->{yl};
			my $yh = $obj->{yh};
			my $yaxpt = ((! $obj->{yLog}) && ($yl < 0) && ($yh > 0)) ? 0 : $yl;

			push(@newary, $$ary[$i], $yaxpt, $$ary[$i+1]), $i += 2
				while ($i <= $#$ary);

			return undef unless $obj->plotData($n, \@newary, 
				$areacolors[$coloridx], $line, $marker,
				$obj->{legend}->[$n], $lwidth, $anchor, $showvals);
		}
		else {
			return undef unless $obj->plotData($n, $ary, $areacolors[$coloridx], $line, $marker,
				$obj->{legend}->[$n], $lwidth, $anchor, $showvals);
		}
		$coloridx++;
		$coloridx = 0 if ($coloridx = $#areacolors);
	}
	return 1;
}

# draws the specified dataset in $obj->{data}
sub plotData {
	my ($obj, $k, $ary, $color, $line, $marker, $legend, $lw, $anchor, $showvals) = @_;
	my ($i, $n, $px, $py, $prevpx, $prevpy, $pyt, $pyb);
	my ($img, $prop, $s, $voff);
	my @props = ();
# legend is left justified underneath
	my ($xl, $xh, $yl, $yh) = ($obj->{xl}, $obj->{xh}, $obj->{yl}, 
		$obj->{yh});
	my ($markw, $markh, $yoff, $wdelta, $hdelta);
	$img = $obj->{img};	

	$color = 'black' unless $color;
	$obj->{$color} = $obj->{img}->colorAllocate(@{$colors{$color}})
		unless $obj->{$color};
		
	if ($marker) {
		$marker = ($valid_shapes{$marker} && ($marker ne 'null')) ? 
			$obj->make_marker($marker, $color) :
			$obj->getIcon($marker);
		return undef unless $marker;
		($markw, $markh) = $marker->getBounds();
		$wdelta = $markw>>1;
		$hdelta = $markh>>1;
	}
	$yoff = ($marker) ? $markh : 2;
#
#	render legend if requested
#
	$obj->addLegend($color, $marker, $legend, ($line eq 'line')) if $legend;
#
#	line/point/area charts
#
#	we need to heuristically sort data sets to optimize the view of 
#	overlapping areagraphs...for now the user will need to be smart 
#	about the order of registering the datasets
#
	$obj->fill_region($obj->{$color}, $ary, $anchor)
		if ($line eq 'fill');

	($prevpx, $prevpy) = (0,0);
	my ($prtX, $prtY);

# draw the rest of the points and lines 
	my $domain = $obj->{symDomain} ? $obj->{domain} : $ary;
	my $xhash = $obj->{symDomain} ? $obj->{domainValues} : undef;
	my $domsize = $obj->{symDomain} ? $#$domain : $#$ary;
	my $x;
	my $incr = $obj->{symDomain} ? 1 : ($line eq 'fill') ? 3 : 2;
	my $offset = ($line eq 'fill') ? 2 : 1;
	my $xd;
#
#	create a brush to draw linegraphs
	my $lbrush;
	if ($line eq 'line') {
		$lbrush = new GD::Image($lw,$lw);
		my $ci = $lbrush->colorAllocate(@{$colors{$color}});
		$lbrush->filledRectangle(0,0,$lw, $lw,$ci);
		$img->setBrush($lbrush);
	}

	for ($x = 0; $x <= $domsize; $x += $incr) {
		$xd = $$xhash{$$domain[$x]} if $obj->{symDomain};
		$i = $obj->{symDomain} ? $xd * 2: $x;
		next unless defined($$ary[$i+1]);

# get next point
		($px, $py) = $obj->pt2pxl(($obj->{symDomain} ? $xd+1 : $$ary[$i]),
			$$ary[$i+$offset] );

# draw line from previous point, maybe
		$img->line($prevpx, $prevpy, $px, $py, gdBrushed)
			if (($line eq 'line') && $i);
		($prevpx, $prevpy) = ($px, $py);

# draw point, maybe
		$img->copy($marker, $px-$wdelta, $py-$hdelta, 0, 0, $markw, 
			$markh)
			if ($marker);

		if ($obj->{genMap} || $showvals) {
			($prtX, $prtY) = ($$ary[$i], $$ary[$i+$offset]);
			$prtY = 10**$prtY if $obj->{yLog};
			$prtX = 10**$prtX if $obj->{xLog};
			$prtY = restore_temporal($prtY, $obj->{timeRange}) if $obj->{timeRange};
			$prtX = restore_temporal($prtX, $obj->{timeDomain}) if $obj->{timeDomain};
			$s = $obj->{symDomain} ? $prtY : "($prtX,$prtY)";
		}
			
		$obj->updateImagemap('CIRCLE', $s, $k, $prtX, $prtY,
			undef, $px, $py, 4)
			if ($obj->{genMap});

		$voff = (length($s) * $tfw)>>1,
		$obj->string($showvals,0,$px-$voff,$py-$yoff, $s, $tfw)
			if $showvals;
	}
	return 1;
}

sub addLegend {
	my ($obj, $color, $shape, $text, $line) = @_;
#
#	add the dataset to the legend
#
	push @{$obj->{_legends}}, [ $color, $shape, $text, $line ] ;
	return 1;
}

sub drawLegend {
	my ($obj) = @_;
#
#	add the dataset to the legend using current color
#	and shape (if any)
#
	my ($color, $shape, $text, $line, $props);
	my $legary = $obj->{_legends};

	my $xadj = 30;
	my $xoff = $obj->{horizEdge};
	my $maxyoff = $obj->{height} - 40;
	my $yoff = $obj->{height} - 40 - 20 - (2 * $tfh);
	my ($w, $h);

	while (@$legary) {
		$props = shift @$legary;
		($color, $shape, $text, $line) = @$props;
		
		$color = 'black' unless $color;
		$shape = $obj->make_marker('fillsquare', $color)
			unless ($shape || $line);
#
#	move to next column if shape too big to fit
#
		($w, $h) = $shape ? $shape->getBounds() : (20, int($tfh * 1.5));

		$yoff = $obj->{height} - 40 - 20 - (2 * $tfh),
		$xoff += $xadj
			if ($yoff + $h > $maxyoff);

		$xadj = ((($w < 20) ? 20 : $w) + ($tfw * (length($text)+2)))
			if ($xadj < ((($w < 20) ? 20 : $w) + ($tfw * (length($text)+2))));
		
		my $img = $obj->{img};
		$img->line($xoff, $yoff+4, $xoff+20, $yoff+4, $obj->{$color})
			if $line;

		$obj->string(5, 0,$xoff + ($line ? 25 : ($w + 5)),$yoff, $text, $tfw);

		$img->copy($shape, $xoff+5, $yoff, 0, 0, $w-1, $w-1)
			if $shape;
		
		$yoff += ($h < int($tfh * 1.5)) ? int($tfh * 1.5) : $h;
	}
	return 1;
}

# compute pixel coordinates from datapoint
sub pt2pxl {
	my ($obj, $x, $y, $z) = @_;
	my $plottype = $obj->{plotTypes} & (HISTO|GANTT);

	return (
		int($obj->{horizEdge} + ($x - $obj->{xl}) * $obj->{xscale}),
		int($obj->{vertEdge} - ($y - $obj->{yl}) * $obj->{yscale})
	 ) unless (defined($z) || $plottype);
#
#	histo version
	return (
		int($obj->{horizEdge} + ($y - $obj->{yl}) * $obj->{yscale}),
		int($obj->{vertEdge} - ($x - $obj->{xl}) * $obj->{xscale})
	 ) unless defined($z);
#
#	translate x,y,z into x,y
#
	my $tx = ($x - $obj->{xl}) * $obj->{xscale};
	my $ty = ($y - $obj->{yl}) * $obj->{yscale};
	my $tz = ($z - $obj->{zl}) * $obj->{zscale};

	return
		$obj->{horizEdge} + int($tx + ($tz * 0.433)),
		$obj->{vertEdge} - int($ty + ($tz * 0.25))
		unless $plottype;
#
#	histo version
	return
		$obj->{horizEdge} + int($ty + ($tz * 0.433)),
		$obj->{vertEdge} - int($tx + ($tz * 0.25));
}
# draw the axes, labels, title, grid/ticks and tick labels

sub plotAxes {
	my $obj = shift;
	return $obj->plot3DAxes
		if ($obj->{zAxisLabel} || $obj->{threed});

	my ($p1x, $p1y, $p2x, $p2y);
	my $img = $obj->{img};
	my ($xl, $xh, $yl, $yh) = ($obj->{xl}, $obj->{xh}, 
		$obj->{yl}, $obj->{yh});

	my $yaxpt = ((! $obj->{yLog}) && ($yl < 0) && ($yh > 0)) ? 0 : $yl;
	my $xaxpt = ((! $obj->{xLog}) && ($xl < 0) && ($xh > 0)) ? 0 : $xl;
	my $plottypes = $obj->{plotTypes};
	
	if ($obj->{vertGrid} || $obj->{horizGrid}) {
#
#	gridded, create a rectangle
#
		($p1x, $p1y) = $obj->pt2pxl ($xl, $yl);
		($p2x, $p2y) = $obj->pt2pxl ($xh, $yh);

  		$img->rectangle( $p1x, $p1y, $p2x, $p2y, $obj->{gridColor});
#
#	hilight the (0,0) axes, if available
#
#	draw X-axis
		($p1x, $p1y) = $obj->pt2pxl($xl, $yaxpt);
		($p2x, $p2y) = $obj->pt2pxl($xh, $yaxpt);
		$img->filledRectangle($p1x, $p1y-1,$p2x, $p2y-1,$obj->{gridColor}); # wide line
#	draw Y-axis
		($p1x, $p1y) = $obj->pt2pxl($xaxpt, $yl);
		($p2x, $p2y) = $obj->pt2pxl($xaxpt, $yh);
		$img->filledRectangle($p1x-1, $p2y,$p2x+1, $p1y,$obj->{gridColor}); # wide line
  	}
  	else {
#
#	X axis
		($p1x, $p1y) = $obj->pt2pxl($xl, $yaxpt);
		($p2x, $p2y) = $obj->pt2pxl($xh, $yaxpt);
		$img->line($p1x, $p1y, $p2x, $p2y, $obj->{gridColor});
#
#	draw at bottom if yl < 0
		($p1x, $p1y) = $obj->pt2pxl($xl, $yl),
		($p2x, $p2y) = $obj->pt2pxl($xh, $yl),
		$img->line($p1x, $p1y, $p2x, $p2y, $obj->{gridColor})
			if ($yl < 0);
	}
#
#	draw X axis label
	my ($len, $xStart, $xStart2);
	($p2x, $p2y) = $obj->pt2pxl($xh, $yl);
#		$obj->{vertGrid} || $obj->{horizGrid}) ? $yl : $yaxpt),
	$len = $sfw * length($obj->{xAxisLabel}),
	$xStart = ($p2x+$len/2 > $obj->{width}-10)
		? ($obj->{width}-10-$len) : ($p2x-$len/2),
	$obj->string(6,0, $xStart, $p2y+ int(4*$sfh/3), $obj->{xAxisLabel}, $sfw)
		if ($obj->{xAxisLabel});

# Y axis
	($p1x, $p1y) = $obj->pt2pxl($xaxpt, $yl);
	($p2x, $p2y) = $obj->pt2pxl((($obj->{vertGrid}) ? $xl : $xaxpt), $yh);
	
	$img->line($p1x, $p1y, $p2x, $p2y, $obj->{gridColor})
		if ((! $obj->{'vertGrid'}) && (! $obj->{horizGrid}));

	$xStart2 = $p2x - length($obj->{yAxisLabel}) * ($sfw >> 1),
	$obj->string(6,0, ($xStart2 > 10 ? $xStart2 : 10), 
		$p2y - 3*($sfh>>1), $obj->{yAxisLabel}, $sfw)
		if ($obj->{yAxisLabel});
#
# draw ticks and labels
# 
	my ($i,$px,$py, $step, $j, $txt);
   	my $prevx = 0;
# 
# horizontal
#
#	for LOG(X):
#
	my $powk;
	if ($obj->{xLog}) {
		$i = $xl;
		my $n = 0;
		my $k = $i;
		while ($i < $xh) {
			$k = $i + $logsteps[$n++];

			($px,$py) = $obj->pt2pxl($k, $yl);
			($p1x, $p1y) = ($obj->{vertGrid}) ? 
				$obj->pt2pxl($k, $yh) : ($px, $py+2);
			$img->line($px, ($obj->{vertGrid} ? $py : $py-2), 
				$px, $p1y, $obj->{gridColor});
#
#	don't draw tick labels if we're overwriting the axis label
#
			$powk = ($obj->{timeDomain}) ? 
				restore_temporal(10**$k, $obj->{timeDomain}) : 10**$k,
			$obj->string(6, 90, $px-$sfh/2, 
				$py+length($powk)*$sfw, $powk)
				if (($n == 1) && ($px+$sfh < $xStart));

			($n, $i)  = (0 , $k)
				if ($n > $#logsteps);
		}
	}
	elsif ($obj->{symDomain}) {
#
# symbolic domain
#
		my $ary = $obj->{domain};
    
		for ($i = 1, $j = 0; $i < $xh; $i++, $j++ ) {
			($px,$py) = $obj->pt2pxl($i, $yl);
			($p1x, $p1y) = ($obj->{vertGrid}) ? 
				$obj->pt2pxl($i, $yh) : ($px, $py+2);
			$img->line($px, ($obj->{vertGrid} ? $py : $py-2), 
				$px, $p1y, $obj->{gridColor});
#
#	skip the label if it would overlap
#
			next if ($obj->{xAxisVert} && ($sfh+1 > ($px - $prevx)));
#
#	truncate long labels
#
			$txt = ($obj->{timeDomain}) ? 
				restore_temporal($$ary[$j], $obj->{timeDomain}) : $$ary[$j];
			$txt = substr($txt, 0, 22) . '...' 
				if (length($txt) > 25);

			if ($obj->{xAxisVert}) {
				$prevx = $px;
				next if ($px+$sfh >= $xStart);
				$obj->string(6, 90, $px-($sfh>>1), 
					$py+2+length($txt)*$sfw, $txt, $sfw);
				next;
			}

			next if (((length($txt)+1) * $sfw) > ($px - $prevx));
			$prevx = $px;

			$obj->string(6,0, $px-length($txt)*($sfw>>1), 
				$py+($sfh>>1), $txt, $sfw);
		}
	}
	else {
	    $step = $obj->{horizStep}; 
		for ($i = $xl; $i <= $xh; $i += $step ) {
			($px,$py) = $obj->pt2pxl($i, $yl);
			($p1x, $p1y) = ($obj->{vertGrid}) ? 
				$obj->pt2pxl($i, $yh) : ($px, $py+2);
			$img->line($px, ($obj->{vertGrid} ? $py : $py-2), 
				$px, $p1y, $obj->{gridColor});

			$txt = ($obj->{timeDomain}) ? 
				restore_temporal($i, $obj->{timeDomain}) : $i;
			$txt = substr($txt, 0, 22) . '...' 
				if (length($txt) > 25);

			next if ((! $obj->{xAxisVert}) && 
				($px - $prevx < (length($txt) * $sfw)));
			next if ($obj->{xAxisVert} && ($px - $prevx < $sfw));
			$prevx = $px;
			next if ($obj->{xAxisVert} &&  ($px+$sfh >= $xStart));
			
			$obj->string(6, 90, $px-($sfh>>1), 
				$py+2+length($txt)*$sfw, $txt, $sfw),
			next
				if ($obj->{xAxisVert});

			$obj->string(6, 0,$px-length($txt)*($sfw>>1), 
				$py+($sfh>>1), $txt, $sfw);
		}
	}
#
# vertical
#
#	for LOG(Y):
#
	if ($obj->{yLog}) {
		$i = $yl;
		my $n = 0;
		my $k = $yl;
		while ($k < $yh) {
			($px,$py) = $obj->pt2pxl(
				((($obj->{xLog}) || ($obj->{horizGrid})) ? 
				$xl : $xaxpt), $k);
			($p1x, $p1y) = ($obj->{horizGrid}) ? 
				$obj->pt2pxl($xh, $k) : ($px+2, $py);
			$img->line(($obj->{horizGrid} ? $px : $px-2), $py, 
				$p1x, $py, $obj->{gridColor});

			$powk = ($obj->{timeRange}) ? 
				restore_temporal(10**$k, $obj->{timeRange}) : 10**$k,
			$obj->string(6, 0, $px-5-length($powk)*$sfw, 
				$py-($sfh>>1), $powk, $sfw)
				if ($n == 0);
			
			$k = $i + $logsteps[$n++];
			($n, $i) = (0, $k)
				if ($n > $#logsteps);
		}
		return 1;
	}

	$step = $obj->{vertStep};
#
#	if y tick step < (2 * sfh), skip every other label
#
	($px,$py) = $obj->pt2pxl((($obj->{horizGrid}) ? $xl : $xaxpt), $yl);
	($p1x,$p1y) = $obj->pt2pxl((($obj->{horizGrid}) ? $xl : $xaxpt), 
		$yl+$step);
	my $skip = ($p1y - $py < ($sfh<<1)) ? 1 : 0;
	my $tickv = $yl;
	for ($i=0, $j = 0; $tickv < $yh; $i++, $j++ ) {
		$tickv = $yl + ($i * $step);
		last if ($tickv > $yh);
		($px,$py) = $obj->pt2pxl((($obj->{horizGrid}) ? $xl : $xaxpt), $tickv);
		($p1x, $p1y) = ($obj->{horizGrid}) ? 
			$obj->pt2pxl($xh, $tickv) : ($px+2, $py);
		$img->line(($obj->{horizGrid} ? $px : $px-2), $py, $p1x, $py, 
			$obj->{gridColor});

		next if (($skip) && ($j&1));
		$txt = $obj->{timeRange} ? restore_temporal($tickv, $obj->{timeRange}) : $tickv,
		$obj->string(6,0, $px-5-length($txt)*$sfw, $py-($sfh>>1), $txt, $sfw);
	}
	return 1;
}

sub plotHistoAxes {
	my ($obj) = @_;
	return $obj->plot3DAxes
		if ($obj->{zAxisLabel} || $obj->{threed});

	my ($p1x, $p1y, $p2x, $p2y);
	my $img = $obj->{img};
	my ($xl, $xh, $yl, $yh) = ($obj->{xl}, $obj->{xh}, 
		$obj->{yl}, $obj->{yh});
	my $plottypes = $obj->{plotTypes};
#
#	draw horizontal and vertical axes
	($p1x, $p1y) = $obj->pt2pxl ($xl, $yl),
	($p2x, $p2y) = $obj->pt2pxl($xh, $yl),
	$img->line($p1x, $p1y, $p2x, $p2y, $obj->{gridColor}),
	($p2x, $p2y) = $obj->pt2pxl ($xl, $yh),
	$img->line($p1x, $p1y, $p2x, $p2y, $obj->{gridColor})
		unless ($obj->{vertGrid} || $obj->{horizGrid});

	if ($obj->{vertGrid} || $obj->{horizGrid}) {
#
#	hilight the (0,0) axes, if available
#
#	draw horizontal axis
		($p1x, $p1y) = $obj->pt2pxl($xl, $yl);
		($p2x, $p2y) = $obj->pt2pxl($xl, $yh);
		$img->filledRectangle($p1x, $p1y-1, $p2x, $p2y-1,$obj->{gridColor}); # wide line
#	draw vertical axis
		($p1x, $p1y) = $obj->pt2pxl($xl, $yl);
		($p2x, $p2y) = $obj->pt2pxl($xh, $yl);
		$img->filledRectangle($p1x-1, $p2y, $p2x+1, $p1y,$obj->{gridColor}); # wide line

		($p1x, $p1y) = $obj->pt2pxl($xl, 0),
		($p2x, $p2y) = $obj->pt2pxl($xh, 0),
		$img->filledRectangle($p1x-1, $p2y, $p2x+1, $p1y,$obj->{gridColor})
			if (($yl < 0) && ($yh > 0));
#
#	gridded, create a rectangle
#
		($p1x, $p1y) = $obj->pt2pxl ($xh, $yl);
		($p2x, $p2y) = $obj->pt2pxl ($xl, $yh);
  		$img->rectangle( $p1x, $p1y, $p2x, $p2y, $obj->{gridColor});
  	}
#
#	draw horizontal axis label
	my ($len, $xStart, $xStart2);
	$len = $sfw * length($obj->{yAxisLabel}),
	$xStart = ($p2x+$len/2 > $obj->{width}-10) ? 
		($obj->{width}-10-$len) : ($p2x-$len/2),
	$obj->string(6,0, $xStart, $p2y+ int(4*$sfh/3), $obj->{yAxisLabel}, $sfw)
		if ($obj->{yAxisLabel});

# vertical axis label
	($p2x, $p2y) = $obj->pt2pxl($xh, $yl),
	$xStart2 = $p2x - ((length($obj->{xAxisLabel}) * $sfw) >> 1),
	$obj->string(6, 0,($xStart2 > 10 ? $xStart2 : 10), 
		$p2y - 3*($sfh>>1), $obj->{xAxisLabel}, $sfw)
		if $obj->{xAxisLabel};
#
# draw ticks and labels
# 
	my ($i,$px,$py, $step, $j, $txt);
# 
# vertical symbolic domain
#
	my $ary = $obj->{domain};
    
	my $prevx = $obj->{vertEdge};
	for ($i = 1, $j = 0; $i < $xh; $i++, $j++) {
		($px,$py) = $obj->pt2pxl($i, $yl);
		($p1x, $p1y) = ($obj->{horizGrid}) ? 
			$obj->pt2pxl($i, $yh) : ($px+2, $py);
		$img->line(($obj->{horizGrid} ? $px : $px-2), $py, 
			$p1x, $py, $obj->{gridColor});
#
#	skip the label if undefined or it would overlap or its Gantt
#
		next unless (($plottypes & HISTO) && defined($$ary[$j]) && ($sfh < ($prevx - $py)));
		$prevx = $py;
		$txt = ($obj->{timeDomain}) ? 
			restore_temporal($$ary[$j], $obj->{timeDomain}) : $$ary[$j];
#
#	truncate long labels
#
		$txt = substr($txt, 0, 22) . '...' 
			if (length($txt) > 25);

		$obj->string(6, 0, ($px-(length($txt)*$sfw)-5), 
			$py-($sfh>>1), $txt, $sfw);
	}
#
# horizontal
#
#	for LOG(Y):
#
	$prevx = 0;
	if ($obj->{yLog}) {
		$i = $yl;
		my $n = 0;
		my $k = $i;
		my $powk;
		while ($i < $yh) {
			$k = $i + $logsteps[$n++];
			($px,$py) = $obj->pt2pxl($xl, $k);
			($p1x, $p1y) = ($obj->{vertGrid}) ? 
				$obj->pt2pxl($xh, $k) : ($px, $py+2);
			$img->line($px, ($obj->{vertGrid} ? $py : $py-2),
				$px, $p1y, $obj->{gridColor});
#
#	skip the label if it would overlap
#
			next if ($obj->{xAxisVert} && ($sfh > ($px - $prevx)));

			$powk = ($obj->{timeRange}) ? 
				restore_temporal(10**$k, $obj->{timeRange}) : 10**$k;

			($n, $i)  = (0, $k)
				if ($n > $#logsteps);

			next if (length($powk) * ($sfw>>1) > ($px - $prevx));
			next unless ($n == 1);

			$prevx = $px;

			next if ($obj->{xAxisVert} && ($px+$sfh >= $xStart));
			$obj->string(6, 90, $px-($sfh>>1), 
				$py+2+length($powk)*$sfw, $powk, $sfw),
			next
				if $obj->{xAxisVert};

			$obj->string(6, 0, $px-(length($powk) * ($sfw>>1)),
				$py+4, $powk, $sfw);
		}
		return 1;
	}

	$step = $obj->{horizStep};
	for ($i=$yl, $j = 0; $i <= $yh; $i+=$step, $j++ ) {
		($px,$py) = $obj->pt2pxl($xl, $i);
		($p1x,$p1y) = ($obj->{vertGrid}) ? $obj->pt2pxl($xh, $i) : ($px, $py+2);
		$img->line($px, ($obj->{vertGrid} ? $py : $py-2), $px, $p1y, $obj->{gridColor});
		next if ($obj->{xAxisVert} && ($px - $prevx < $sfh+3));

		$txt = $obj->{timeRange} ? restore_temporal($i, $obj->{timeRange}) : $i;
		next unless ($obj->{xAxisVert} || 
			(length($txt) * ($sfw>>1) < ($px - $prevx)));
		$prevx = $px;

		next if ($obj->{xAxisVert} && ($px+$sfh >= $xStart));
		$obj->string(6, 90, $px-($sfh>>1), 
			$py+2+length($txt)*$sfw, $txt, $sfw),
		next
			if $obj->{xAxisVert};

		$obj->string(6,0, $px-(length($txt) * ($sfw>>1)),
			$py+4, $txt, $sfw);
	}
	return 1;
}

sub drawTitle {
	my ($obj) = @_;
	my ($w,$h) = (gdMediumBoldFont->width, gdMediumBoldFont->height);

# centered below chart
	my ($px,$py) = ($obj->{width}/2, $obj->{height} - 40 + $h);

	($px,$py) = ($px - length ($obj->{title}) * $w/2, $py-$h/2);
	$obj->string(7, 0, $px, $py, $obj->{title}, $w); 
}

sub drawSignature {
	my ($obj) = @_;
	my $fw = ($tfw * length($obj->{signature})) + 5;
# in lower right corner
	my ($px,$py) = ($obj->{width} - $fw, $obj->{height} - ($tfh * 2));

	$obj->string(5, 0, $px, $py, $obj->{signature}, $tfw); 
}

sub fill_region {
	my ($obj, $ci, $ary, $anchor) = @_;
	my $img = $obj->{img};
	my($x, $y, $xbot, $ybot, $xval);
	my @bottom;
#	
# Create a new polygon
	my $poly = GD::Polygon->new();
#
# Add the data points; data is organized as (x, ybot, ytop)
	for (my $i = 0; $i < @$ary; $i += 3)
	{
		next unless defined($$ary[$i]);
		$xval = $obj->{symDomain} ? ($i/3)+1 : $$ary[$i];
		($x, $y) = $obj->pt2pxl($xval, $$ary[$i+2]);
		($xbot, $ybot) = $obj->pt2pxl($xval, $$ary[$i+1]);
		$poly->addPt($x, $y);
		push @bottom, [$x, $ybot];
	}

	$poly->addPt($_->[0], $_->[1])
		foreach (reverse @bottom);

	# Draw a filled and a line polygon
	$img->filledPolygon($poly, $ci);
	$img->polygon($poly, $ci);

	1;
}

sub make_marker {
	my ($obj, $mtype, $mclr) = @_;

	my $brush = new GD::Image(9,9);
	my $white = $brush->colorAllocate(255, 255, 255);
	my $clr = $brush->colorAllocate(@{$colors{$mclr}});
	$brush->transparent($white);
	$mtype = $valid_shapes{$mtype};

# square, filled	
	$brush->filledRectangle(0,0,6,6,$clr),
	return $brush
		if ($mtype == 1);

# Square, open
	$brush->rectangle( 0, 0, 6, 6, $clr ),
	return $brush
		if ($mtype == 2);

# Cross, horizontal
	$brush->line( 0, 4, 8, 4, $clr ),
	$brush->line( 4, 0, 4, 8, $clr ),
	return $brush
		if ($mtype == 3);

# Cross, diagonal
	$brush->line( 0, 0, 8, 8, $clr ),
	$brush->line( 8, 0, 0, 8, $clr ),
	return $brush
		if ($mtype == 4);

# Diamond, filled
	$brush->line( 0, 4, 4, 8, $clr ),
	$brush->line( 4, 8, 8, 4, $clr ),
	$brush->line( 8, 4, 4, 0, $clr ),
	$brush->line( 4, 0, 0, 4, $clr ),
	$brush->fillToBorder( 4, 4, $clr, $clr ),
	return $brush
		if ($mtype == 5);

# Diamond, open
	$brush->line( 0, 4, 4, 8, $clr ),
	$brush->line( 4, 8, 8, 4, $clr ),
	$brush->line( 8, 4, 4, 0, $clr ),
	$brush->line( 4, 0, 0, 4, $clr ),
	return $brush
		if ($mtype == 6);

# Circle, filled
	$brush->arc( 4, 4, 8 , 8, 0, 360, $clr ),
	$brush->fillToBorder( 4, 4, $clr, $clr ),
	return $brush,
		if ($mtype == 7);

# must be Circle, open
	$brush->arc( 4, 4, 8, 8, 0, 360, $clr ),
	return $brush
		if ($mtype == 8);
#
#	dot - contributed by Andrea Spinelli
	$brush->setPixel( 4,4, $clr ),
	return  $brush
 		if ( $mtype == 10 );
}

sub getIcon {
	my ($obj, $icon, $isbar) = @_;
	my $pat = GD::Image->can('newFromGif') ? 
		'png|jpe?g|gif' : 'png|jpe?g';

	$obj->{errmsg} = 
	'Unrecognized icon file format. File qualifier must be .png, .jpg, ' . 
		(GD::Image->can('newFromGif') ? '.jpeg, or .gif.' : 'or .jpeg.'),
	return undef
		unless ($icon=~/\.($pat)$/i);

	$obj->{errmsg} = "Unable to open icon file $icon.",
	return undef
		unless open(ICON, "<$icon");

	my $iconimg = ($icon=~/\.png$/i) ? GD::Image->newFromPng(*ICON) :
	  ($icon=~/\.gif$/i) ? GD::Image->newFromGif(*ICON) :
	    GD::Image->newFromJpeg(*ICON);
	close(ICON);
	$obj->{errmsg} = "GD cannot read icon file $icon.",
	return undef
		unless $iconimg;

	my ($iconw, $iconh) = $iconimg->getBounds();
	$obj->{errmsg} = "Icon image $icon too wide for chart image.",
	return undef
		if (($isbar && ($iconw > $obj->{brushWidth})) ||
			($iconw > $obj->{plotWidth}));
		
	$obj->{errmsg} = "Icon image $icon too tall for chart image.",
	return undef
		if ($iconh > $obj->{plotHeight});
	return $iconimg;
}

sub drawIcons {
	my ($obj, $iconimg, $pxl, $pyb, $pxr, $pyt) = @_;
#
#	force the icon into the defined image area
#
	my ($iconw, $iconh) = $iconimg->getBounds();
	my $img = $obj->{img};
	if ($pxl == $pxr) {
		$pxl -= int($iconw/2);

		my $srcY = 0;
		my $h = $iconh;
#
#	handle candlestick points
		$img->copy($iconimg, $pxl, $pyb, 0, $srcY, $iconw, $h),
		return 1
			if ($pyt == 0);

		while ($pyb > $pyt) {	
			$h = $pyb - $pyt,
			$srcY = $iconh - $h,
				if ($iconh > ($pyb - $pyt));
			$pyb -= $h;
			$img->copy($iconimg, $pxl, $pyb, 0, $srcY, $iconw, $h);
		}
		return 1;
	}
#
#	must be histogram
	$pyb -= int($iconh/2); # this might need adjusting

	my $limX = $iconw;
	while ($pxl < $pxr) {	
		$limX = ($pxr - $pxl) if ($iconw > ($pxr - $pxl));
		$img->copy($iconimg, $pxl, $pyb, 0, 0, $limX, $iconh);
		$pxl += $limX;
	}
	1;
}

sub plot3DAxes {
	my ($obj) = @_;
	my $img = $obj->{img};
	my ($xl, $xh, $yl, $yh, $zl, $zh) = 
		($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh}, $obj->{zl}, $obj->{zh});

	my $numRanges = scalar @{$obj->{data}};
	my $zbarw = ($obj->{zh} - $obj->{zl})/($obj->{zAxisLabel} ? $obj->{Zcard}*2 : 2);
	my $ishisto = ($obj->{plotTypes} & HISTO);

	$zl -= (0.8);
	$zh += $zbarw;
	my $yc = ($yl < 0) ? 0 : $yl;
	my @v = ($ishisto) ? 
	(
		$xl, $yl, $zl,	# bottom front left
		$xl, $yl, $zh,	# bottom rear left
		$xh, $yl, $zl,	# top front left
		$xh, $yl, $zh,	# top rear left
		$xl, $yh, $zl,	# bottom front right
		$xl, $yh, $zh,	# bottom rear right
		$xh, $yh, $zh,	# top rear right
#
#	in case floor is above bottom of graph
		$xl, $yl, $zl,	# bottom front left
		$xl, $yh, $zl,	# bottom front right
		$xl, $yh, $zh,	# bottom rear right
		$xl, $yl, $zh	# bottom rear left
	) :
#	its a barchart
	(
		$xl, $yl, $zl,	# bottom front left
		$xl, $yl, $zh,	# bottom rear left
		$xl, $yh, $zl,	# top front left
		$xl, $yh, $zh,	# top rear left
		$xh, $yl, $zl,	# bottom front right
		$xh, $yl, $zh,	# bottom rear right
		$xh, $yh, $zh,	# top rear right
#
#	in case floor is above bottom of graph
		$xl, $yc, $zl,	# bottom front left
		$xh, $yc, $zl,	# bottom front right
		$xh, $yc, $zh,	# bottom rear right
		$xl, $yc, $zh	# bottom rear left
	);
	my @xlatverts = ();
#
#	generate vertices of cabinet projection
#
	my ($i, $j);
	for ($i = 0; $i <= $#v; $i+=3) {
		push(@xlatverts, $obj->pt2pxl($v[$i], $v[$i+1], $v[$i+2]));
	}
#
#	draw left and rear wall, and floor
#
	for ($i = 0; $i <= $#axesverts; $i+=2) {
		$img->line($xlatverts[$axesverts[$i]],
			$xlatverts[$axesverts[$i]+1],
			$xlatverts[$axesverts[$i+1]],
			$xlatverts[$axesverts[$i+1]+1], $obj->{gridColor});
	}
#
#	draw grid lines if requested
#
	my ($gx, $gy, $hx, $hy);
	if ($obj->{horizGrid}) {
		my ($imax, $imin, $step) = 
			($obj->{yh}, $obj->{yl}, 
				($ishisto ? $obj->{horizStep} : $obj->{vertStep}));
		
		for ($i = $imin; $i < $imax; $i += $step) {
			($gx, $gy) = $obj->pt2pxl($xl, $i, $zl);
			($hx, $hy) = $obj->pt2pxl($xl, $i, $zh);
			$img->line($gx, $gy, $hx, $hy, $obj->{gridColor});
			($gx, $gy) = $obj->pt2pxl($xh, $i, $zh);
			$img->line($gx, $gy, $hx, $hy, $obj->{gridColor});
		}
	}
#
#	we forgot the axis labels!!!
#	draw Y-axis at rear-left-top corner
#	draw X-axis at front-right-bottom corner
#	draw Z-axis vertical from front-right-bottom along image edge
#
	my ($xal, $yal, $zal) = ($obj->{plotTypes} & HISTO) ? 
		($obj->{yAxisLabel}, $obj->{xAxisLabel}, $obj->{zAxisLabel}) :
		($obj->{xAxisLabel}, $obj->{yAxisLabel}, $obj->{zAxisLabel});
	if ($xal) {
		($gx, $gy) = ($yc == $yl) ? $obj->pt2pxl($v[12], $v[13], $v[14]) :
			$obj->pt2pxl($v[15], $v[16], $v[17]);
		$gx -= ($sfw * length($xal)),
		$gy += 10,
		$obj->string(6, 0, $gx, $gy, $xal, $sfw);
	}

	($gx, $gy) = $obj->pt2pxl($v[9], $v[10], $v[11]),
	$gx -= ($sfw * length($yal)/2),
	$gy -= ($sfh + 5),
	$obj->string(6, 0, $gx, $gy, $yal, $sfw)
		if $yal;

	($gx, $gy) = $obj->pt2pxl($v[15], $v[16], $v[17]),
	$gx += $sfh + 10,
	$gy += ($sfw * length($zal)),
	$obj->string(6, 90, $gx, $gy, $zal, $sfw)
		if $zal;

# need these later to redraw floor and tick labels
	$obj->{xlatVerts} = \@xlatverts;
	1;
}

sub plot3DTicks {
#
#	draw axis tick values
#
	my ($obj) = @_;
	my $img = $obj->{img};
	my ($xl, $xh, $yl, $yh, $zl, $zh) =
		($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh}, $obj->{zl}, $obj->{zh});

	my $numRanges = scalar @{$obj->{data}};
	my $zcard = $obj->{zAxisLabel} ? $obj->{Zcard} : 1;
	my $zbarw = ($zh - $zl)/($zcard*2);
	my $ishisto = ($obj->{plotTypes} & HISTO);

	my $data = $obj->{data}->[0];
	$zl -= (0.8);
	$zh += $zbarw;
	my $yc = ($yl < 0) ? 0 : $yl;
	my $i;
	my $xlatverts = $obj->{xlatVerts};

	my $text = '';
	my ($gx, $gy, $hx, $hy);
	if ($obj->{zAxisLabel}) {
		my $zs = $obj->{zValues};
		my $xv = $ishisto ? $xl : $xh;
		my $yv = $ishisto ? $yh : $yl;
		foreach (0..$#$zs) {
			($gx, $gy) = $obj->pt2pxl($xv, $yv, $_+1+0.8);
			$text = $$zs[$_];
			$text = substr($text, 0, 22) . '...' if (length($text) > 25);
			$obj->string(6, 0, $gx, $gy, $text, $sfw);
		}
	}
	my $xs = $obj->{xValues};
	my $xoff = ($yl >= 0) ? 1 : $ishisto ? 0 : 0.5;
	my $zv = (($yl >= 0) || $ishisto) ? $zl : $zh; 
	foreach (0..$#$xs) {
		($gx, $gy) = $obj->pt2pxl($_+$xoff, $yl, $zv);
		$text = $$xs[$_];
		$text = substr($text, 0, 22) . '...' if (length($text) > 25);

		$gy += (length($text) * $sfw) + 5,
		$obj->string(6, 90, $gx-($sfh>>1), $gy, $text, $sfw),
		next
			unless $ishisto;

		$gx -= (length($text) * $sfw) + 5;
		$obj->string(6, 0, $gx, $gy-($sfw>>1), $text, $sfw);
	}
	my $ystep = $ishisto ? $obj->{horizStep} : $obj->{vertStep};
	for ($i = $yl; $i < $yh; $i += $ystep) {
		($gx, $gy) = $obj->pt2pxl($xl, $i, $zl);
		$text = $i;
		$text = substr($text, 0, 22) . '...' if (length($text) > 25);

		$gx -= ((length($text) * $sfw) + 5),
		$obj->string(6, 0, $gx, $gy-($sfw>>1), $text, $sfw),
		next
			unless $ishisto;

		$gy += ((length($text) * $sfw) + 5),
		$obj->string(6, 90, $gx-($sfh>>1), $gy, $text, $sfw);
	}
	return 1 if $ishisto;
#
#	redraw the floor in case we had negative values
	for ($i = 18; $i <= $#axesverts; $i+=2) {
		$img->line($$xlatverts[$axesverts[$i]],
			$$xlatverts[$axesverts[$i]+1],
			$$xlatverts[$axesverts[$i+1]],
			$$xlatverts[$axesverts[$i+1]+1], $obj->{gridColor});
	}

	1;
}

sub plot3DBars {
	my ($obj) = @_;
	
	my $img = $obj->{img};
	my $numRanges = scalar @{$obj->{data}};
	my ($xoff, $zcard) = ($obj->{zAxisLabel}) ? 
		(1.0, $obj->{Zcard}) : (0.9, 1);
	my $xbarw = $xoff/$numRanges;
	my $zbarw = ($obj->{zh} - $obj->{zl})/($zcard*2);
	my ($xvals, $zvals) = ($obj->{xValues}, $obj->{zValues});
	my @fronts = ();
	my @tops = ();
	my @sides = ();
	my $legend = $obj->{legend};
	my $k = 0;
	my $color = 'black';
	my $ary;
	my $showvals;
	my $ys;
	my $t;
	my $numPts = $#{$obj->{data}->[0]};
	my @props;
	my $stacked = undef;
	my @barcolors = ();
	my $svfont = 5;
#
#	extract properties
#
	for ($k = 0; $k < $numRanges; $k++) {
		push @tops, [];
		push @fronts, [];
		push @sides, [];
		$t = $obj->{props}->[$k];
		$t=~s/\s+/ /g;
		$t = lc $t;
		@props = split (' ', $t);
		$stacked = 0;
		foreach (@props) {
			$showvals = [ ], $svfont = $1, next if /^showvalues:(\d+)/i;
			$stacked = 1, next if ($_ eq 'stack');
#
#	generate light, medium, and dark version for front,
#	top, and side faces
#
			$color = $_,
			push(@barcolors, $_),
			$obj->{$color} = $img->colorAllocate(@{$colors{$_}}),
			push(@{$tops[$k]}, $obj->{$color}),
			push(@{$fronts[$k]}, $img->colorAllocate(int($colors{$_}->[0] * 0.8), 
				int($colors{$_}->[1] * 0.8), int($colors{$_}->[2] * 0.8))),
			push(@{$sides[$k]}, $img->colorAllocate(int($colors{$_}->[0] * 0.6), 
				int($colors{$_}->[1] * 0.6), int($colors{$_}->[2] * 0.6))),
				if ($colors{$_});
		}
		
		if (($legend) && ($$legend[$k])) {
			$obj->addLegend($color, undef, $$legend[$k], undef), next
				unless $stacked;

			$obj->addLegend($barcolors[$_], undef, $$legend[$k]->[$_], undef)
				foreach (0..$#{$$legend[$k]});
		}
	}
#
#	draw each bar
#	WE NEED A BETTER CONTROL VALUE HERE!!! since different plots may not
#	have the exact same domain!!!
#
	my ($i, $j) = (0,0);
	unless (($numRanges > 1) || $stacked) {
#
#	to support multicolor single ranges
		$ary = $obj->{data}->[0];
		for (; $i <= $numPts; $i+=3) {
			$ys = $$ary[$i+1];
			$obj->drawCube($$ary[$i], $$ys[0], $$ys[1], $$ary[$i+2],
				0, $fronts[0]->[$j], $tops[0]->[$j], $sides[0]->[$j], 
				$xoff, $xbarw, $zbarw, $$xvals[$$ary[$i]-1], 
				$$zvals[$$ary[$i+2]-1], $showvals);
			$obj->renderCubeValues($showvals, $svfont) if $showvals;
			$j++;
			$j = 0 if ($j > $#{$fronts[0]});
		}
		return 1;
	}
#
#	multirange (or stacked), draw the bar for each dataset
	$numRanges--;
	for (; $i <= $numPts; $i+=3) {
		foreach $k (0..$numRanges) {
			$numPts = $#{$obj->{data}->[$k]};
			$ary = $obj->{data}->[$k];
			$ys = $$ary[$i+1];
			$obj->drawCube($$ary[$i], $$ys[$_-1], $$ys[$_], $$ary[$i+2],
				$k, $fronts[$k]->[$_-1], $tops[$k]->[$_-1], $sides[$k]->[$_-1], 
				$xoff, $xbarw, $zbarw, $$xvals[$$ary[$i]-1], 
				$$zvals[$$ary[$i+2]-1], $showvals, $stacked),
				foreach (1..$#$ys);
			$obj->renderCubeValues($showvals, $svfont) if $showvals;
		}
	}
	return 1;
}

sub computeSides {
	my ($x, $xoff, $barw, $k) = @_;
	
	return ($x - ($xoff/2) + ($k * $barw), 
		$x - ($xoff/2) + (($k+1) * $barw));
}

sub drawCube {
	my ($obj, $x, $yl, $yh, $z, $k, $front, $top, $side, 
		$xoff, $xbarw, $zbarw, $xval, $zval, $showvals, $stacked) = @_;
	my ($xl, $xr) = computeSides($x, $xoff, $xbarw, $k);
	my $ishisto = $obj->{plotTypes} & HISTO;
	my @val_stack = ();
	my ($mx, $px, $py);

	$z++;
#
#	generate value coordinates of visible vertices
	my @v = $ishisto ?
	(
		$xl, $yl, $z - $zbarw,	# left bottom front
		$xr, $yl, $z - $zbarw,	# left top front
		$xr, $yl, $z + $zbarw,	# left top rear
		$xr, $yh, $z + $zbarw,	# right top rear
		$xr, $yh, $z - $zbarw,	# right top front
		$xl, $yh, $z - $zbarw,	# right bottom front
		$xl, $yh, $z + $zbarw	# right bottom rear
	) :
	(
		$xl, $yl, $z - $zbarw,	# left bottom front
		$xl, $yh, $z - $zbarw,	# left top front
		$xl, $yh, $z + $zbarw,	# left top rear
		$xr, $yh, $z + $zbarw,	# right top rear
		$xr, $yh, $z - $zbarw,	# right top front
		$xr, $yl, $z - $zbarw,	# right bottom front
		$xr, $yl, $z + $zbarw	# right bottom rear
	);
	
	my @xlatverts = ();
	my $img = $obj->{img};
	my ($i, $j);
#
#	translate value vertices to pixel coordinate using
#	cabinet projection
	for ($i = 0; $i < 21; $i+=3) {
		push(@xlatverts, $obj->pt2pxl($v[$i], $v[$i+1], $v[$i+2]));
	}
	my $xwidth = $xlatverts[12] - $xlatverts[0];

	my @faces = ($top, $front, $side);
#
#	render faces as filled polygons to obscure any prior cubes
#
	for ($i = 0; $i < 3; $i++) {
		my $poly = new GD::Polygon;
		my $ary = $polyverts[$i];
		$poly->addPt($xlatverts[$$ary[$_]],$xlatverts[$$ary[$_]+1])
			foreach (0..3);
		$img->filledPolygon($poly, $faces[$i]);
	}
	for ($i = 0; $i < 18; $i+=2) {
		$img->line($xlatverts[$vert2lines[$i]], 
			$xlatverts[$vert2lines[$i]+1],
			$xlatverts[$vert2lines[$i+1]],
			$xlatverts[$vert2lines[$i+1]+1], $obj->{black});
	}
	return 1 unless ($obj->{genMap} || $showvals);
#
#	generate image map for top(right) face only
#
	my $y = ($yh > 0) ? $yh : $yl;
	if ($obj->{genMap}) {
		my $text = ($obj->{zAxisLabel}) ? "($xval, $y, $zval)" : "($xval, $y)";
		my $ary = $polyverts[($ishisto ? 2 : 0)];
		my @ptsary = ();
		push(@ptsary, $xlatverts[$$ary[$_]], $xlatverts[$$ary[$_]+1])
			foreach (0..3);
		$obj->updateImagemap('POLY', $text, 0, $xval, $y, $zval, @ptsary);
	}
	return 1 unless $showvals;
#
#	push values info on a stack, then render *after* we've drawn all the cubes
#	(for stacked bars)
#
	$mx = ($xr + $xl)/($ishisto ? 1.9 : 2);
	($px, $py) = $obj->pt2pxl($mx, $yh, $z - $zbarw);
#
#	adjust value position based on +/- and stacking
#
	my $valsz = (length($y) * $tfw);
	if ($stacked) {
#		$px += (($y > 0) ? (-15 - $valsz) : 15) if $ishisto;
#		$py += (($y < 0) ? 10 : (($xwidth > ($obj->{yMaxlen} * $tfw)) ? 10 : 10 + $valsz)) 
		$px -= (15 + $valsz) if $ishisto;
		$py += (($xwidth > $obj->{yMaxlen}) ? 10 : 10 + $valsz) 
			unless $ishisto;
	}
	else {
		$px += (($y < 0) ? -15 : 15) if $ishisto;
		$py += (($y < 0) ? (($xwidth < ($obj->{yMaxlen} * $tfw)) ? 10 + $valsz : 10) : -10) 
			unless $ishisto;
	}
	$y = $yh - $yl if ($stacked && ($yh > 0) && ($yl > 0));
	$y = $yl - $yh if ($stacked && ($yh < 0) && ($yl < 0));
	push(@$showvals, $px, $py, $y, ($xwidth > ($obj->{yMaxlen} * $tfw)));
	return 1;
}

sub renderCubeValues {
	my ($obj, $val_stack, $svfont) = @_;
#
#	render the top text label
#
	my ($px, $py, $y, $xwidth, $ishisto);
	$ishisto = $obj->{plotTypes} & HISTO;
	my $img = $obj->{img};
	
	while (@$val_stack) {
		$px = shift @$val_stack;
		$py = shift @$val_stack;
		$y = shift @$val_stack;
		$xwidth = shift @$val_stack;

		$obj->string($svfont, 90, $px, $py, $y, $tfw), next
			unless ($ishisto || $xwidth);
		$obj->string($svfont,0, $px, $py, $y, $tfw);
	}
	return 1;
}

sub abs { my $x = shift; return ($x < 0) ? -1*$x : $x; }

sub plotPie {
	my ($obj) = @_;
	my $ary = $obj->{data}->[0];
#
#	extract properties
#
	my @colormap = ();
	my $t = $obj->{props}->[0];
	$t=~s/\s+/ /g;
	$t = lc $t;
	my @props = split (' ', $t);
	my $img = $obj->{img};
	my $showvals = 6;
	foreach (@props) {
		$showvals = $1, next if /^showvalues:(\d+)/;
		push(@colormap, $img->colorAllocate(@{$colors{$_}}) )
			if $colors{$_};
	}
#
#	render each wedge, in clockwise order, starting from 12 o'clock
#
	my $i = 0;
#
#	compute sum of wedge values
#	and max length of wedge labels
#
	my $total = 0;
	my $arc = 0;
	my $maxlen = 0;
	my $len = 0;
	for ($i = 0; $i <= $#$ary; $i+=2) { 
		$total += $$ary[$i+1]; 
		$len = length($$ary[$i]);
		$len = 25 if ($len > 25);
		$maxlen = $len if ($len > $maxlen);
	}
	$maxlen++;
	$maxlen *= $tfw;
	$obj->{errmsg} = 'Insufficient image size for graph.',
	return undef
		if ($maxlen * 2 > ($obj->{width} * 0.5));
#
#	compute center coords and radius of pie
#
	my $xc = int($obj->{width}/2);
	my $yc = int(($obj->{height}/2) - 30);
	my $hr = $xc - $maxlen - 10;
	my $vr = $obj->{threed} ? int($hr * tan(30 * (3.1415926/180))) : $hr;
	my $piefactor = $obj->{threed} ? cotan(30 * (3.1415926/180)) : 1;

	$vr = $yc - 20, $hr = $vr
		unless ($obj->{threed} || ($yc - 20 > $vr));
	$vr = $yc - 20, $hr = int($vr/tan(30 * (3.1415926/180)))
		if ($obj->{threed} && ($vr > $yc - 20));

	$img->arc($xc, $yc, $hr*2, $vr*2, 0, 360, $obj->{black});
	$img->arc($xc, $yc+20, $hr*2, $vr*2, 0, 180, $obj->{black}),
	$img->line($xc-$hr, $yc, $xc-$hr, $yc+20, $obj->{black}),
	$img->line($xc+$hr, $yc, $xc+$hr, $yc+20, $obj->{black})
		if $obj->{threed};

#	$img->line($xc, $yc, $xc, $yc - $radius, $obj->{black});
#
#	now draw each wedge
#
	my $w = 0;
	my $j = 0;
	for ($i = 0, $j = 0; $i <= $#$ary; $i+=2, $j++) { 
		$w = $$ary[$i+1];
		my $color = $colormap[$j%(scalar @colormap)];
		$arc = $obj->drawWedge($arc, $color, $xc, 
			$yc, $vr, $hr, $w/$total, $$ary[$i], $w, $piefactor, $showvals);
	}
	return 1;
}

sub drawWedge {
	my ($obj, $arc, $color, $xc, $yc, $vr, $hr, $pct, $text, $val, $piefactor, $showvals) = @_;
	my $img = $obj->{img};
#
#	locate coords at 80% of radius that bisects the wedge;
#	we'll use this to fill the color and apply the text
#
	my ($x, $y, $fx, $fy);
#
#	if imagemap, generate 10 degree coordinates up 
#	to the arc of the wedge
#
	if ($obj->{genMap}) {
		my $tarc = 0;

		my @ptsary = ($xc, $yc);
		while ($tarc <= (2 * 3.1415926 * $pct)) {
			($x, $y) = computeCoords($xc, $yc, $vr, $hr, 
				$arc + $tarc, $piefactor);
			push(@ptsary, $x, $y);
			last if ((2 * 3.1415926 * $pct) - $tarc < (2 * 3.1415926/36));
			$tarc += (2 * 3.1415926/36);
		}
		if ($tarc < (2 * 3.1415926 * $pct)) {
			($x, $y) = computeCoords($xc, $yc, $vr, $hr, 
				$arc + (2 * 3.1415926 * $pct), $piefactor);
			push(@ptsary, $x, $y);
		}
		$val = restore_temporal($val, $obj->{timeRange}) if $obj->{timeRange};
		$obj->updateImagemap('POLY', 
			"$val(" . (int($pct * 1000)/10) . '%)', 0, $text, $val, 
			int(10000*$pct)/100, @ptsary);
	}
	my $start = $arc;
	my $bisect = $arc + ($pct * 3.1415926);
	$arc += (2 * 3.1415926 * $pct); 
	my $visible = ($obj->{threed} &&
		(($start < 3.1415926/2) || ($start >= (1.5 * 3.1415926)) ||
		($arc < 3.1415926/2) || ($arc >= (1.5 * 3.1415926))));
	$start = (($arc < 3.1415926/2) || ($arc >= (1.5 * 3.1415926))) ?
			$arc : $start;

#	print "Plotting $text with $pct % angle $arc\n";
	($x, $y) = computeCoords($xc, $yc, $vr, $hr, $arc, $piefactor);
	($fx, $fy) = computeCoords($xc, $yc, $vr * 0.6, $hr* 0.6, $bisect, 
		$piefactor);
	$img->line($xc, $yc, $x, $y, $obj->{black});
	$img->fill($fx, $fy, $color);
#
#	draw front face line if visible
	if ($visible) {
		$img->line($x, $y, $x, $y+20, $obj->{black})
			if ($start == $arc);
		($fx, $fy) = computeCoords($xc, $yc+10, $vr, $hr, $start, $piefactor);
		$fx += ($start == $arc) ? 2 : -2;
		$img->fill($fx, $fy, $color);
	}
#
#	render text
#
	if ($text) {
		my ($gx, $gy) = computeCoords($xc, $yc, $vr, $hr, $bisect, $piefactor);
		$gy -= $sfh if (($bisect > 3.1415926/2) && ($bisect <= (1.5 * 3.1415926)));

		$gy += 20 if ($obj->{threed} && 
			(($bisect < 3.1415926/2) || ($bisect >= (1.5 * 3.1415926))));
		$gx -= ((length($text)+1) * $sfw) 
			if (($gx < $xc) && ($bisect > 3.1415926/4));
		$gx -= (length($text) * $sfw/2) 
			if (($gx > $xc) && ($bisect > (1.75 * 3.1415926)));
		$gx += $sfw if ($gx > $xc);
		$gx -= (length($text) * $sfw/2) 
			if (($gx == $xc) || ($bisect <= 3.1415926/4));

		$obj->string($showvals, 0,$gx, $gy, $text, $tfw);
	}
	return $arc;
}

sub computeCoords {
	my ($xc, $yc, $vr, $hr, $arc, $piefactor) = @_;

	return (
		int($xc + $piefactor * $vr * cos($arc + (3.1415926/2))), 
		int($yc + $piefactor * ($vr/$hr) * $vr * sin($arc+ (3.1415926/2)))
	);
}

sub tan {
	my ($angle) = @_;
	
	return (sin($angle)/cos($angle));
}

sub cotan {
	my ($angle) = @_;
	
	return (cos($angle)/sin($angle));
}

sub updateImagemap {
	my ($obj, $shape, $alt, $plotNum, $x, $y, $z, @pts) = @_;
	$y = '' unless defined($y);
	$z = '' unless defined($z);
#
#	do different for Perl map
#
	return $obj->updatePerlImagemap($plotNum, $x, $y, $z, $shape, @pts)
		if (uc $obj->{mapType} eq 'PERL');

	my $imgURL = $obj->{mapURL};
	my $imgScript = $obj->{mapScript};
#
#	if modifier is supplied, call it before applying any of our
#	transforms
#
	if ($obj->{mapModifier}) {
		my $maphash = {
			URL => $imgURL,
			Script => $imgScript,
			Name => $obj->{genMap},
			PLOTNUM => $plotNum,
			X => $x, Y => $y, Z => $z,
			AltText => $alt
		};
		&{$obj->{mapModifier}}($maphash);
		$imgURL = $maphash->{URL};
		$imgScript = $maphash->{Script};
		$alt = $maphash->{AltText};
	}
#
#	render image map element:
#	hotspot is an 8 pixel diameter circle centered on datapoint for
#	lines, points, areas, and candlesticks.
#	the user can provide both a URL to be invoked, and/or a 
#	script function to be locally executed, when the hotspot is clicked.
#	Special variable names $PLOTNUM, $X, $Y, $Z can be specified
#	anywhere in the URL/script string to be interpolated to the
#	the equivalent input values
#
	$shape = uc $shape;
	$x =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
	$y =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
	$z =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
	$plotNum =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
	my $imgmap = $obj->{imgMap};
#
#	interpolate special variables
#
	$imgURL=~s/:PLOTNUM\b/$plotNum/g,
	$imgURL=~s/:X\b/$x/g,
	$imgURL=~s/:Y\b/$y/g,
	$imgURL=~s/:Z\b/$z/g
		if ($imgURL);
#
#	interpolate special variables
#
	$imgScript=~s/:PLOTNUM\b/$plotNum/g,
	$imgScript=~s/:X\b/$x/g,
	$imgScript=~s/:Y\b/$y/g,
	$imgScript=~s/:Z\b/$z/g
		if ($imgScript);

	$imgmap .= "\n<AREA TITLE=\"$alt\" " .
		(($obj->{mapURL}) ? " HREF=\"$imgURL\" " : ' NOHREF ');
	$imgmap .= " $imgScript "
		if ($imgScript);

	$imgmap .= " SHAPE=$shape COORDS=\"" . join(',', @pts) . '">';
	$obj->{imgMap} = $imgmap;
	return 1;
}

sub updatePerlImagemap {
	my ($obj, $plotNum, $x, $y, $z, $shape, @pts) = @_;
#
#	render image map element:
#	hotspot is an 8 pixel diameter circle centered on datapoint for
#	lines, points, areas, and candlesticks.
#
	my $imgmap = $obj->{imgMap};
	$imgmap .= ",\n" unless ($imgmap eq '');
	$imgmap .= 
"\{
	plotnum => $plotNum,
	X => '$x',
	Y => '$y',
	Z => '$z',
	shape => '$shape',
	coordinates => [ " . join(',', @pts) . "]
}";
	$obj->{imgMap} = $imgmap;
	return 1;
}

sub addLogo {
	my ($obj) = @_;
	my $pat = GD::Image->can('newFromGif') ? 'png|jpe?g|gif' : 'png|jpe?g';
	my ($logo, $imgw, $imgh) = ($obj->{logo}, $obj->{width}, $obj->{height});
	my $img = $obj->{img};

	$obj->{errmsg} = 
	'Unrecognized logo file format. File qualifier must be .png, .jpg, ' .
		(GD::Image->can('newFromGif') ? '.jpeg, or .gif.' :	'or .jpeg.'),
	return undef
		unless ($logo=~/\.($pat)$/i);

	$obj->{errmsg} = 'Unable to open logo file.',
	return undef
		unless open(LOGO, "<$logo");

	my $logoimg = ($logo=~/\.png$/i) ? GD::Image->newFromPng(*LOGO) :
	  ($logo=~/\.gif$/i) ? GD::Image->newFromGif(*LOGO) :
	    GD::Image->newFromJpeg(*LOGO);
	close(LOGO);
	
	$obj->{errmsg} = 'GD cannot read logo file.',
	return undef
		unless $logoimg;

	my ($logow, $logoh) = $logoimg->getBounds();
#
#	force the logo into the defined image area
#
	my $srcX = ($logow > $imgw) ? ($logow - $imgw)>>1 : 0;
	my $srcY = ($logoh > $imgh) ? ($logoh - $imgh)>>1 : 0;
	my $dstX = ($logow > $imgw) ? 0 : ($imgw - $logow)>>1;
	my $dstY = ($logoh > $imgh) ? 0 : ($imgh - $logoh)>>1;
	my $h = ($logoh > $imgh) ? $imgh : $logoh;
	my $w = ($logow > $imgw) ? $imgw : $logow;
	$img->copy($logoimg, $dstX, $dstY, $srcX, $srcY, $w-1, $h-1);
	return 1;
}

#
#	use plotHistoAxes to make axes

sub setGanttPoints {
	my ($obj, $taskary, $starts, $ends, $assignees, $pcts, @depends) = @_;
	my $props = pop @depends;
	my @data = ();
	my %taskhash = ();
	my %starthash = ();
	my $yh = -1E38;
	my $xh = 0;
	my $i;
	for ($i = 0; $i <= $#$taskary; $i++) {
		next unless (defined($$taskary[$i]) && 
			defined($$starts[$i]) && 
			defined($$ends[$i]));
		
		$obj->{errmsg} = 'Duplicate task name.',
		return undef
			if $taskhash{uc $$taskary[$i]};
		
		my $startdate = convert_temporal($$starts[$i], $obj->{timeRange});
		my $enddate = convert_temporal($$ends[$i], $obj->{timeRange});
		$obj->{errmsg} = 'Invalid start date.',
		return undef
			unless defined($startdate);
		$yh = $enddate if ($enddate > $yh);
		
		$obj->{errmsg} = 'Invalid end date.',
		return undef
			unless (defined($enddate) && ($enddate >= $startdate));
		
		$obj->{errmsg} = 'Invalid completion percentage.',
		return undef
			unless ((! $$pcts[$i]) || 
				(($$pcts[$i]=~/^\d+(\.\d+)?$/) &&
				($$pcts[$i] >= 0) && ($$pcts[$i] <= 100)));

		my @deps = ();
		foreach (@depends) {
			next unless $_->[$i];

			$obj->{errmsg} = "Invalid dependency; $$taskary[$i] cannot be self-dependent.",
			return undef
				if (uc $_->[$i] eq uc $$taskary[$i]);
			push(@deps, $_->[$i]);
		}

		$taskhash{uc $$taskary[$i]} = $startdate;
		$starthash{$startdate} = 
			[ [ $$taskary[$i], $startdate, $enddate, $$assignees[$i], $$pcts[$i], \@deps ] ], next
			unless $starthash{$startdate};
		push @{$starthash{$startdate}}, 
			[ $$taskary[$i], $startdate, $enddate, $$assignees[$i], $$pcts[$i], \@deps ] ;
	}		
	foreach my $d (@depends) {
		foreach (0..$#$d) {
			next unless $$d[$_];
			$obj->{errmsg} = 'Unknown task ' . $$d[$_],
			return undef
				unless $taskhash{uc $$d[$_]};

			$obj->{errmsg} = "Invalid dependency; $$d[$_] precedes $$taskary[$_].",
			return undef
				if ($taskhash{uc $$d[$_]} < $taskhash{uc $$taskary[$_]});
		}
	}
#
#	sort tasks on startdate
	my @started = sort numerically keys(%starthash);
	foreach my $startdate (@started) {
		push(@data, @$_),
		$xh++
			foreach (@{$starthash{$startdate}});
	}
	push(@{$obj->{data}}, \@data);
	push(@{$obj->{props}}, $props);
	$obj->{yl} = $started[0] unless (defined($obj->{yl}) && ($obj->{yl} < $started[0]));
	$obj->{yh} = $yh unless (defined($obj->{yh}) && ($obj->{yh} > $yh));
	$obj->{xl} = 1;
	$obj->{xh} = $xh;
	$obj->{plotTypes} |= GANTT;
	return 1;
}

sub plotGantt {
	my ($obj) = @_;
#
#	collect color
	my $props = $obj->{props}->[0];
	my $data = $obj->{data}->[0];
	my ($xl, $xh, $yl, $yh) = ($obj->{xl}, $obj->{xh}, $obj->{yl}, $obj->{yh});
	my ($s, $t, $i, $j, $deps, $depend, $srcx, $color);
	my ($offset, $span, $pct, $compend, $prtT, $starts, $ends);
	my $img = $obj->{img};

	my $showvals = 6;
	foreach (split(' ', $props)) {
		$showvals = $1, next if /^showvalues:(\d+)/;
		$color = $_ if $colors{$_};
	}
	$obj->{$color} = $img->colorAllocate(@{$colors{$color}})
		unless $obj->{$color};
	$obj->{compcolor} = $img->colorAllocate($colors{$color}->[0] * 0.6,
		$colors{$color}->[1] * 0.6,$colors{$color}->[2] * 0.6);
#
#	precompute start/end pts of bar
	my @pts = ();
	my %taskhash = ();
	for ($i = 0, $j = ($#$data+1)/6; $i <= $#$data; $i+=6, $j--) {
		$taskhash{uc $$data[$i]} = $#pts + 1;
		push (@pts, $obj->pt2pxl($j, $$data[$i + 1]),
			$obj->pt2pxl($j, $$data[$i + 2]));
	}
#
#	draw dependency lines 1st
	my $marker = $obj->make_marker('filldiamond', 'black');
	my ($markw, $markh) = $marker->getBounds;
	for ($i = 0; $i <= $#$data; $i+=6) {
		$s = $taskhash{uc $$data[$i]};
		$deps = $$data[$i+5];
		next unless ($deps && ($#$deps >= 0));
		foreach (@$deps) {
			$t = $taskhash{uc $_};
			$img->line($pts[$s+2], $pts[$s+3], $pts[$t], $pts[$s+3], $obj->{black})
				if ($pts[$s+2] < $pts[$t]); # horiz line if src ends before tgt starts
			$srcx = ($pts[$s+2] < $pts[$t]) ? $pts[$t] : 
				($pts[$s+2] < $pts[$t+2]) ? $pts[$s+2] : $pts[$t];
			$img->line($srcx, $pts[$s+3], $srcx, $pts[$t+3]-$sfh, $obj->{black});
			$img->copy($marker, $srcx-($markw/2), $pts[$t+3]-$sfh, 0, 0, 
				$markw-1, $markh-1);
		}
	}
#
#	then draw boxes
	$offset = $sfh/2;
	for ($i = 0; $i <= $#$data; $i+=6) {
		$s = $taskhash{uc $$data[$i]};
#
#	compute pct. completion and create intermediate start/end pts
		$span = $pts[$s+2] - $pts[$s];
		$pct = $$data[$i+4]/100;
		$compend = $pts[$s] + int($span * $pct);
		$img->filledRectangle($pts[$s], $pts[$s+1] - $offset, 
			$compend, $pts[$s+3] + $offset, $obj->{compcolor})
			if ($pct);
		$img->filledRectangle($compend, $pts[$s+1] - $offset, 
			$pts[$s+2], $pts[$s+3] + $offset, $obj->{$color})
			if ($pct != 1);
#
#	now fill in taskname and assignee text
		$prtT = $$data[$i];
		$prtT .= '(' . $$data[$i+3]. ')' if $$data[$i+3];
		$prtT .= ' : ' . $$data[$i+4] . '%';
		$obj->string($showvals, 0, $pts[$s], $pts[$s+1] - $offset - $sfh,
				$prtT, $tfw);

		$starts = restore_temporal($$data[$i+1], $obj->{timeRange}),
		$ends = restore_temporal($$data[$i+2], $obj->{timeRange}),

		$prtT = $starts . '->' . $ends,
		$obj->updateImagemap('RECT', $prtT, 
			$$data[$i], $starts, $ends, $$data[$i+4] . ':' . $$data[$i+3],
			$pts[$s], $pts[$s+1] - $offset, $pts[$s+2], $pts[$s+3] + $offset)
			if $obj->{genMap};
	}
	1;
}

sub setQuadPoints {
	my ($obj, @ranges) = @_;
	my ($min, $max) = (1.0E+38, 1.0E-38);
	my $props = pop @ranges;
	$obj->{errmsg} = 'Invalid dataset supplied for quadtree',
	return undef
		unless ((ref $ranges[0]) && (ref $ranges[0] eq 'ARRAY') 
			&& (@{$ranges[0]} > 2));
	my $cells = @{$ranges[0]};
	my @dataset = ();
	push (@dataset, [ ])
		foreach (1..$cells);

	foreach my $x (@ranges) {
		$obj->{errmsg} = 'Invalid dataset supplied for quadtree',
		return undef
			unless ((ref $x) && (ref $x eq 'ARRAY') && ($#$x > 1));
		$obj->{errmsg} = 'Unbalanced dataset supplied for quadtree',
		return undef
			unless ($cells == @$x);
#
#	transform tabular format into clustered format
#
		push @{$dataset[$_-1]}, $x->[$_-1]
			foreach (1..$cells);
	}
	foreach (@{$ranges[$#ranges]}) {
		next unless defined($_);
#
#	adjust min/max intensity values
#
		$min = $_ unless ($min < $_);
		$max = $_ unless ($max > $_);
	}
	$obj->{yl} = $min;
	$obj->{yh} = $max;
#
#	generate a tree structure to cluster the data
#	for easier plotting later
#
	my %keyhash = ();
	$cells--;
	$obj->{data} = \@dataset;
	$obj->clusterQuadPts([ 0..$cells ], 0, \%keyhash, '');
	$obj->{data}->[0] = \%keyhash;
	$obj->{props}->[0] = $props;
	$obj->{plotTypes} |= QUADTREE;
	return 1;
}

sub clusterQuadPts {
	my ($obj, $rowlist, $keycol, $keyhash, $category) = @_;
	my $result = 0;
#
#	if its last index column, just sum the value
#
	my $rows = $obj->{data};
	my $ttlcols = @{$$rows[$$rowlist[0]]} - 1;
	if ($keycol == $ttlcols - 2) {
#
#	save the key, value and intensity in the hash
#
		$$keyhash{$$rows[$_]->[$keycol]} = 
			[ ($category . ':' . $$rows[$_]->[$keycol]), 
				$$rows[$_]->[$keycol+1], 
				$$rows[$_]->[$keycol+2] ],
		$result += $$rows[$_]->[$keycol+1]
			foreach (@$rowlist);
		return $result;
	}
#
#	collect distinct keycols values and create array
#
	my %idxhash = ();
	foreach (@$rowlist) {
#
#	accumulate key values; create new child node hash on first occurance
#
		$idxhash{$$rows[$_]->[$keycol]} = [ ]
			unless $idxhash{$$rows[$_]->[$keycol]};
#
#	accumulate indexes of rows in the same category
#
		push @{$idxhash{$$rows[$_]->[$keycol]}}, $_;
	}
#
#	recurse to compute totals of each child node
#
	foreach (keys(%idxhash)) {
		my %lclhash = ();	# create a new hash on every pass
		$$keyhash{$_} = 
			[ \%lclhash, $obj->clusterQuadPts($idxhash{$_}, $keycol+1, \%lclhash, 
				($category eq '') ? $_ : ($category . ':' . $_)) ];
	}
#
#	now compute our subtotal
#
	$result += $$keyhash{$_}->[1]
		foreach (keys(%$keyhash));
	return $result;
}

sub dumpQuadData {
	my ($group, $tabcnt) = @_;
	
	print ' ' x (4*$tabcnt), $group , "\n" and return 1
		unless (ref $group);
	
	foreach (@$group) {
		if (ref $_ eq 'HASH') {
			foreach my $cat (keys(%{$_})) {
				dumpQuadData($cat, $tabcnt+1), next if (ref $cat);
				print ' ' x (4*$tabcnt), $cat , ' => {', "\n";
				dumpQuadData($_->{$cat}, $tabcnt+1);
			}
		}
		elsif (ref $_ eq 'ARRAY') {
			foreach my $cat (0..$#$_) {
				print ' ' x (4*$tabcnt), $cat , ' => [', "\n";
				dumpQuadData($_->[$cat], $tabcnt+1);
			}
		}
		else {
			print ' ' x (4*$tabcnt), $_ , "\n";
		}
	}
}

sub plotQuadtree {
	my ($obj) = @_;
#
# generate color gradient
#
	$obj->computeGradient;
#
#	then render within defined margins
#	note we always leave 40 pixel margins on each side
#
	$obj->renderQuadTree([ $obj->{data}->[0] ], 40, 40, $obj->{width} - 80, 
		$obj->{height} - 80, 'v', '');
	return 1;
}
#
#	sub to generate a quadtree via recursion
#
sub renderQuadTree {
	my ($obj, $group, $xorig, $yorig, $w, $h, $splitdir) = @_;
	
#	dumpQuadData($group, 0);
	
	my @cluster1 = ();
	my @cluster2 = ();
	my ($ttl, $half, $hash, $no_more_room, $w1, $w2, $h1, $h2);
#
#	if the node is a singleton, then partition
#	its children
#
	while ((ref $$group[0] eq 'HASH') && (! $#$group)) {
		my @newgroup = ();
		$hash = $$group[0];
		push(@newgroup, (ref $$hash{$_}->[0]) ? $$hash{$_}->[0] : $$hash{$_})
			foreach (keys(%$hash));
		$group = \@newgroup;
	}
#
#	at the atom level, so draw the area
	if (! ref $$group[0]) {
		my $img = $obj->{img};
		my $colormap = $obj->{colormap};
		my $color;
		foreach (@$colormap) {
#
#	locate color that matches our intensity
#
			$color = $_->[5], last
				if ($$group[2] >= $_->[3] && $$group[2] <= $_->[4]);
		}
		$img->filledRectangle($xorig, $yorig, $xorig+$w, $yorig+$h, $color);
		$img->rectangle($xorig, $yorig, $xorig+$w, $yorig+$h, $obj->{black});
		my ($category, $item) = ($1,$2) if ($$group[0]=~/^(.*):(.+?)$/);
		$obj->updateImagemap('RECT', 
			"$$group[0]=$$group[1]($$group[2])",
			$$group[2], $category, $item, $$group[1], 
			$xorig, $yorig, $xorig+$w, $yorig+$h)
			if $obj->{genMap};
		return 1;
	}
#
#	if our group is all atoms, recursively split them up
#
	if (ref $$group[0] eq 'ARRAY') {
		return $obj->renderQuadTree($$group[0], $xorig, $yorig, $w, $h, $splitdir)
			if ($#$group == 0);

		my $ttl = 0;
		$ttl += $_->[1]
			foreach (@$group);
 		$half = $ttl/2;
 		foreach (@$group) {
			$half -= $_->[1],
			push(@cluster1, $_),
			next
				if ($half >= $_->[1]);
			push(@cluster2, $_);
		}
#
#	divide the area based on current split direction
		$no_more_room = 0;
		if ($splitdir eq 'v') {
			$w1 = int($w * ((($ttl/2) - $half)/$ttl));
			$w2 = $w - $w1;
			$no_more_room = ($w2 <= 0);
		}
		else {
			$h1 = int($h * ((($ttl/2) - $half)/$ttl));
			$h2 = $h - $h1;
			$no_more_room = ($h2 <= 0);
		}
#
#	render each half
#
		return undef
			unless (($splitdir eq 'v') ?
				$obj->renderQuadTree(((@cluster1 == 1) ? $cluster1[0] : \@cluster1), 
					$xorig, $yorig, $w1, $h, 'h') :
				$obj->renderQuadTree(((@cluster1 == 1) ? $cluster1[0] : \@cluster1),
					$xorig, $yorig, $w, $h1, 'v'));

		return ($no_more_room ? 1 : 
			($splitdir eq 'v') ?
			$obj->renderQuadTree(((@cluster2 == 1) ? $cluster2[0] : \@cluster2), 
				$xorig+$w1, $yorig, $w2, $h, 'h') :
			$obj->renderQuadTree(((@cluster2 == 1) ? $cluster2[0] : \@cluster2), 
				$xorig, $yorig+$h1, $w, $h2, 'v'));
	}
#
#	at non-leaf node, so partition
#
#	partition group into 2 nearly equal halves
#
	my @ttlhash = ();
	my $i = 0;
	$ttl = 0;
	foreach $hash (@$group) {
		$ttlhash[$i] = 0;
		$ttlhash[$i] += $$hash{$_}->[1]
			foreach (keys(%$hash));
		$ttl += $ttlhash[$i];
		$i++;
	}
	$i = 0;
	$half = $ttl/2;
	foreach $hash (@$group) {
		$half -= $ttlhash[$i++],
		push(@cluster1, $hash),
		next
			if (($half > 0) && ($i < $#ttlhash));
		push(@cluster2, $hash);
	}
#
#	divide the area based on current split direction
#
	$no_more_room = 0;
	if ($splitdir eq 'v') {
		$w1 = int($w * ((($ttl/2) - $half)/$ttl));
		$w2 = $w - $w1;
		$no_more_room = ($w2 <= 0);
	}
	else {
		$h1 = int($h * ((($ttl/2) - $half)/$ttl));
		$h2 = $h - $h1;
		$no_more_room = ($h2 <= 0);
	}
#
#	render each half
#
	return undef
		unless (($splitdir eq 'v') ?
			$obj->renderQuadTree(\@cluster1, $xorig, $yorig, $w1, $h, 'h') :
			$obj->renderQuadTree(\@cluster1, $xorig, $yorig, $w, $h1, 'v'));

	return ($no_more_room ? 1 : 
		($splitdir eq 'v') ?
		$obj->renderQuadTree(\@cluster2, $xorig+$w1, $yorig, $w2, $h, 'h') :
		$obj->renderQuadTree(\@cluster2, $xorig, $yorig+$h1, $w, $h2, 'v'));
}

sub computeGradient {
	my ($obj) = @_;
#
#	compute color gradient from min and max intensity
#	values and input property string
#
	my @colormap = ();
	my @t = split(' ', $obj->{props}->[0]);
	foreach (@t) {
		push @colormap, $colors{$_}
			if defined($colors{$_});
#
#	may need showvalues in future
#
	}
#
#	compute intensity steps using 24 equal segments
#	then assign intensity ranges to colormap in equal
#	segments
#	NOTE that the last color in list is used as upper bound
#	of gradient shading
#
	$obj->{yh} *= 2, $obj->{yl} = 0
		if ($obj->{yh} == $obj->{yl});
	my $incr = ($obj->{yh} - $obj->{yl})/24;
	my $shadestep = ($obj->{yh} - $obj->{yl})/$#colormap;
	my $min = $obj->{yl};
	my $max;
	$_->[3] = $min,
	$_->[4] = $min + $shadestep, 
	$min += $shadestep
		foreach (@colormap);
		
	my @newmap = ();
	my ($redincr, $greenincr, $blueincr) = (0,0,0);
	my $img = $obj->{img};
	my ($thiscolor, $nextcolor);
	$nextcolor = $colormap[0];
	my ($redcomp, $greencomp, $bluecomp);
	my $i;
	foreach (1..$#colormap) {

		$thiscolor = $nextcolor;
		$nextcolor= $colormap[$_];
		$min = $thiscolor->[3];
		$max = $thiscolor->[4];

		$i = int(($max - $min)/$incr);
		$redincr = ($nextcolor->[0] - $thiscolor->[0])/$i;
		$greenincr = ($nextcolor->[1] - $thiscolor->[1])/$i;
		$blueincr = ($nextcolor->[2] - $thiscolor->[2])/$i;
		my ($redcomp, $greencomp, $bluecomp, $min, $max) = @$thiscolor;
#
#	compute the (min,max) and allocate color for each step of current color segment
#
		push(@newmap, [ $redcomp, $greencomp, $bluecomp, $min, $min + $incr,
			$img->colorAllocate($redcomp, $greencomp, $bluecomp) ]),
		$min += $incr,
		$redcomp += $redincr, 
		$greencomp += $greenincr, 
		$bluecomp += $blueincr
			while ($min < $max);
	}
	$obj->{colormap} = \@newmap;
	return 1;
}
#
#	validate that font exists, and if so,
#	map our std. pt sizes to the closest available size
#
sub loadFont {
	my ($obj, $font) = @_;
	
	my $gd_text;
	my $ptsz;
	my $rc;
	foreach (5,6,7) {
		$gd_text = GD::Text::Align->new($obj->{img},
			valign => 'top', halign => 'center') or return undef;
		$ptsz = $_;
		while ($ptsz < 12) {
			$rc = $gd_text->set_font($font, $ptsz);
			last if $rc;
			$ptsz++;
		}
		return undef unless ($ptsz < 13);
		$fontMap{$_} = $gd_text;
	}
	return 1;
}
#
#	render a string using either the
#	provided font, or default font
#
sub string {
	my ($obj, $size, $angle, $x, $y, $val, $fontsz) = @_;

	my $img = $obj->{img};
	$angle = 0 unless $angle;
	$angle = 3.1415926 * ($angle/360);
	
	my $rc;
	my $font = $obj->{font};
	unless ($font eq 'gd') {
		unless ($fontMap{$size}) {
			my $gd_text = GD::Text::Align->new($img,
				valign => 'top', halign => 'right') or return undef;
			my $ptsz = $size;
			while ($ptsz < $size + 4) {
				last if $gd_text->set_font($font, $ptsz);
				$ptsz++;
			}
			return undef unless ($ptsz < $size+4);
			$fontMap{$size} = $gd_text;
		}
#
#	need to adjust our X based on length
#
		$fontsz = $sfw unless $fontsz;
		$x += (length($val) * ($fontsz>>1));
		$rc = $fontMap{$size}->set( color => $obj->{textColor} );
		$rc = $fontMap{$size}->set_text( $val );
		$rc = $fontMap{$size}->draw(int($x), int($y), $angle);
		return 1 if $rc;
	}
#
#	it was std font, or didn't work
#
	$font = $gdfontmap{$size};
#
#	if none of the fonts provided exists, then use defaults
#
	$img->string($font,$x,$y, $val, $obj->{textColor}),
	return 1
		unless $angle;
	
	$img->stringUp($font,$x,$y, $val, $obj->{textColor});
	return 1
}	

1;
}

__END__

=head1 NAME

DBD::Chart::Plot - Graph/chart Plotting engine for DBD::Chart

=head1 SYNOPSIS

    use DBD::Chart::Plot;

    my $img = DBD::Chart::Plot->new();
    my $anotherImg = DBD::Chart::Plot->new($image_width, $image_height);

    $img->setPoints(\@xdataset, \@ydataset, 'blue line nopoints');

    $img->setOptions (
        horizMargin => 75,
        vertMargin => 100,
        title => 'My Graph Title',
        xAxisLabel => 'my X label',
        yAxisLabel => 'my Y label' );

    print $img->plot;

=head1 DESCRIPTION

B<DBD::Chart::Plot> creates images of various types of graphs for
2 or 3 dimensional data. Unlike GD::Graph, the input data sets
do not need to be uniformly distributed in the domain (X-axis),
and may be either numeric, temporal, or symbolic.

B<DBD::Chart::Plot> supports the following:

=over 4

=item - multiple data set plots

=item - line graphs, areagraphs, scatter graphs, linegraphs w/ points,
	candlestick graphs, barcharts (2-D, 3-D, and 3-axis), histograms,
	piecharts, box & whisker charts (aka boxcharts), and Gantt charts

=item - optional iconic barcharts or datapoints

=item - a wide selection of colors, and point shapes

=item - optional horizontal and/or vertical gridlines

=item - optional legend

=item - auto-sizing of axes based in input dataset ranges

=item - optional symbolic and temproal (i.e., non-numeric) domain values

=item - automatic sorting of numeric and temporal input datasets to assure
	proper order of plotting

=item - optional X, Y, and Z axis labels

=item - optional X and/or Y logarithmic scaling

=item - optional title

=item - optional adjustment of horizontal and vertical margins

=item - optional HTML or Perl imagemap generation

=item - composite images from multiple graphs

=item - user programmable colors

=back

=head1 PREREQUISITES

=over 4

=item B<GD.pm> module minimum version 1.26 (available on B<CPAN>)

GD.pm requires additional libraries:

=item libgd

=item libpng

=item zlib

=head1 USAGE

=head2 Create an image object: new()

    use DBD::Chart::Plot;

    my $img = DBD::Chart::Plot->new;
    my $img = DBD::Chart::Plot->new ( $image_width, $image_height );
    my $img = DBD::Chart::Plot->new ( $image_width, $image_height, \%colormap );
    my $anotherImg = new DBD::Chart::Plot;

Creates an empty image. If image size is not specified,
the default is 400 x 300 pixels.

=head2 Graph-wide options: setOptions()


    $img->setOptions (_title => 'My Graph Title',
        xAxisLabel => 'my X label',
        yAxisLabel => 'my Y label',
        xLog => 0,
        yLog => 0,
        horizMargin => $numHorPixels,
        vertMargin => $numvertPixels,
        horizGrid => 1,
        vertGrid => 1,
        showValues => 1,
        legend => \@plotnames,
        genMap => 'a_valid_HTML_anchor_name',
        mapURL => 'http://some.website.com/cgi-bin/cgi.pl',
        icon => [ 'redstar.png', 'bluestar.png' ]
        symDomain => 0
     );

As many (or few) of the options may be specified as desired.

=item width, height

The width and height of the image in pixels. Default is 400 and 300,
respectively.

=item genMap, mapType, mapURL, mapScript

Control generation of imagemaps. When genMap is set to a legal HTML
anchor name, an image map of the specified type is created for the image.
The default type is 'HTML' if no mapType is specified. Legal types are
'HTML' and 'PERL'.

If mapType is 'PERL', then Perl script compatible text is generated
representing an array ref of hashrefs containing the following
attributes:

plotnum => the plot number to which this hashref applies (to support
multi-range graphs), starting at zero.

x => the domain value for the plot element

y => the range value for the plot element

z => the Z axis value for 3-axis bar charts, if any

shape => the shape of the hotspot area of the plot element, same
as for HTML: 'RECT', 'CIRCLE', 'POLY'

coordinates => an arrayref of the (x,y) pixel coordinates of the hotspot
area to be mapped; for CIRCLE shape, its (x-center, y-center, radius),
for RECT, its (upper-left corner x, upper-left corner y,
lower-right corner x, lower-right corner y), and for POLY its the
set of vertices (x,y)'s.

If the mapType is 'HTML', then either the mapURL or mapScript (or both)
can be specified. mapURL specifies a legal URL string, e.g.,
'http://www.mysite.com/cgi-bin/plotproc.pl?plotnum=:PLOTNUM&X=:X&Y=:Y',
which will be added to the AREA tags generated for each mapped plot element.
mapScript specifies any legal HTML scripting tag, e.g.,
'ONCLICK="alert('Got X=:X, Y=:Y')"' to be added to each generated AREA tag.

For both mapURL and mapScript, special variables :PLOTNUM, :X, :Y, :Z
can be specified which are replaced by the following values when the
imagemap is generated.

Refer to the IMAGEMAP description at www.presicient.com/dbdchart#imagemap
for details.

=item horizMargin, vertMargin

Sets the number of pixels around the actual plot area.

=item xAxisLabel, yAxisLabel, zAxisLabel

Sets the label strings for each axis.

=item xLog, yLog

When set to a non-zero value, causes the associated axis to be
rendered in log10 format. Z axis plots are currently only
symbolic, so no zLog is supported.

=item title

Sets a title string to be rendered at the bottom center of the image
in bold text.

=item signature

Sets a string to be rendered in tiny font at the lower right corner of the
image, e.g., 'Copyright(C) 2001, Presicient Corp.'.

=item legend

Set to an array ref of domain names to be displayed in a legend
for the various plots.
The legend is displayed below the chart, left justified and placed
above the chart title string.
The legend for each plot is
printed in the same color as the plot. If a point shape or icon has been specified
for a plot, then the point shape is printed with the label; otherwise, a small
line segment is printed with the label. Due to space limitations,
the number of datasets plotted should be limited to 8 or less.

=item showValues

When set to a non-zero value, causes the data points for each
plotted element to be displayed next to hte plot point.

=item horizGrid, vertGrid

Causes grid lines to be drawn completely across the plot area.

=item xAxisVert

When set to a non-zero value, causes the X axis tick labels to be rendered
vertically.

=item keepOrigin

When set to a non-zero value, forces the (0,0) data point into the
graph. Normally, DBD::Chart::Plot will heuristically clip away from the
origin is the plot never crosses the origin.

=item bgColor

Sets the background color of the image. Default is white.

=item threed

When set to a non-zero value for barcharts, causes the bars to be
rendered in a 3-D effect.

=item icons

Set to an arrayref of image filenames. The images will be used
to plot iconic barcharts or individual plot points, if the
'icon' shape is specified in the property string supplied
to the setPoints() function (defined below). The array must
match 1-to-1 with the number of plots in the image; icons
and predefined point shapes can be mixed in the same image
by setting the icon arrayref entry to undef for plots using
predefined shapes in the properties string.

=item symDomain

When set to a non-zero value, causes the domain to be treated
as discrete symbolic values which are evenly distributed over
the X-axis. Numeric domains are plotted as scaled values
in the image.

=item timeDomain

When set to a valid format string, the domain data points
are treated as associated temporal values (e.g., date,  time,
timestamp, interval). The values supplied by setPoints will
be strings of the specified format (e.g., 'YYYY-MM-DD'), but
will be converted to numeric time values for purposes of
plotting, so the domain is treated as continuous numeric
data, rather than discrete symbolic. Note that for barcharts,
histograms, candlesticks, or piecharts, temporal domains are
treated as symbolic for plotting purposes, but are sorted
as numeric values.

=item timeRange

When set to a valid format string, the range data points
are treated as associated temporal values (e.g., date,  time,
timestamp, interval). The values supplied by setPoints will
be strings of the specified format (e.g., 'YYYY-MM-DD'), but
will be converted to numeric time values for purposes of
plotting, so the range is treated as continuous numeric
data.

=item gridColor

Sets the color of the axis lines and ticks. Default is black.

=item textColor

Sets the color used to render text in the image. Default is black.

=item font - NOT YET SUPPORTED

Sets the font used to render text in the image. Default is
default GD fonts (gdMedium, gdSmall, etc.).

=item logo

Specifies the name of an image file to be drawn into the
background of the image. The logo image is centered in the
plot image, and will be clipped if the logo size exceeds
the defined width or height of the plot image.

By default, the graph will be centered within the image, with 50
pixel margin around the graph border. You can obtain more space for
titles or labels by increasing the image size or increasing the
margin values.


=head2 Establish data points: setPoints()

    $img->setPoints(\@xdata, \@ydata);
    $img->setPoints(\@xdata, \@ydata, 'blue line');
    $img->setPoints(\@xdata, \@ymindata, \@ymaxdata, 'blue points');
    $img->setPoints(\@xdata, \@ydata, \@zdata, 'blue bar zaxis');

Copies the input array values for later plotting.
May be called repeatedly to establish multiple plots in a single graph.
Returns a positive integer on success and C<undef> on failure.
The global graph properties should be set (via setOptions())
prior to setting the data points.
The error() method can be used to retrieve an error message.
X-axis values may be non-numeric, in which case the set of domain values
is uniformly distributed along the X-axis. Numeric X-axis data will be
properly scaled, including logarithmic scaling is requested.

If two sets of range data (ymindata and ymaxdata in the example above)
are supplied, and the properties string does not specify a 3-axis barchart,
a candlestick graph is rendered, in which case the domain
data is assumed non-numeric and is uniformly distributed, the first range
data array is used as the bottom value, and the second range data array
is used as the top value of each candlestick. Pointshapes may be specified,
in which case the top and bottom of each stick will be capped with the
specified pointshape. The range and/or domain axis may be logarithmically scaled.
If value display is requested, the range value of both the top and bottom
of each stick will be printed above and below the stick, respectively.

B<Plot properties:> Properties of each dataset plot can be set
with an optional string as the third argument. Properties are separated
by spaces. The following properties may be set on a per-plot basis
(defaults in capitals):

    COLOR     CHARTSTYLE  USE POINTS?   POINTSHAPE
    -----     ---------  -----------   ----------
	BLACK       LINE        POINTS     FILLCIRCLE
	white      noline      nopoints    opencircle
	lgray       fill                   fillsquare
	gray        bar                    opensquare
	dgray       pie                    filldiamond
	lblue       box                    opendiamond
	blue       zaxis                   horizcross
	dblue      histo                   diagcross
	gold                               icon
	lyellow	                           dot
	yellow
	dyellow
	lgreen
	green
	dgreen
	lred
	red
	dred
	lpurple
	purple
	dpurple
	lorange
	orange
	pink
	dpink
	marine
	cyan
	lbrown
	dbrown

E.g., if you want a red scatter plot (red dots
but no lines) with filled diamonds, you could specify

    $p->setPoints (\@xdata, \@ydata, 'Points Noline Red filldiamond');

Specifying icon for the pointshape requires setting the
icon object attribute to a list of compatible image filenames
(as an arrayref, see below). In that case, the icon images
are displayed centered on the associated plotpoints. For 2-D
barcharts, a stack of the icon is used to display the bars,
including a proportionally clipped icon image to cap the bar
if needed.


=head2 Draw the image: plot()

     $img->plot();

Draws the image and returns it as a string.
To save the image to a file:

    open (WR,'>plot.png') or die ("Failed to write file: $!");
    binmode WR;            # for DOSish platforms
    print WR $img->plot();
    close WR;

To return the graph to a browser via HTTP:

    print "Content-type: image/png\n\n";
    print  $img->plot();

The range of values on each axis is automatically
computed to optimize the data placement in the largest possible
area of the image. As a result, the origin (0, 0) axes
may be omitted if none of the datasets cross them at any point.
Instead, the axes will be drawn on the left and bottom borders
using the value ranges that appropriately fit the dataset(s).

=head2 Fetch the imagemap: getMap()

     $img->getMap();

Returns the imagemap for the chart.
If no mapType was set, or if mapType was set to HTML.
the returned value is a valid <MAP...><AREA...></MAP> HTML string.
If mapType was set to 'Perl', a Perl-compatible arrayref
declaration string is returned.

The resulting imagemap will be applied as follows:

=item 2 axis 2-D Barcharts and Histograms

Each bar is mapped individually.

=item Piecharts

Each wedge is mapped. The CGI parameter values are used slightly
differently than described above:

X=<wedge-label>&Y=<wedge-value>&Z=<wedge-percent>

=item 3-D Barcharts (either 2 or 3 axis)

The top face of each bar is mapped. The Z CGI parameter will be
empty for 2 axis barcharts.

=item 3-D Histograms (either 2 or 3 axis)

The right face of each bar is mapped. The Z CGI parameter will be
empty for 2 axis barcharts.

=item Line, point, area graphs

A 4 pixel diameter circle around each datapoint is mapped.

=item Candlestick graphs

A 4 pixel diameter circle around both the top and bottom datapoints
of each stick are mapped.


=item Boxcharts

The area of the box is mapped, and 4-pixel diameter circles
are mapped at the end of each extreme whisker.


=item Gantt Charts

The area of each bar in the chart is mapped.


=head1 TO DO

=item programmable fonts

=item symbolic ranges for scatter graphs

=item axis labels for 3-D charts

=item surfacemaps

=item SVG support

=head1 AUTHOR

Copyright (c) 2001 by Presicient Corporation. (darnold@presicient.com)

You may distribute this module under the terms of the Artistic License,
as specified in the Perl README file.

=head1 SEE ALSO

GD, DBD::Chart. (All available on CPAN).
