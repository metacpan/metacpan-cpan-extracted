package Astro::SkyPlot;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.03';
use Carp 'croak';
use Astro::MapProjection;
use PostScript::Simple;
use Class::XSAccessor {
  getters   => [qw/xsize ysize ps/],
  accessors => [qw/marker/]
};

use constant {
  HAMMER_PROJ     => 0,
  SINUSOIDAL_PROJ => 1,
  MILLER_PROJ     => 2,
};

use constant PROJ_COORD_TRAFO => [
  \&Astro::MapProjection::hammer_projection,
  \&Astro::MapProjection::sinusoidal_projection,
  \&Astro::MapProjection::miller_projection,
];
use constant PROJ_CANVAS_TRAFO => [
  sub {return( $_[0]*$_[2]/6 + $_[2]/2, $_[1]*$_[3]/6 + $_[3]/2 )},
  sub {return( $_[0]*$_[2]/6.5 + $_[2]/2, $_[1]*$_[3]/6.5 + $_[3]/2 )},
  sub {return( $_[0]*$_[2]/6.5 + $_[2]/2, $_[1]*$_[3]/6.5 + $_[3]/2 )},
];
use constant PROJ_NAMES => {
  'hammer'     => HAMMER_PROJ,
  'sinusoidal' => SINUSOIDAL_PROJ,
  'miller'     => MILLER_PROJ,
};

use constant PI      => atan2(1,0)*2;
use constant DEG2RAD => PI/180;
use constant RAD2DEG => 180/PI;

use constant {
  MARK_CIRCLE           => 0,
  MARK_CIRCLE_FILLED    => 1,
  MARK_BOX              => 2,
  MARK_BOX_FILLED       => 3,
  MARK_TRIANGLE         => 4,
  MARK_TRIANGLE_FILLED  => 5,
  MARK_DTRIANGLE        => 6,
  MARK_DTRIANGLE_FILLED => 7,
  MARK_CROSS            => 8,
  MARK_DIAG_CROSS       => 9,
};

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = ( 'all' => [ qw(
  MARK_CIRCLE
  MARK_CIRCLE_FILLED
  MARK_BOX
  MARK_BOX_FILLED
  MARK_TRIANGLE
  MARK_TRIANGLE_FILLED
  MARK_DTRIANGLE
  MARK_DTRIANGLE_FILLED
  MARK_CROSS
  MARK_DIAG_CROSS
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Astro::SkyPlot - Create very basic sky plots

=head1 SYNOPSIS

  use Astro::SkyPlot qw/:all/; # export the markers
  my $plot = Astro::SkyPlot->new(); # use defaults (see below)
  
  # specify options yourself:
  $plot = Astro::SkyPlot->new(
    xsize       => 200, # mm
    ysize       => 200,
    bgcolor     => [0, 0, 0], # RGB => black
    projection  => 'hammer',
    axiscolor   => [100, 100, 100], # RGB => grey
  );
  
  $plot->setcolor(255, 0, 0); # RGB => red
  $plot->plot_lat_long(1, 1); # units: radians
  $plot->plot_lat_long(1, 1, size => 0.2, marker => MARK_CIRCLE); # units: radians, radians, mm
  $plot->write(file => "skyplot.eps");

=head1 DESCRIPTION

A module to create very basic sky plots as EPS documents.

=head1 MARKERS

There are multiple types of markers that can be plotted into the sky plot.
These are defined through constants that can be exported from the module:

  MARK_CIRCLE           => circular markers
  MARK_CIRCLE_FILLED    => filled circular markers
  MARK_BOX              => square markers
  MARK_BOX_FILLED       => filled square markers
  MARK_TRIANGLE         => triangularmarkers
  MARK_TRIANGLE_FILLED  => filled triangular markers
  MARK_DTRIANGLE        => downward triangular markers
  MARK_DTRIANGLE_FILLED => filled downward triangular markers
  MARK_CROSS            => cross shaped markers
  MARK_DIAGCROSS        => diagonal cross shaped markers

=head1 PROJECTIONS

You can use the Hammer projection (C<"hammer">), the Sinusoidal projection
(C<"sinusoidal">), and the Miller projection (C<"miller">). Default is C<"hammer">.
You can use the C<projection> argument to the constructor to change this.

Cf. L<Astro::MapProjection> for details on these projections and have a look at
the default axes by running the F<examples/projections.pl> example.

=head1 METHODS

=head2 new

Constructor. Without arguments, uses the default settings
(cf. SYNOPSIS). Supports the following options:

    xsize       => Plot x-size in mm (def: 200mm)
    ysize       => Plot y-size in mm (def: 200mm)
    bgcolor     => Background color as array reference
                   (RGB value 0-255 per component)
                   (def: black, [0, 0, 0])
    projection  => Projection type. Default: Hammer projection ('hammer')
    axiscolor   => Color for the axes. (def: grey, [100, 100, 100])

=cut

sub new {
  my $class = shift;
  # todo: arg checking
  my $self = bless {
    xsize       => 200, # mm
    ysize       => 200,
    bgcolor     => [0, 0, 0], # RGB => black
    projection  => 'hammer',
    axiscolor   => [100, 100, 100], # RGB => grey
    marker      => MARK_CIRCLE_FILLED,
    @_,
  } => $class;

  my $ps = PostScript::Simple->new(
    eps    => 1,
    units  => "mm",
    xsize  => $self->xsize,
    ysize  => $self->ysize,
    colour => 1,
  );
  $self->{ps} = $ps;

  $self->setcolor(255, 255, 255);

  my $proj_name = $self->{projection};
  $self->{projection} = PROJ_NAMES->{$proj_name};
  croak("Unknown projection '$proj_name'")
    if not defined $self->{projection};

  $self->_draw_bg();
  $self->_plot_axis();

  return $self;
}

=head2 setcolor

Set a new drawing color. Takes three numbers corresponding to red,
green and blue values between 0 and 255.

=cut

sub setcolor {
  my $self = shift;
  croak("Need three numbers (RGB) for the drawing color")
    if @_ != 3;
  $self->{color} = [@_];
  $self->{ps}->setcolour(@_);
  return $self;
}

=head2 plot_lat_long

Draw a new latitude/longitude point.

These may be followed by key/value pairs of options.
Supported options:

C<size>: the size (radius) of the point (default: 0.1mm)

C<marker>: The type of marker to use (see L</MARKERS>).

=cut

sub plot_lat_long {
  my $self = shift;
  croak("Need latitude/longitude")
    if @_ < 2;
  my $lat = shift;
  my $long = shift;
  my %opt = @_;
  my $size = $opt{size}||0.1;
  my $ps = $self->{ps};
  my ($x, $y) = $self->_project($lat, $long);
  my $marker = exists($opt{marker}) ? $opt{marker} : $self->{marker};
  $self->_draw_marker($x, $y, $marker, $size);
}

=head2 write

Write the plot to the specified EPS file.

=cut

sub write {
  my $self = shift;
  my $file = shift;
  croak("Need file name as argument")
    if not defined $_[0];
  my $ps = $self->{ps};
  $ps->output($_[0]);
  return $self;
}

=head1 ACCESSOR METHODS

The following are read only accessors unless otherwise noted.

=head2 marker

Get/Set the default marker type. The marker type for a single
plot operation can be specified as an option to C<plot_lat_long>.

=head2 ps

Returns the internals C<PostScript::Simple> object.

=head2 xsize

Returns the image's width (in mm).

=head2 ysize

Returns the image's height (in mm).

=cut

=head1 PRIVATE METHODS

=head2 _draw_bg

Draws the plot's background.

=cut

sub _draw_bg {
  my $self = shift;
  my $ps = $self->{ps};
  $ps->setcolour(0, 0, 0);
  $ps->box({filled=>1}, 0, 0, $self->xsize, $self->ysize);
  $ps->setcolour(255, 255, 255);
  return $self->_restore_color();
}

=head2 _restore_color

Restores the previously saved color.

=cut

sub _restore_color {
  my $self = shift;
  my $ps = $self->{ps};
  $ps->setcolour(@{$self->{color}});
  return $self;
}

=head2 _plot_axis

Plot the sky-plot axis.

=cut

sub _plot_axis {
  my $self = shift;
  my $ps = $self->{ps};
  my $projection = $self->{projection};
  my $old_color = $self->{color};
  $self->setcolor(@{$self->{axiscolor}});
  my $xsize = $self->{xsize};
  my $ysize = $self->{ysize};

  my $ps_trafo = PROJ_CANVAS_TRAFO->[$projection];
  my $projector = PROJ_COORD_TRAFO->[$projection];

  $ps->setlinewidth(0.05);
  
  if ($projection == HAMMER_PROJ || $projection == SINUSOIDAL_PROJ) {
    # plot longitude axes
    for (my $long = -180*DEG2RAD; $long <= 180.001*DEG2RAD; $long += 45*DEG2RAD) {
      my $first = 1;
      for (my $lat = -90*DEG2RAD; $lat <= 90.001*DEG2RAD; $lat += 3.0*DEG2RAD) {
        my ($x, $y) = $ps_trafo->( $projector->($lat, $long), $xsize, $ysize );
        if ($first) {
          $ps->line($x, $y, $x, $y);
          $first = 0;
        }
        else {
          $ps->linextend($x, $y);
        }
      }
    }

    # plot lat axes
    for (my $lat = -90*DEG2RAD; $lat <= 90.001*DEG2RAD; $lat += 10*DEG2RAD) {
      my $first = 1;
      for (my $long = -180*DEG2RAD; $long <= 180.001*DEG2RAD; $long += 5.0*DEG2RAD) {
        my ($x, $y) = $ps_trafo->( $projector->($lat, $long), $xsize, $ysize );
        if ($first) {
          $ps->line($x, $y, $x, $y);
          $first = 0;
        }
        else {
          $ps->linextend($x, $y);
        }
      }
    }
  }
  elsif ($projection == MILLER_PROJ) {
    # much, much less steps required ==> special case
    # plot longitude axes
    for (my $long = -180*DEG2RAD; $long <= 180.001*DEG2RAD; $long += 45*DEG2RAD) {
      my ($xs, $ys) = $ps_trafo->( $projector->(-90*DEG2RAD, $long), $xsize, $ysize );
      my ($xe, $ye) = $ps_trafo->( $projector->(90*DEG2RAD, $long), $xsize, $ysize );
      $ps->line($xs, $ys, $xe, $ye);
    }

    # plot lat axes
    for (my $lat = -90*DEG2RAD; $lat <= 90.001*DEG2RAD; $lat += 10*DEG2RAD) {
      my ($xs, $ys) = $ps_trafo->( $projector->($lat, -180*DEG2RAD), $xsize, $ysize );
      my ($xe, $ye) = $ps_trafo->( $projector->($lat, 180*DEG2RAD), $xsize, $ysize );
      $ps->line($xs, $ys, $xe, $ye);
    }
  }
  else {
    die "Invalid projection type $projection";
  }

  $self->{color} = $old_color;
  return $self->_restore_color();
}

=head2 _project

Projects given lat/long to x/y to plot coordinates.

=cut

sub _project {
  my $self = shift;
  my $projection = $self->{projection};
  my $ps_trafo = PROJ_CANVAS_TRAFO->[$projection];
  my $projector = PROJ_COORD_TRAFO->[$projection];
  return $ps_trafo->( $projector->(@_), $self->{xsize}, $self->{ysize} );
}

=head2 _draw_marker

Draws a marker at the given plot coordinates. Arguments C<$x, $y, $markerno, $size>.

=cut

sub _draw_marker {
  my $self = shift;
  die('Need $x, $y, $marker, $size')
    if not @_ == 4;
  my ($x, $y, $marker, $size) = @_;
  my $ps = $self->{ps};
  if ($marker <= MARK_CIRCLE_FILLED) {
    $ps->circle(
      {filled => ($marker == MARK_CIRCLE_FILLED)},
      $x, $y, $size
    );
  }
  elsif ($marker <= MARK_BOX_FILLED) {
    $ps->box(
      {filled => ($marker == MARK_BOX_FILLED)},
      $x-$size, $y-$size, $x+$size, $y+$size
    );
  }
  elsif ($marker <= MARK_TRIANGLE_FILLED) {
    my $lowy = $y-$size;
    $ps->polygon(
      {filled => ($marker == MARK_TRIANGLE_FILLED)},
      $x-$size, $lowy,
      $x+$size, $lowy,
      $x, $y+$size,
      $x-$size, $lowy,
    );
  }
  elsif ($marker <= MARK_DTRIANGLE_FILLED) {
    my $highy = $y+$size;
    $ps->polygon(
      {filled => ($marker == MARK_DTRIANGLE_FILLED)},
      $x-$size, $highy,
      $x+$size, $highy,
      $x, $y-$size,
      $x-$size, $highy,
    );
  }
  elsif ($marker == MARK_CROSS) {
    $ps->line(
      $x-$size, $y, $x+$size, $y
    );
    $ps->line(
      $x, $y-$size, $x, $y+$size
    );
  }
  elsif ($marker == MARK_DIAG_CROSS) {
    $ps->line(
      $x-$size, $y-$size, $x+$size, $y+$size
    );
    $ps->line(
      $x-$size, $y+$size, $x+$size, $y-$size
    );
  }
  else {
    die('Invalid marker no. ' . $marker);
  }
}

1;
__END__


=head1 SEE ALSO

For more general information on map projections: L<http://en.wikipedia.org/wiki/Map_projection>

Map projections are implemented in L<Astro::MapProjection>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
