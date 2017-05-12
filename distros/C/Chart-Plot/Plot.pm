#=====================================================================#
# Chart::Plot -- Front end to GD.pm for plotting two dimensional data #
#                by Sanford Morton <smorton@pobox.com>                #
#=====================================================================#

# Changes:
#   v 0.0 - 08 March 1998 
#           first version
#   v 0.01 - 09 March 1998; 
#            - _getOM reports >= max instead of >;
#            - fixed bug in setData() data check
#   v 0.02 - 10 March 1998; 
#            - changed error handling in setData() (public method) which
#            now returns undef on success and sets $self->error ;
#            - changed legend to title (public method)
#            - adjusted horizontal tick labels up a bit
#   v 0.03 - 15 March 1998
#            - added colors and dashed line options to dataset graph style
#            - added option to pass dataset as two arrays (@xdata, @ydata)
#            - added hack for case om == max
#   v 0.04 - 15 March 1998
#            - added general purpose setGraphOptions()
#   v 0.05 - 18 March 1998
#            _ added synopsis to pod
#            - added getBounds()
#            - Hor axis label is set below and right centered or justified.
#            - additional vertical offset if title is present; larger font
#   v 0.06 - 22 March 1998
#            - removed title, offset and axis label methods in favor of
#              setGraphOptions()
#            - added getBounds()
#   v 0.07 - 29 May 1998
#            - finally put into standard h2xs form
#            - added check for tick step too small
#            - changed data validity check to permit scientific notation
#              but this invites awful looking tick labels
#   v 0.08 - 15 Dec 1998
#            - added access to GD object: getGDobject() and data2pxl() 
#   v 0.09 - 26 July 1999
#            - added custom tick labels: xTickLabels, yTickLabels
#            - added binmode() to install test and demo script
#   v 0.10 - 22 May 2000
#            - added @_image_types and image_type() to use gif, jpeg or png
#              according to local version of GD; modified draw() and _init()
#   v 0.11 - 04 April 2001
#            - fixed bug in draw() to enable jpeg's

package Chart::Plot;

$Chart::Plot::VERSION = '0.11'; 

use GD;
use strict;


#==================#
#  class variables #
#==================#

# list of image types supported by GD, currently jpeg, png or gif, 
# depending on GD version; initialized in _init()
my @_image_types = ();



#==================#
#  public methods  #
#==================#

# usage: $plot = new Chart::Plot(); # default 400 by 300 pixels or 
#        $plot = new Chart::Plot(640, 480); 
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init (@_);

    return $self;
}

sub setData {
  my $self = shift;
  my ($arrayref1, $arrayref2, $style) = @_;
  my ($arrayref, $i);

  if (ref $arrayref2) { # passing data as two data arrays (x0 ...) (y0 ...)

    unless ($#$arrayref1 = $#$arrayref2) { # error checking
      $self->{'_errorMessage'} = "The dataset does not contain an equal number of x and y values.";
      return 0;
    }

    # check whether data are numeric
    # and construct a single flat array
    for ($i=0; $i<=$#$arrayref1; $i++) {

      if ($$arrayref1[$i] !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	# if ($$arrayref1[$i] =~ /[^\d\.-]/) {
	$self->{'_errorMessage'} = "The data element $$arrayref1[$i] is non-numeric.";
	return 0;
      }
      if ($$arrayref2[$i] !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	# if ($$arrayref2[$i] =~ /[^\d\.-]/) {
	$self->{'_errorMessage'} = "The data element $$arrayref2[$i] is non-numeric.";
	return 0;
      }

      # construct a flat array
      $$arrayref[2*$i] = $$arrayref1[$i];
      $$arrayref[2*$i+1] = $$arrayref2[$i];
    }

  } else { # passing data as a single flat data array (x0 y0 ...)

    $arrayref = $arrayref1;
    $style = $arrayref2;

    # check whether array is unbalanced
    if ($#$arrayref % 2 == 0) {
      $self->{'_errorMessage'} = "The dataset does not contain an equal number of x and y values.";
      return 0;
    }

    # check whether data are numeric
    for ($i=0; $i<=$#$arrayref; $i++) {
      if ($$arrayref[$i] !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	# if ($$arrayref1[$i] =~ /[^\d\.-]/) {
	$self->{'_errorMessage'} = "The data element $$arrayref[$i] is non-numeric.";
	return 0;
      }
    }
  }

  # record the dataset
  my $label = ++$self->{'_numDataSets'};
  $self->{'_data'}->{$label} = $arrayref;
  $self->{'_dataStyle'}->{$label} = ($style ? $style : 'linespoints');

  $self->{'_validMinMax'} = 0; # invalidate any prior min-max calculations
  return $label;
}

sub error {
  my $self = shift;
  return $self->{'_errorMessage'};
}

sub setGraphOptions {
  my $self = shift;
  my %hash = @_;

  for (keys (%hash)) {
    $self->{"_$_"} = $hash{$_};

    # check tick labels for non-numeric positions
    if (/^(x|y)TickLabels$/) {
      my $xory = $1;
      foreach ( keys %{$hash{$_}} ) {
	unless (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	  $self->{'_errorMessage'} = 
	    "The $xory axis tick label position $_ is non-numeric.";
	  return 0;
	}
      }
    }
  }
  return 1;
}

sub getBounds {
  my $self = shift;
  $self->_getMinMax() unless $self->{'_validMinMax'};

  return ($self->{'_xmin'}, $self->{'_ymin'},
	  $self->{'_xmax'}, $self->{'_ymax'});
}

sub image_type {
  return (wantarray ? @_image_types : $_image_types[0]);
}

sub draw {
  my $self = shift;


  # draw stuff in the GD object
  $self->_getMinMax() unless $self->{'_validMinMax'};
  $self->_drawTitle() if $self->{'_title'}; # vert offset may be increased
  $self->_drawAxes();
  $self->_drawData();

  # construct the image and return it.
  # $_image_types[0] is the supported GD format, gif or png or jpeg
  # Damien says no good way around this temp variable
  if ($_[0]) { # image type argument
    unless ( $self->{'_im'}->can($_[0]) ) {
      $self->{'_errorMessage'} = "The image format $_[0] is not supported by this version $GD::VERSION of GD";
      return undef;
    }

    $_ = $_[0];                       # forgot these in ver 0.10 
    return $self->{'_im'}->$_();      # an embarrassment

  } else {
    $_ = $_image_types[0];
    return $self->{'_im'}->$_();
  }
}

sub getGDobject {
  my $self = shift;

  if (wantarray) {
    return ( $self->{'_im'}, 
             $self->{'_black'}, $self->{'_white'},
	     $self->{'_red'}, $self->{'_green'}, $self->{'_blue'},
           );
  } else {
    return $self->{'_im'};
  }
}

sub data2pxl {
  my $self = shift;
  my @data = @_;

  # calculate required translation parameters
  $self->_getMinMax() unless $self->{'_validMinMax'};

  return $self->_data2pxl (@data);
}


#===================#
#  private methods  #
#===================#

# initialization
# this contains a record of all private data except class variables, up top
sub _init {
  my $self = shift;

  #  create an image object
  if ($#_ == 1) {
    $self->{'_im'} = new GD::Image($_[0], $_[1]);
    $self->{'_imx'} = $_[0];
    $self->{'_imy'} = $_[1];
  }
  else {
    $self->{'_im'} = new GD::Image(400,300);
    $self->{'_imx'} = 400;
    $self->{'_imy'} = 300;
  }

  # find format(s) supported by GD
  unless (@_image_types) {
    for ( qw(png gif jpeg) ) {
      push @_image_types, $_ if $self->{'_im'}->can($_);
    }
  }

  # set graph offset; graph will be centered this many pixels within  image
  $self->{'_horGraphOffset'} = 50;
  $self->{'_vertGraphOffset'} = 50;

  # create an empty hash for the datsets
  # data sets and their styles are hashes whose keys are 1 ... _numDataSets
  # and values are refs to flat data arrays or style strings, respectively
  $self->{'_data'} = {};
  $self->{'_dataStyle'} = {};
  $self->{'_numDataSets'} = 0;

  # calculated by _getMinMax and used in translating _data2pxl()
  $self->{'_xmin'} = 0;    $self->{'_xmax'} = 0; # among all datasets
  $self->{'_ymin'} = 0;    $self->{'_ymax'} = 0;
  $self->{'_xslope'} = 0;  $self->{'_yslope'} = 0; # for _data2pxl()
  $self->{'_ax'} = 0;      $self->{'_ay'} = 0;
  $self->{"_omx"} = 0;     $self->{"_omy"} = 0; # for axis ticks
  $self->{'_validMinMax'} = 0; # last calculated min and max still valid

  # initialize text 
  ($self->{'_horAxisLabel'}, $self->{'_vertAxisLabel'}) = ('','');
  $self->{'_title'} = '';
  $self->{'_errorMessage'} = '';

  # initialize custom tick labels
  ($self->{'_xTickLabels'}, $self->{'_yTickLabels'}) = (0,0);

  #  allocate some colors
  $self->{'_white'} = $self->{'_im'}->colorAllocate(255,255,255);
  $self->{'_black'} = $self->{'_im'}->colorAllocate(0,0,0);
  $self->{'_red'} = $self->{'_im'}->colorAllocate(255,0,0);
  $self->{'_blue'} = $self->{'_im'}->colorAllocate(0,0,255);
  $self->{'_green'} = $self->{'_im'}->colorAllocate(0,255,0);

  # make the background transparent and interlaced
  $self->{'_im'}->transparent($self->{'_white'});
  $self->{'_im'}->interlaced('true');

  # Put a black frame around the picture
  $self->{'_im'}->rectangle( 0, 0,
			     $self->{'_imx'}-1, $self->{'_imy'}-1,
			     $self->{'_black'});

  # undocumented: in script, use as $plotObject->{'_debugging'} = 1;
  $self->{'_debugging'} = 0;
}


# sets min and max values of all data (_xmin, _ymin, _xmax, _ymax);
# also sets _xslope, _yslope, _ax and _ay used in _data2pxl;
# usage: $self->_getMinMax
sub _getMinMax {
  my $self = shift;
  my ($i, $arrayref);
  my ($xmin, $ymin, $xmax, $ymax);

  # if no data, set arbitrary bounds
  ($xmin, $ymin, $xmax, $ymax) = (0,0,1,1) unless keys %{$self->{'_data'}} > 0;

  # initialize to zero
  $xmin = $xmax = $ymin = $ymax = 0;
  # # or to first data point of an arbitrary dataset
  # foreach (keys %{$self->{'_data'}}) {
  #   $arrayref = $self->{'_data'}->{$_};
  #   $xmin = $xmax = ($self->{'_noZeroX'} ? $$arrayref[0] : 0);
  #   $ymin = $ymax = ($self->{'_noZeroY'} ? $$arrayref[1] : 0);
  #   last; # skip any other datasets
  # }

  # cycle through the datasets looking for min and max values
  foreach (keys %{$self->{'_data'}}) {

    $arrayref = $self->{'_data'}->{$_};

    for ($i=0; $i<$#{$arrayref}; $i++) {
      $xmin = ($xmin > $$arrayref[$i] ? $$arrayref[$i] : $xmin);
      $xmax = ($xmax < $$arrayref[$i] ? $$arrayref[$i] : $xmax);
      $i++;
      $ymin = ($ymin > $$arrayref[$i] ? $$arrayref[$i] : $ymin);
      $ymax = ($ymax < $$arrayref[$i] ? $$arrayref[$i] : $ymax);
    }
  }

  # set axes data ranges as decimal order of magnitude of widest dataset
  ($self->{'_xmin'}, $self->{'_xmax'}) = $self->_getOM ('x', $xmin,$xmax);
  ($self->{'_ymin'}, $self->{'_ymax'}) = $self->_getOM ('y', $ymin,$ymax);

  # calculate conversion constants for _data2pxl()
  $self->{'_xslope'} = ($self->{'_imx'} - 2 * $self->{'_horGraphOffset'})
    / ($self->{'_xmax'} - $self->{'_xmin'});
  $self->{'_yslope'} = ($self->{'_imy'} - 2 * $self->{'_vertGraphOffset'})
    / ($self->{'_ymax'} - $self->{'_ymin'});

  $self->{'_ax'} = $self->{'_horGraphOffset'};
  $self->{'_ay'} = $self->{'_imy'} - $self->{'_vertGraphOffset'};

  $self->{'_validMinMax'} = 1;

  print STDERR 
    "_getMinMax(): ($self->{'_omx'}, $self->{'_omy'}) "
      . "($xmin,$xmax) ($ymin,$ymax) "
	. "($self->{'_xmin'}, $self->{'_xmax'}) "
	  . "($self->{'_ymin'}, $self->{'_ymax'})\n"
	    if $self->{'_debugging'};
}


# returns order of magnitude (with decimal) greater than +/- min and max
# sets _omx or _omy used for translating _data2pxl
# usage: ($min, $max) = $self->_getOM ('x', $xmin, $xmax);  # or ('y', $ymin, $ymax)
sub _getOM {
  my $self = shift;
  my $xory = shift;
  my @nums = @_;
  my ($tmp, $om) = (0,0);
  my @sign = ();

  if ($nums[0] == 0 && $nums[1] == 0) {
    $self->{"_om$xory"} = 1;
    return (0,1);
  }
  # find the (exponential) order of magnitude eg, 1000
  foreach (@nums) {
    if ($_<0) {
      push @sign, ('-1');
      $_ = - $_;
    } elsif ($_ == 0) {
      push @sign, ('0');
      next;
    } else {
      push @sign, ('1');
    }

    $tmp = 10 ** (int (log($_) / log(10))); # 1, 10, 100, ... less than $_
    $om = ( $tmp>$om ? $tmp : $om );
  }
  $self->{"_om$xory"} = $om;

  # return the decimal order of magnitude eg, 7000
  # epsilon adjustment in case om equals min or max
  return (0,0) if $om == 0; # to prevent divide by zero 
  return ( $om * (int(($_[0]-0.00001*$sign[0])/$om) + $sign[0]),
	   $om * (int(($_[1]-0.00001*$sign[1])/$om) + $sign[1])
	 );
}



# draws all the datasets in $self->{'_data'}
# usage: $self->_drawData()
sub _drawData {
  my $self = shift;
  my ($i, $num, $px, $py, $prevpx, $prevpy, $dataSetLabel, $color);

  foreach $dataSetLabel (keys %{$self->{'_data'}}) {

    # get color
    if ( $self->{'_dataStyle'}->{$dataSetLabel} =~ /((red)|(blue)|(green))/i ) {
      $color = "_$1";
      $color =~ tr/A-Z/a-z/;
    } else {
      $color = '_black';
    }

    # draw the first point 
    ($px, $py) = $self->_data2pxl (
			     $self->{'_data'}->{$dataSetLabel} [0],
			     $self->{'_data'}->{$dataSetLabel} [1]
			    ); 
    $self->{'_im'}->arc($px, $py,4,4,0,360,$self->{$color})
      unless $self->{'_dataStyle'}->{$dataSetLabel} =~ /nopoint/i;

    ($prevpx, $prevpy) = ($px, $py);

    # debugging
    if ($self->{'_debugging'}) {
      $self->{'_im'}->string(gdSmallFont,$px,$py-10,
			     "0($px,$py)",$self->{$color});
      print STDERR "pxldata: 0 ($px, $py)";
    }

    # draw the rest of the points and lines 
    $num = @{ $self->{'_data'}->{$dataSetLabel} };
    for ($i=2; $i<$num; $i+=2) {

      # get next point
      ($px, $py) = $self->_data2pxl (
				     $self->{'_data'}->{$dataSetLabel}[$i],
				     $self->{'_data'}->{$dataSetLabel}[$i+1]
				    );

      # draw point, maybe
      $self->{'_im'}->arc($px, $py,4,4,0,360,$self->{$color})
	unless $self->{'_dataStyle'}->{$dataSetLabel} =~ /nopoint/i;

      # draw line from previous point, maybe
      if ($self->{'_dataStyle'}->{$dataSetLabel} =~ /dashed/) {
	$self->{'_im'}->dashedLine($prevpx, $prevpy, $px, $py, $self->{$color});
      } elsif ($self->{'_dataStyle'}->{$dataSetLabel} =~ /noline/i) {
	next;
      } else { # default to solid line
	$self->{'_im'}->line($prevpx, $prevpy, $px, $py, $self->{$color});
      }

      ($prevpx, $prevpy) = ($px, $py);

      # debugging
      if ($self->{'_debugging'}) {
	$self->{'_im'}->string(gdSmallFont,$px-10,$py+10,
			       "$i($px,$py)",$self->{$color});
	print STDERR "$i ($px, $py)";
      }
    }
  }
}



# translate a data point to the nearest pixel point within the graph
# usage: (px,py) = $self->_data2pxl (x,y)
sub _data2pxl {
  my $self = shift;
  my ($x, $y) = @_;

  return ( int ( $self->{'_ax'} 
		 + ($x - $self->{'_xmin'}) * $self->{'_xslope'} ),
	   int ( $self->{'_ay'} 
		 - ($y - $self->{'_ymin'}) * $self->{'_yslope'} )
	 );
}



# draw the axes, axis labels, ticks and tick labels
# usage: $self->_drawAxes
sub _drawAxes {
  # axes run from data points: x -- ($xmin,0) ($xmax,0);
  #                            y -- (0,$ymin) (0,$ymax);
  # these mins and maxes are decimal orders of magnitude bounding the data

  my $self = shift;
  my ($w,$h) = (gdSmallFont->width, gdSmallFont->height);

  ### horizontal axis
  my ($p1x, $p1y) = $self->_data2pxl ($self->{'_xmin'}, 0);
  my ($p2x, $p2y) = $self->_data2pxl ($self->{'_xmax'}, 0);
  $self->{'_im'}->line($p1x, $p1y, $p2x, $p2y, $self->{'_black'});

  ### axis label
  my $len = $w * length ($self->{'_horAxisLabel'});
  my $xStart = ($p2x+$len/2 > $self->{'_imx'}-10) # center under right end of axis 
    ? ($self->{'_imx'}-10-$len) : ($p2x-$len/2);  #   or right justify
  $self->{'_im'}->string (gdSmallFont, $xStart, $p2y+3*$h/2,
			  $self->{'_horAxisLabel'},
			  $self->{'_black'});

  print STDERR "\nHor: p1 ($p1x, $p1y) p2 ($p2x, $p2y)\n" 
    if $self->{'_debugging'};

  ### vertical axis
  ($p1x, $p1y) = $self->_data2pxl (0, $self->{'_ymin'});
  ($p2x, $p2y) = $self->_data2pxl (0, $self->{'_ymax'});
  $self->{'_im'}->line($p1x, $p1y, $p2x, $p2y, $self->{'_black'});

  ### axis label
  $xStart = $p2x - length ($self->{'_vertAxisLabel'}) * $w / 2;
  $self->{'_im'}->string (gdSmallFont, ($xStart>10 ? $xStart : 10), $p2y - 2*$h,
			  $self->{'_vertAxisLabel'},
			  $self->{'_black'});
  
  print STDERR "Ver: p1 ($p1x, $p1y) p2 ($p2x, $p2y)\n" 
    if $self->{'_debugging'};

  ###
  ### draw axis ticks and tick labels
  ### 
  my ($i,$px,$py, $step);
  

  ### 
  ### horizontal
  ###
  # if horizontal custom tick labels
  if ($self->{'_xTickLabels'}) {
    
    # a hashref with horizontal data point and label
    # example: %{$self->{'_xTickLabels'} = (10 => 'Ten', 20 => 'Twenty', ...)
    foreach ( keys %{$self->{'_xTickLabels'}} ) {
      
      ($px,$py) = $self->_data2pxl($_, 0);
      $self->{'_im'}->line($px, $py-2, $px, $py+2, $self->{'_black'});
      $self->{'_im'}->string ( gdSmallFont,  
			       $px-length( ${$self-> {'_xTickLabels'}}{$_} ) * $w/2,   
                               $py+$h/2,   
                               ${$self->{'_xTickLabels'}}{$_},  
                               $self->{'_black'}
     ); 
    } 
    
  } else {

    # horizontal step calculation
    $step = $self->{'_omx'}; 
    # step too large
    $step /= 2  if ($self->{'_xmax'} - $self->{'_xmin'}) / $step < 6;
    # once again. A poor hack for case  om = max.
    $step /= 2  if ($self->{'_xmax'} - $self->{'_xmin'}) / $step < 6;
    # step too small. As long as we are doing poor hacks
    $step *= 2  if ($self->{'_xmax'} - $self->{'_xmin'}) / $step > 12;
    
    for ($i=$self->{'_xmin'}; $i <= $self->{'_xmax'}; $i+=$step ) {
      ($px,$py) = $self->_data2pxl($i, 0);
      $self->{'_im'}->line($px, $py-2, $px, $py+2, $self->{'_black'});
      $self->{'_im'}->string (gdSmallFont, 
			      $px-length($i)*$w/2, $py+$h/2, 
			      $i, $self->{'_black'}) unless $i == 0;
    }
    print STDERR "Horstep: $step ($self->{'_xmax'} - $self->{'_xmin'})/$self->{'_omx'})\n"
      if $self->{'_debugging'};
  }

  ###
  ### vertical
  ###
  if ($self->{'_yTickLabels'}) {
    foreach ( keys %{$self->{'_yTickLabels'}} ) {
      ($px,$py) = $self->_data2pxl(0, $_);
      $self->{'_im'}->line($px-2, $py, $px+2, $py, $self->{'_black'});
      $self->{'_im'}->string ( gdSmallFont,  
			       $px-(1+length( ${$self->{'_yTickLabels'}}{$_} )) * $h/2,
                               $py-$h/2,   
                               ${$self->{'_yTickLabels'}}{$_},  
                               $self->{'_black'}); 
    }
  } else {
    $step = $self->{'_omy'};
    $step /= 2  if ($self->{'_ymax'} - $self->{'_ymin'}) / $step < 6;
    $step /= 2  if ($self->{'_ymax'} - $self->{'_ymin'}) / $step < 6; 
    $step *= 2  if ($self->{'_ymax'} - $self->{'_ymin'}) / $step > 12;

    for ($i=$self->{'_ymin'}; $i <= $self->{'_ymax'}; $i+=$step ) {
      ($px,$py) = $self->_data2pxl (0, $i);
      $self->{'_im'}->line($px-2, $py, $px+2, $py, $self->{'_black'});
      $self->{'_im'}->string (gdSmallFont, 
			      $px-5-length($i)*$w, $py-$h/2, 
			      $i, $self->{'_black'}) unless $i == 0;
    }
    print STDERR "Verstep: $step ($self->{'_ymax'} - $self->{'_ymin'})/$self->{'_omy'})\n"
      if $self->{'_debugging'};
  }
}


sub _drawTitle {
  my $self = shift;
  my ($w,$h) = (gdMediumBoldFont->width, gdMediumBoldFont->height);

  # increase vert offset and recalculate conversion constants for _data2pxl()
  $self->{'_vertGraphOffset'} += 2*$h;

  $self->{'_xslope'} = ($self->{'_imx'} - 2 * $self->{'_horGraphOffset'}) 
    / ($self->{'_xmax'} - $self->{'_xmin'});
  $self->{'_yslope'} = ($self->{'_imy'} - 2 * $self->{'_vertGraphOffset'}) 
    / ($self->{'_ymax'} - $self->{'_ymin'});

  $self->{'_ax'} = $self->{'_horGraphOffset'};
  $self->{'_ay'} = $self->{'_imy'} - $self->{'_vertGraphOffset'};


  # centered below chart
  my ($px,$py) = ($self->{'_imx'}/2, # $self->{'_vertGraphOffset'}/2);
		  $self->{'_imy'} - $self->{'_vertGraphOffset'}/2);

  ($px,$py) = ($px - length ($self->{'_title'}) * $w/2, $py+$h/2);
  $self->{'_im'}->string (gdMediumBoldFont, $px, $py,
			  $self->{'_title'},
			  $self->{'_black'}); 
}

1;

__END__


=head1 NAME

Chart::Plot - Plot two dimensional data in an image. Version 0.10.

=head1 SYNOPSIS

    use Chart::Plot; 
    
    my $img = Chart::Plot->new(); 
    my $anotherImg = Chart::Plot->new ($image_width, $image_height); 
    
    $img->setData (\@dataset) or die( $img->error() );
    $img->setData (\@xdataset, \@ydataset);
    $img->setData (\@anotherdataset, 'red_dashedline_points'); 
    $img->setData (\@xanotherdataset, \@yanotherdataset, 
                   'Blue SolidLine NoPoints');
    
    my ($xmin, $ymin, $xmax, $ymax) = $img->getBounds();
    
    $img->setGraphOptions ('horGraphOffset' => 75,
    			    'vertGraphOffset' => 100,
    			    'title' => 'My Graph Title',
    			    'horAxisLabel' => 'my X label',
    			    'vertAxisLabel' => 'my Y label' );
    
    print $img->draw();

=head1 DESCRIPTION

I wrote B<Chart::Plot> to create images of some simple graphs
of two dimensional data. The other graphing interface modules to GD.pm
I saw on CPAN either could not handle negative data, or could only
chart evenly spaced horizontal data. (If you have evenly spaced or
nonmetric horizontal data and you want a bar or pie chart, I have
successfully used the GIFgraph and Chart::* modules, available on
CPAN.)

B<Chart::Plot> will plot multiple data sets in the same graph, each
with some negative or positive values in the independent or dependent
variables. Each dataset can be a scatter graph (data are represented
by graph points only) or with lines connecting successive data points,
or both. Colors and dashed lines are supported, as is scientific
notation (1.7E10). Axes are scaled and positioned automatically
and 5-10 ticks are drawn and labeled on each axis.

You must have already installed the B<GD.pm> library by Lincoln Stein,
available on B<CPAN> or at http://stein.cshl.org/WWW/software/GD/
Versions of GD below 1.19 supported only gif image format. Versions
between 1.20 and 1.26 support only png format. GD version 1.27
supports either png or jpg image formats. Chart::Plot will draw
whichever format your version of GD will draw. (See below for a method
to determine which format your version supports.)


=head1 USAGE

=head2 Create an image object: new()

    use Chart::Plot; 

    my $img = Chart::Plot->new; 
    my $img = Chart::Plot->new ( $image_width, $image_height ); 
    my $anotherImg = new Chart::Plot; 

Create a new empty image with the new() method. It will be transparent
and interlaced if your version of GD supports gif format.  png does
not yet support either. If image size is not specified, the default is 400
x 300 pixels, or you can specify a different image size. You can also
create more than one image in the same script.

=head2 Acquire a dataset: setData()

    $img->setData (\@data);
    $img->setData (\@xdata, \@ydata);
    $img->setData (\@data, 'red_dashedline_points'); 
    $img->setData (\@xdata, \@ydata, 'blue solidline');

The setData() method reads in a two-dimensional dataset to be plotted
into the image. You can pass the dataset either as one flat array
containing the paired x,y data or as two arrays, one each for the x
and y data.

As a single array, in your script construct a flat array of the
form (x0, y0, ..., xn, yn) containing n+1 x,y data points .  Then plot
the dataset by passing a reference to the data array to the setData()
method. (If you do not know what a reference is, just put a backslash
(\) in front of the name of your data array when you pass it as an
argument to setData().) Like this:

    my @data = qw( -3 9   -2 4   -1 1   0 0   1 1  2 4  3 9);
    $img->setData (\@data);

Or, you may find it more convenient to construct two equal length
arrays, one for the horizontal and one for the corresponding vertical
data. Then pass references to both arrays (horizontal first) to
setData():

    my @xdata = qw( -3  -2  -1  0  1  2  3 );
    my @ydata = qw(  9   4   1  0  1  4  9 );
    $img->setData (\@xdata, \@ydata);

In the current version, if you pass a reference to a single, flat
array to setData(), then only a reference to the data array is stored
internally in the plot object, not a copy of the array. The object
does not modify your data, but you can and the modified data will be
drawn.  On the other hand, if you pass references to two arrays, then
copies of the data are stored internally, and you cannot modify them
from within your script. This inconsistent behavior is probably a
bug, though it might be useful from time to time.

You can also plot multiple datasets in the same graph by calling
C<$img-E<gt>setData()> repeatedly on different datasets.

B<Error checking:> The setData() method returns a postive integer on
success and 0 on failure. If setData() fails, you can recover an error
message about the most recent failure with the error() method. The
error string returned will either be "The data set does not contain an
equal number of x and y values." or "The data element ... is
non-numeric."

    $p->setData (\@data) or die( $p->error() );

In the current version, only numerals, decimal points (apologies to
Europeans), minus signs, and more generally, scientific notation
(+1.7E-10 or -.298e+17) are supported. Commas (,), currencies ($),
time (11:23am) or dates (23/05/98) are not yet supported and will
generate errors. I hope to figure these out sometime in the future.

Be cautious with scientific notation, since the axis tick labels will
probably become unwieldy. Consider rescaling your data by orders of
magnitude or using logarithmic transforms before plotting them. Or
experiment with image size and graph offset.

B<Style options:> You can also specify certain graphing style options
for each dataset by passing an optional final string argument to
setData() with a concatenated list of selections from each of the
following groups:

    BLACK           SOLIDLINE            POINTS    
    red		    dashedline           nopoints  
    green 	    noline         
    blue

The capitalized options in each group are the default for that group.  If
you do not specify any options, you will get black solid lines
connecting successive data points with dots at each data point
('black_solidline_points'). If you want a red scatter plot (red dots
but no lines) you could specify either

    $p->setData (\@data, 'redNOLINE'); 
    $p->setData (\@xdata, \@ydata, 'Points Noline Red');

Options are detected by a simple regexp match, so order does not
matter in the option string, options are not case sensitive and
extraneous characters between options are ignored. There is no harm
in specifying a default. There is also no error checking.


=head2 Obtain current graph boundaries: getBounds()

    my ($xmin, $ymin, $xmax, $ymax) = $img->getBounds;

This method returns the data values of the lower left corner and upper
right corner of the graph, based on the datasets so far set.  If you
have only positive data, then $xmin and $ymin will be 0. The upper
values will typically not be the data maxima, since axis tick ranges
are usually a little beyond the range of the data.  If you add another
dataset, these values may become inaccurate, so you will need to call
the method again. As an example, I use this to draw a least squares
regression line (using Statistics::OLS) through a scatter plot of the
data, running from the edges of the graph rather than from the bounds
of the data.



=head2 Graph-wide options: setGraphOptions()

    $img->setGraphOptions ('title' => 'My Graph Title',
		         'horAxisLabel' => 'my X label',
		         'vertAxisLabel' => 'my Y label' 
			 'horGraphOffset' => $numHorPixels,
	                 'vertGraphOffset' => $numvertPixels);

    my %xTickLabels = qw (1 One o'clock 2 Two o'clock 3 Three o'clock);
    my %yTickLabels = qw (1 Jan 2 Feb 3 Mar);
    $img->setGraphOptions ('xTickLabels' => \%xTickLabels,
                           'yTickLabels' => \%yTickLabels)
       or die ($img->error);

This method and each of its arguments are optional.  You can call it
with one, some or all options, or you can call it repeatedly to set or
change options. This method will also accept a hash.

In the current version, Chart::Plot is a little smarter about
placement of text, but is still not likely to satisfy everyone, If you
are not constructing images on the fly, you might consider leaving
these blank and using a paint program to add text by hand. Or place
descriptive text in a caption outside the image.

Titles and Axis labels are blank, by default. The title will be
centered in the margin space below the graph. A little extra vertical
offset space (the margin between the edges of the graph proper and the
image) is added to allow room. There is no support for multi-line
strings. You can specify empty strings for one or the other of the
axis labels.  The vertical label will be centered or left justified
above the vertical axis; the horizontal label will be placed below the
end of the horizontal axis, centered or right justified.

By default, the graph will be centered within the image, with 50
pixels offset distance from its edges to the edges of the image
(though a title will increase the vertical offset). Axis and tick
labels and the title will appear in this margin (assuming all data are
positive). You can obtain more space for a title or a horizontal label
by increasing the image size (method new() ) and adjusting the
offset. 

B<Custom Tick Labels:> Normally, Chart::Plot will draw five to ten
ticks on each axis and label them with their corresponding data
values. You can override this and supply your own custom tick labels
to either axis in a hash reference, in which the axis position (eg,
the axis data coordinate) is the key and the label at that distance
along the axis is its value.  If a key is not a number, an error
message is set to the effect that a tick label is non-numeric. If you
supply an empty hash reference, all ticks will be suppressed.




=head2 Draw the image: draw() 

     $img->draw();
     $img->draw('jpeg') or die "$img->error()";

This method draws the image and returns it as a string, which you can
print to a file or to STDOUT. (This should be the last method called
from the $img object.)  You will generally need to know which image
format your version of GD supports: if it supports png, then to save
the image in a file:

    open (WR,'>plot.png') or die ("Failed to write file: $!");
    binmode WR;            # for DOSish platforms
    print WR $img->draw();
    close WR;

Or, to return the graph from a cgi script:

    print "Content-type: image/png\n\n";
    print  $img->draw();

Or, to pipe it to a viewing program which accepts STDIN (such as xv on
Unix)

    open (VIEWER,'| /usr/X11R6/bin/xv -') or die ("Failed to open viewer: $!");
    print VIEWER $img->draw();
    close VIEWER;

Of course, if you have a version of GD which supports only gif, change
the file names and types to gif.  GD version 1.19 and below supported
only gif image format. Versions between 1.20 and 1.26 support only png
format.  If you are not sure, or suspect the supported formats may
change in the future, you can use

    $extension = $img->image_type();
    open (WR,">plot.$extension");

to obtain the type, 'png' or 'gif'. Often, you must know the type to
write the correct file extension or to return the correct content type
from a cgi script.

GD version 1.27 supports both png and jpeg image formats. For this
version, C<draw()> will default to 'png' unless you supply 'jpeg' as
the argument.  C<image_type()> will return 'png' in scalar context and
the list of all supported formats C<(png,jpeg)> in array context. 

If the argument to C<draw()> is not a supported image format by the
local version of GD, C<draw()> will return undef and an error message
will be set. C<error()> will return 'The image format ... is not
supported by this version ... of GD.'


=head2 Accessing the GD object directly

Chart::Plot is a front end to GD and creates an internal GD
object. You can access the GD object directly, to use GD methods to
draw on it in ways that Chart::Plot does not anticipate. The
C<getGDobject()> method in Chart::Plot returns the object reference to
its internal GD object.

    my $GDobject = $img->getGDobject();
    my ($GDobject, $black, $white, $red, $green, $blue) 
        = $img->getGDObject();

In scalar context, this method returns only the reference to the GD
object. It can also return a list containing the reference to the
image object and the colors already created by Chart::Plot for that GD
onject, in the order specified above.  If you do not obtain these
colors, you will need to allocate your own colors before drawing,
example below. 

When you call the C<draw()> method of Chart::Plot (typically the last
step in your script) any drawing you have done in your script with GD
on the GD object will also be drawn.

Since Chart::Plot works with data values and GD works with pixel
values, you will need the C<data2pxl()> method of Chart::Plot to
translate (x,y) pairs of data values to (px,py) pairs of pixel
values. (You call this method on the Chart::Plot object, not the GD
object.) You must call this method only after all datasets have been
registered with the setData() method, since the graph scaling and this
translation may change with each new dataset.

Here is a brief example which draws small blue circles around each
data point in the chart. 

    use Chart::Plot; 
    my $img = Chart::Plot->new; 
    my @data = qw( 10 11 11 12 12 13 13 14 14 15);
    $img->setData (\@data);
    
    # draw circles around each data point, diameter 15 pixels
    my $gd = $img->getGDobject;
    my $blue = $gd->colorAllocate(0,0,255); # or use $img's blue 
    my ($px,$py); 
    for (my $i=0; $i<$#data; $i+=2) {
      ($px,$py) = $img->data2pxl ($data[$i], $data[$i+1]);
      $gd->arc($px,$py,15,15,0,360,$blue);
    }

    # draw the rest of the chart, and print it 
    open (OUT,">plot.gif"); 
    binmode OUT; 
    print OUT $img->draw(); 
    close OUT; 

 

=head1 BUGS AND TO DO

If your data is bunched tightly but far away from the origin, then you
will obtain a better chart if the graph is clipped away from the
origin. I have not yet found a useful way to do this, but I am still
thinking. You may be able to use Custom Tick Labels to improve your
chart in the meantime.

You will probably be unhappy with axis tick labels running together if
you use scientific notation.  Controlling tick label formatting and
length for scientific notation seems doable but challenging.

Future versions might incorporate a legend, control of font size, word
wrap and dynamic adjustment of axis labels and title. Better code, a
better pod page.


=head1 AUTHOR

Copyright (c) 1998-2000 by Sanford Morton <smorton@pobox.com>  All
rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself. 

This work is dedicated to the memory of Dr. Andrew Morton, who requested it. 
I<Requiescat in pace>, my friend.

=head1 SEE ALSO

GD::Graph(1) (formerly GIFgraph(1)) and Chart(1) are other front end
modules to GD(1). All can be found on CPAN.

=cut 
