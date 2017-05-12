
package Chart::Plot::Canvas;

our $VERSION = '0.04';

use strict;
use warnings;

use base qw(Chart::Plot);

#==================#
#  class variables #
#==================#

# list of image types supported by GD, currently jpeg, png or gif,
# depending on GD version; initialized in _init()
my @_image_types = ();

#==================#
#  public methods  #
#==================#

sub image_type {
  return (wantarray ? @_image_types : $_image_types[0]);
}

sub draw {
  my $self = shift;

  $self->_init_gd();

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

  }
  else {
    $_ = $_image_types[0];
    return $self->{'_im'}->$_();
  }
}

sub canvas {
  my $self = shift;

  $self->_init_cv(@_);

  # draw stuff in the GD object
  $self->_getMinMax() unless $self->{'_validMinMax'};
  $self->_createTitle() if $self->{'_title'}; # vert offset may be increased
  $self->_createAxes();
  $self->_createData();

  return $self->{'_cv'};
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
    $self->{'_imx'} = $_[0];
    $self->{'_imy'} = $_[1];
  }
  else {
    $self->{'_imx'} = 400;
    $self->{'_imy'} = 300;
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
  $self->{'_omx'} = 0;     $self->{'_omy'} = 0; # for axis ticks
  $self->{'_validMinMax'} = 0; # last calculated min and max still valid

  # initialize text
  ($self->{'_horAxisLabel'}, $self->{'_vertAxisLabel'}) = (q{},q{});
  $self->{'_title'} = q{};
  $self->{'_errorMessage'} = q{};

  # initialize custom tick labels
  ($self->{'_xTickLabels'}, $self->{'_yTickLabels'}) = (0,0);

  # undocumented: in script, use as $plotObject->{'_debugging'} = 1;
  $self->{'_debugging'} = 0;
}

sub _init_gd {
  my $self = shift;

  use GD;

  #  create an image object
  $self->{'_im'} = new GD::Image($self->{'_imx'}, $self->{'_imy'});

  # find format(s) supported by GD
  unless (@_image_types) {
    for ( qw(png gif jpeg) ) {
      push @_image_types, $_ if $self->{'_im'}->can($_);
    }
  }

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
}

sub _init_cv {
  my $self = shift;

  use Tk;
  my($widget) = @_;

  #  create an canvas object
  $self->{'_cv'} = $widget->Canvas(
      -width        => $self->{'_imx'},
      -height       => $self->{'_imy'},
  );

  # make the background white
  $self->{'_cv'}->configure(
      -background   => 'white',
  );

  # some fonts
  if ($^O eq 'MSWin32') {
    $self->{'_MediumBoldFont'} = "{MS Sans serif} 8 bold";
    $self->{'_SmallFont'} = "Tahoma 8";
    $self->{'_TinyFont'} = "{Small Fonts} 6";
  }
  else {
    $self->{'_MediumBoldFont'} = '7x13bold';
    $self->{'_SmallFont'} = '6x12';
    $self->{'_TinyFont'} =  '5x8';
  }
}

# draws all the datasets in $self->{'_data'}
# usage: $self->_createData()
sub _createData {
  my $self = shift;
  my ($i, $num, $px, $py, $prevpx, $prevpy, $dataSetLabel, $color);

  foreach $dataSetLabel (keys %{$self->{'_data'}}) {

    # get color
    if ( $self->{'_dataStyle'}->{$dataSetLabel} =~ /((red)|(blue)|(green))/i ) {
      $color = $1;
      $color =~ tr/A-Z/a-z/;
    }
    else {
      $color = 'black';
    }

    # draw the first point
    ($px, $py) = $self->_data2pxl (
                                   $self->{'_data'}->{$dataSetLabel} [0],
                                   $self->{'_data'}->{$dataSetLabel} [1]
                                  );
    $self->{'_cv'}->createOval($px-2, $py-2, $px+2, $py+2, -fill => $color, -outline => $color)
      unless $self->{'_dataStyle'}->{$dataSetLabel} =~ /nopoint/i;

    ($prevpx, $prevpy) = ($px, $py);

    # debugging
    if ($self->{'_debugging'}) {
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
      $self->{'_cv'}->createOval($px-2, $py-2, $px+2, $py+2, -fill => $color, -outline => $color)
        unless $self->{'_dataStyle'}->{$dataSetLabel} =~ /nopoint/i;

      # draw line from previous point, maybe
      if ($self->{'_dataStyle'}->{$dataSetLabel} =~ /dashed/) {
#        $self->{'_cv'}->createLine($prevpx, $prevpy, $px, $py, -width => 1, -dash => [6,6], -fill => $color);
        $self->{'_cv'}->createLine($prevpx, $prevpy, $px, $py, -dash => ',', -fill => $color);
      }
      elsif ($self->{'_dataStyle'}->{$dataSetLabel} =~ /noline/i) {
        next;
      }
      else { # default to solid line
        $self->{'_cv'}->createLine($prevpx, $prevpy, $px, $py, -fill => $color);
      }

      ($prevpx, $prevpy) = ($px, $py);

      # debugging
      if ($self->{'_debugging'}) {
        print STDERR "$i ($px, $py)";
      }
    }
  }
}

# draw the axes, axis labels, ticks and tick labels
# usage: $self->_createAxes
sub _createAxes {
  # axes run from data points: x -- ($xmin,0) ($xmax,0);
  #                            y -- (0,$ymin) (0,$ymax);
  # these mins and maxes are decimal orders of magnitude bounding the data

  my $self = shift;
  my ($w,$h) = (6, 12);

  ### horizontal axis
  my ($p1x, $p1y) = $self->_data2pxl ($self->{'_xmin'}, 0);
  my ($p2x, $p2y) = $self->_data2pxl ($self->{'_xmax'}, 0);
  $self->{'_cv'}->createLine($p1x, $p1y, $p2x, $p2y, -fill => 'black');

  ### axis label
  my $len = $w * length ($self->{'_horAxisLabel'});
  my $xStart = ($p2x+$len/2 > $self->{'_imx'}-10) # center under right end of axis
    ? ($self->{'_imx'}-10-$len) : ($p2x-$len/2);  #   or right justify
  $self->{'_cv'}->createText($xStart, $p2y+3*$h/2,
                             -font => $self->{'_SmallFont'},
                             -anchor => 'nw',
                             -text => $self->{'_horAxisLabel'},
                             -fill => 'black');

  print STDERR "\nHor: p1 ($p1x, $p1y) p2 ($p2x, $p2y)\n"
    if $self->{'_debugging'};

  ### vertical axis
  ($p1x, $p1y) = $self->_data2pxl (0, $self->{'_ymin'});
  ($p2x, $p2y) = $self->_data2pxl (0, $self->{'_ymax'});
  $self->{'_cv'}->createLine($p1x, $p1y, $p2x, $p2y, -fill => 'black');

  ### axis label
  $xStart = $p2x - length ($self->{'_vertAxisLabel'}) * $w / 2;
  $self->{'_cv'}->createText(($xStart>10 ? $xStart : 10), $p2y - 2*$h,
                             -font => $self->{'_SmallFont'},
                             -anchor => 'nw',
                             -text => $self->{'_vertAxisLabel'},
                             -fill => 'black');

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
      $self->{'_cv'}->createLine($px, $py-2, $px, $py+2, -fill => 'black');
      $self->{'_cv'}->createText($px, $py+3,
                                 -font => $self->{'_SmallFont'},
                                 -anchor => 'n',
                                 -text => ${$self->{'_xTickLabels'}}{$_},
                                 -fill => 'black');
    }

  }
  else {

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
      $self->{'_cv'}->createLine($px, $py-2, $px, $py+2, -fill => 'black');
      $self->{'_cv'}->createText($px, $py+3,
                                 -font => $self->{'_SmallFont'},
                                 -anchor => 'n',
                                 -text => $i,
                                 -fill => 'black') unless $i == 0;
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
      $self->{'_cv'}->createLine($px-2, $py, $px+2, $py, -fill => 'black');
      $self->{'_cv'}->createText($px-5, $py,
                                 -font => $self->{'_SmallFont'},
                                 -anchor => 'e',
                                 -text => ${$self->{'_yTickLabels'}}{$_},
                                 -fill => 'black');
    }
  }
  else {
    $step = $self->{'_omy'};
    $step /= 2  if ($self->{'_ymax'} - $self->{'_ymin'}) / $step < 6;
    $step /= 2  if ($self->{'_ymax'} - $self->{'_ymin'}) / $step < 6;
    $step *= 2  if ($self->{'_ymax'} - $self->{'_ymin'}) / $step > 12;

    for ($i=$self->{'_ymin'}; $i <= $self->{'_ymax'}; $i+=$step ) {
      ($px,$py) = $self->_data2pxl (0, $i);
      $self->{'_cv'}->createLine($px-2, $py, $px+2, $py, -fill => 'black');
      $self->{'_cv'}->createText($px-5, $py,
                                 -font => $self->{'_SmallFont'},
                                 -anchor => 'e',
                                 -text => $i,
                                 -fill => 'black') unless $i == 0;
    }
    print STDERR "Verstep: $step ($self->{'_ymax'} - $self->{'_ymin'})/$self->{'_omy'})\n"
      if $self->{'_debugging'};
  }
}

sub _createTitle {
  my $self = shift;
  my ($w,$h) = (7, 13);

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

   $self->{'_cv'}->createText($px, $py,
                              -font => $self->{'_MediumBoldFont'},
                              -anchor => 'center',
                              -text => $self->{'_title'},
                              -fill => 'black');
}

1;

__END__


=head1 NAME

Chart::Plot::Canvas - Plot two dimensional data in an Tk Canvas.

=head1 SYNOPSIS

    use Chart::Plot::Canvas;

    my $img = Chart::Plot::Canvas->new();
    my $anotherImg = Chart::Plot::Canvas->new ($image_width, $image_height);

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

    $img->canvas($toplevel)->pack();

=head1 DESCRIPTION

This package overloads Chart::Plot and supplies a new method 'canvas' that returns
a Tk Canvas equivalent to GD::Image returned by the method 'draw' of Chart::Plot.

The graphs are descripted by same way as for Chart::Plot.

With Chart::Plot::Canvas, the method 'draw' works like with Chart::Plot.

=head1 USAGE

See L<Chart::Plot> for all over methods.

=head2 Create the canvas: canvas()

     $img->canvas(toplevel);

This method creates the canvas and returns it.

    use Chart::Plot::Canvas;

    my $img = Chart::Plot->new();
    $img->setData (\@xdataset, \@ydataset);
    my $cv = $img->canvas($toplevel);
    $cv->pack();


=head1 SEE ALSO

L<Chart::Plot>

=head1 COPYRIGHT

(c) 2003-2011 Francois PERRAD, France. All rights reserved.

This library is distributed under the terms of the Artistic Licence 2.0.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=cut
