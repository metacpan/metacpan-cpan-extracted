package Chart::Plot::Annotated;

use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '0.01';

##################################################################
# define this class:
use base 'Chart::Plot';
use Class::MethodMaker
  # the extra data we'll put into the Chart::Plot object
  object_list => [ Chart::Plot::Annotated::_DataPt => '_AnnoData' ],

  # formatting internals
  get_set => [ qw [ _anno_xOffset _anno_yOffset _anno_font _anno_color ] ],

  # error-reporting
  get_set => [ '_problem' ];
##################################################################
# define an auxiliary class:
use Class::Struct Chart::Plot::Annotated::_DataPt =>
  [ X => '$', Y => '$', anno => '$' ];
##################################################################
# new public method:
sub setAnnoData {
  my $self = shift;
  my @annos = @{shift @_};

  my $rc = $self->setData(@_);
  if (not $rc) {
    return $rc;
  }

  # store the datapoints for later
  if (ref $_[0] eq 'ARRAY' and ref $_[1] eq 'ARRAY') {
    # x datapts and y datapts separated
    my (@x) = @{shift @_};
    my (@y) = @{shift @_};
    unless (@annos == @x) {
      $self->_problem("different numbers of annotations and x-values");
      return 0;
    }

    unless (@annos == @y) {
      $self->_problem("different numbers of annotations and y-values");
      return 0;
    }

    while (@annos) {
      my $datum =
	Chart::Plot::Annotated::_DataPt->new( X => shift @x,
					      Y => shift @y,
					      anno => shift @annos
					    );
      $self->push__AnnoData($datum);
    }
  }
  else {
    # assume X and Y datapoints presented as one array
    my @xy = @{shift @_};
    unless (@xy == 2*@annos) {
      $self->_problem("annos not synced with (x,y) values " .
		      "-- different numbers of elements");
      return 0;
    }
    while (@annos) {
      my $datum;
      my $anno = shift @annos;
      if (not defined $anno) {
	$anno = '';
      }
      $datum =
	Chart::Plot::Annotated::_DataPt->new( X => shift @xy,
					      Y => shift @xy,
					      anno => $anno );
      $self->push__AnnoData($datum);
    }
  }

  if (defined $_[0] and ref $_[0] eq 'ARRAY') {
    $self->_problem("too many arrayrefs to setAnnoData");
    return 0;
  }

  # arrive here? no problems.
  return 1;
}
##################################################################
# override base class to handle extra layer's new possible errors
sub error {
  my $self = shift;
  if (defined $self->_problem) {
    return $self->_problem();
  }
  # else call base class
  return $self->SUPER::error();
}
##################################################################
# override base class to handle extra layer's extra options
sub setGraphOptions {
  my $self = shift;
  my %args = @_;
  if (defined $args{anno_color}) {
    if (ref $args{anno_color} ne 'ARRAY') {
      $self->_problem("anno_color arg to setGraphOptions()" .
		      " needs arrayref value");
      return 0;
    }
    $self->_setAnnoColor(@{$args{anno_color}})
      or return 0; # problem?
    delete $args{anno_color};
  }

  if (defined $args{anno_xOffset}) {
    $self->_anno_xOffset($args{anno_xOffset});
    delete $args{anno_xOffset};
  }
  if (defined $args{anno_yOffset}) {
    $self->_anno_yOffset($args{anno_yOffset});
    delete $args{anno_yOffset};
  }

  # send remaining args to base class, if there are any left
  if (%args) {
    return $self->SUPER::setGraphOptions(%args);
  }
  else {
    # everything went fine!
    return 1;
  }
}
##################################################################
use GD; # use this to directly annotate the resulting plot with the
        # annotations.
##################################################################
# override base class to handle extra layer's extra markup on the
# image object
sub draw {
  my $self = shift;
  my $gdObj = $self->SUPER::getGDobject();

  if (not defined $self->_anno_color) {
    $self->_setAnnoColor(0,0,0); # black
  }
  if (not defined $self->_anno_font) {
    $self->_anno_font( gdTinyFont );
  }
  if (not defined $self->_anno_xOffset) {
    $self->_anno_xOffset( 0 );
  }
  if (not defined $self->_anno_yOffset) {
    $self->_anno_yOffset( 0 );
  }

  # set all the annotations
  while ($self->count__AnnoData) {
    my $datum = $self->shift__AnnoData;
    if (defined $datum->anno and length $datum->anno) {
      $self->_setAnno($gdObj, $datum);
    }
    # otherwise skip empty strings
  }

  # done with extra markup, now call base class draw; returning
  # whatever it does
  return $self->SUPER::draw();
}
##################################################################
# private methods
##################################################################
sub _setAnnoColor {
  # sets the annotation color to the appropriate color-triple. Used
  # for handling configuration data
  my $self = shift;
  my ($r, $g, $b) = @_;

  if (@_ < 3) {
    # fatal
    $self->_problem( "need 3 args to annotation color-setting" );
    return 0;
  }
  if (@_ > 3) {
    # non-fatal, though silly
    carp "_setAnnoColor args beyond (R,G,B) ignored";
  }

  my $gdObj = $self->SUPER::getGDobject();
  my $color = $gdObj->colorAllocate($r, $g, $b);

  $self->_anno_color($color);
  return 1;
}
##################################################################
sub _setAnno {
  # writes an annotation onto the base class Chart::Plot, given a
  # pointer to the GD Object underneath.
  my $self = shift;
  my $gdObj = shift;
  my $datum = shift;
  my ($xp, $yp) = $self->SUPER::data2pxl($datum->X, $datum->Y);
  $gdObj->string($self->_anno_font,
		 ($xp + $self->_anno_xOffset),
		 ($yp + $self->_anno_yOffset),
		 $datum->anno,
		 $self->_anno_color);
}
##################################################################
1;

__END__

=head1 NAME

Chart::Plot::Annotated - Subclass of Chart::Plot that allows text
annotation of data-points.

=head1 SYNOPSIS

  use Chart::Plot::Annotated;

  # initialize same as Chart::Plot
  my $img = Chart::Plot::Annotated->new();
  my $anotherImg =
    Chart::Plot::Annotated->new($image_width, $image_height);

  # setData() method uses extra initial argument of datapoint
  # annotation strings. Must be the same length as the number of
  # points. Can use undef or '' to indicate no annotation for a given
  # point.

  $img->setAnnoData (\@annotations, \@dataset)
     or die( $img->error() );
  $img->setAnnoData (\@annotations, \@xdataset, \@ydataset);
  $img->setAnnoData (\@yetmoreAnnos, \@xanotherdataset, \@yanotherdataset,
                     'Blue SolidLine NoPoints');

  # note the new keys allowed for setGraphOptions:
  $img->setGraphOptions ('horGraphOffset' => 75,
                         'vertGraphOffset' => 100,
                         'title' => 'My Graph Title',
                         'horAxisLabel' => 'my X label',
                         'vertAxisLabel' => 'my Y label',

      # now there are new keys allowed:
                         'anno_color' => [ 255, 0, 0 ], # red anno
                                                        # text!
                         'anno_xpix_offset' => 2,
                         'anno_ypix_offset' => -2,
                         # using anno_font requires that GD be 'use'd
                         # in this module to name fonts
                         'anno_font' => gdMediumBoldFont,
                         );

  # can still use Chart::Plot's methods:
  $img->setData (\@anotherdataset, 'red_dashedline_points');
  my ($xmin, $ymin, $xmax, $ymax) = $img->getBounds();

  # prints annotated Chart
  print $img->draw();

=head1 DESCRIPTION

A subclass of Chart::Plot that provides a new method allowing
text annotations on groups of datapoints.

=head1 Features

=head2 Additional methods

In addition to those methods provided by C<Chart::Plot>, this class
provides the following additional methods:

=over

=item setAnnoData

  $img->setAnnoData (\@annos, \@data);
  $img->setAnnoData (\@annos, \@xdata, \@ydata);
  $img->setAnnoData (\@annos, \@data, 'red_dashedline_points');
  $img->setAnnoData (\@annos, \@xdata, \@ydata, 'blue solidline');

Like parent class (see L<Chart::Plot>), but takes additional initial
argument arrayref of the text annotations for the datapoints.

Unlike parent class (in some scenarios), the positions of the
annotations are fixed when passed to this function, so if you modify
the data after passing it in, the parent class data-plotting may move
the datapoints, but the annotations will consistently remain where the
datapoints were when entered. Caveat user. (and see the notes on this
subject in C<Chart::Plot>'s documentation).

Note that for un-annotated datasets, you can still use the C<setData>
method from the parent class on C<Chart::Plot::Annotated> objects,
even in the same image.

=back

=head2 Additional graph options

In addition to the graph options provided by C<Chart::Plot>, this
module also provides the following graph-wide options:

=over

=item anno_color

Requires an arrayref with 3 values indicating the C<(R,G,B)> values
for the desired color. This color applies to all the datapoint
annotations in the plot.

=item anno_font

Requires a C<GD::Font> object as a value. The default is C<gdTinyFont>.

=item anno_xpix_offset

The number of horizontal pixels from the data point to set the
annotations.  This can be negative or positive. Default is C<0>.

=item anno_ypix_offset

The number of vertical pixels from the data point to set the
annotations.  This can be negative or positive. Default is C<0>.

=back

=head1 TO DO

=over

=item allow colors to be set per annotation group

This would be nice.

=item allow font variation per anno group

Nice to have, as well. Should probably have the same per-annotation
group treatment that color should get.

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Chart::Plot::Annotated

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<Chart::Plot> by Sanford Morton.

L<perl>.

=cut
