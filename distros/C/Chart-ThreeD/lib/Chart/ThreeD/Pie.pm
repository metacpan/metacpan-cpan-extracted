# -*- mode: Perl -*-

##########################################################################
#
#   Pie.pm  - 3D Piecharts
#
# version : 0.01
# Project : 3D Charts
# Copyright (c) 1998-1999, Fabien Tassin <fta@oleane.net>
#
##########################################################################
# ABSOLUTELY NO WARRANTY WITH THIS PACKAGE. USE IT AT YOUR OWN RISKS.
##########################################################################

package Chart::ThreeD::Pie;

use strict;
use Carp;
use vars qw(@ISA @EXPORT $VERSION $DEBUG);
use Exporter;
use GD;

$VERSION = 0.01;
$DEBUG = 0;
@ISA = ('Exporter');
@EXPORT = qw();

=head1 NAME

Pie.pm - 3D Piechart

=head1 SYNOPSIS

    use Chart::ThreeD::Pie;

    # create a new pie
    my $pie = new Chart::ThreeD::Pie (500, 300, "title");

    # add data
    $pie->add (160, '#FFAA00', 'part 1');
    $pie->add (350, '#00FF66', 'part 2');
    $pie->add (100, '#AA00FF', 'part 3');
    $pie->add (300, '#0000FF', 'part 4');
    $pie->add (300, '#DD00FF', 'part 5');
    $pie->add (300, '#00DDFF', 'part 6');

    # add a percentage after each label part.
    $pie->percents (1);

    # only draw parts greater or equal to 3%. All other parts will be
    # concatenated in to a part called "others" (using red color)
    $pie->limit (2, '#FF0000', 'others');

    # thickness of the pie
    $pie->thickness (30);

    # sort the "parts"
    $pie->want_sort (1);

    # foreground and background colors
    $pie->fgcolor ('#FF0000');
    $pie->bgcolor ('#00FFFF');

    # add a border
    $pie->border (1);

    # make sure we are writing to a binary stream
    binmode STDOUT;

    # Draw the pie, Convert the image to GIF and print it on standard output
    print $pie->plot->gif;

=head1 DESCRIPTION

    Chart::ThreeD::Pie allows you to create 3D Piecharts very easily
    and emit the drawings as GIF files. You can customize almost everything
    using a large number of methods.

    This module requires the Lincoln D. Stein's GD module available on CPAN.

=head1 Method Calls


=head2 Creating Pie

=over 5

=item C<new>

C<Chart::ThreeD::Pie::new(width, height, title)> I<class method>

To create a new pie, send a new() message to the Chart::ThreeD::Pie
class.  For example:

        $pie = new Chart::ThreeD::Pie (450, 320, 'my title');

This will create an image that is 450 x 320 pixels wide.  If you don't
specify the dimensions, a default of 400 x 300 will be chosen. The default
title is an empty string (no title). The three parameters can be changed
using the corresponding methods specified bellow.

=back

=cut

# A new Pie object
sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize (@_);
  return $self;
}

sub initialize {
  my $self = shift;

  $self->{xmax}  = shift || 400;
  $self->{ymax}  = shift || 300;
  $self->{title} = shift || '';
  $self->{data}  = [];
  $self->{bgcolor} = '#FFFFFF';
  $self->{fgcolor} = '#000000';
  $self->{limit} = [ 7, '#FF0000', 'others' ];
  $self->{transparent} = 0;
  $self->{interlaced} = 0;
  $self->{thickness} = 30; # pixels
  $self->{radius} = $self->{xmax} / 3;
  $self->{want_sort} = 0;
  $self->{border} = 0;
  $self->{percents} = 0;
}

=head2 Commands

=over 5

=item C<thickness>

C<Chart::ThreeD::Pie::thickness(val)> I<object method>

This allows you to set the thickness (in pixel) of the pie if val is
defined. The current value is returned. Default value is 30 pixels.

Example:

      print "Current thickness is ", $pie->thickness, " pixels\n";
      # set it to 20.
      $pie->thickness(20);

=cut

sub thickness {
  my $self = shift;
  my $arg  = shift;
  $self->{thickness} = $arg if defined $arg;
  return $self->{thickness};
}

=item C<want_sort>

C<Chart::ThreeD::Pie::thickness(bool)> I<object method>

This will allow you to sort the parts of the pie if bool is non-null.
The current value is returned. Default is null;

Example:

      print "Current want_sort value is ", $pie->want_sort, "\n";
      # set it to true
      $pie->want_sort(1);

=cut

sub want_sort {
  my $self = shift;
  my $arg  = shift;
  $self->{want_sort} = $arg if defined $arg;
  return $self->{want_sort};
}

=item C<transparent>

C<Chart::ThreeD::Pie::transparent(bool)> I<object method>

This will allow you to make the background of the final picture transparent
if bool is non-null. The current value is returned. Default is null;

Example:

      # Background will be transparent.
      $pie->transparent(1);

=cut

sub transparent {
  my $self = shift;
  my $arg  = shift;
  $self->{transparent} = $arg if defined $arg;
  return $self->{transparent};
}

=item C<interlaced>

C<Chart::ThreeD::Pie::interlaced(bool)> I<object method>

This will allow you to make the background of the final picture interlaced
if bool is non-null. The current value is returned. Default is null;

Example:

      # Picture will be interlaced
      $pie->interlaced(1);

=cut

sub interlaced {
  my $self = shift;
  my $arg  = shift;
  $self->{interlaced} = $arg if defined $arg;
  return $self->{interlaced};
}

=item C<percents>

C<Chart::ThreeD::Pie::percents(bool)> I<object method>

This will add percentages after the label of each part of the pie
if bool is non-null. The current value is returned. Default is null;

Example:

      # add percents in labels
      $pie->percents(1);

=cut

sub percents {
  my $self = shift;
  my $arg  = shift;
  $self->{percents} = $arg if defined $arg;
  return $self->{percents};
}

=item C<bgcolor>

C<Chart::ThreeD::Pie::bgcolor(bgcolor)> I<object method>

Set the background color if bgcolor is defined. The current value is
returned. Default value is '#000000' (black). Color is a string
composed of a '#' followed by 3 two-digits hexadecimal values, respectively
Red, Green and Blue.

Example:

      # set the background color to yellow
      $pie->bgcolor ('#FFFF00');

=cut

sub bgcolor {
  my $self = shift;
  my $arg  = shift;
  $self->{bgcolor} = $arg if defined $arg;
  return $self->{bgcolor};
}

=item C<fgcolor>

C<Chart::ThreeD::Pie::fgcolor(fgcolor)> I<object method>

Set the foreground color if fgcolor is defined. The current value is
returned. Default value is '#000000' (black). Color is a string
composed of a '#' followed by 3 two-digits hexadecimal values, respectively
Red, Green and Blue.

Example:

      # set the foreground color to red
      $pie->fgcolor ('#FF0000');

=cut

sub fgcolor {
  my $self = shift;
  my $arg  = shift;
  $self->{fgcolor} = $arg if defined $arg;
  return $self->{fgcolor};
}

=item C<border>

C<Chart::ThreeD::Pie::border(bool)> I<object method>

This will allow you to add a border to the final picture if bool is non-null.
The current value is returned. Default is null. The color of the boder
is specified by fgcolor.

Example:

      # Want a border
      $pie->border(1);

=cut

sub border {
  my $self = shift;
  my $arg  = shift;
  $self->{border} = $arg if defined $arg;
  return $self->{border};
}

=item C<limit>

C<Chart::ThreeD::Pie::limit(val, color, label)> I<object method>

This allows you to set the size (in percent) of the smallest part of
the pie that will be drawn. All other parts will be merged into a
single part labeled by 'label' and using the color 'color'. If 'val'
is null, all parts are drawn. Default values are  7, '#FF0000' and
'others'. Current values are returned.

=cut

sub limit {
  my $self = shift;
  splice @{$self->{limit}}, 0, $#_ + 1, @_;
  return $self->{limit};
}

=item C<radius>

C<Chart::ThreeD::Pie::radius(rad)> I<object method>

Specify the radius of the pie in pixels if rad is non-null. The current
value is returned. The default value is a third of the xmax value given
to the creation of the pie (first parameter of the constructor).

Example:

      # set radius to 100.
      $pie->radius(100);

=cut

sub radius {
  my $self = shift;
  my $arg  = shift;
  $self->{radius} = $arg if defined $arg;
  return $self->{radius};
}

=item C<xmax>

C<Chart::ThreeD::Pie::xmax(val)> I<object method>

This allows you to set the length (in pixel) of the pie if val is
defined. The current value is returned.

Example:

      print "Current length is ", $pie->xmax, " pixels\n";
      # set it to 600.
      $pie->xmax(600);

=cut

sub xmax {
  my $self = shift;
  my $arg  = shift;
  $self->{xmax} = $arg if defined $arg;
  return $self->{xmax};
}

=item C<ymax>

C<Chart::ThreeD::Pie::ymax(val)> I<object method>

This allows you to set the width (in pixel) of the pie if val is
defined. The current value is returned.

Example:

      print "Current width is ", $pie->ymax, " pixels\n";
      # set it to 500.
      $pie->ymax(500);

=cut

sub ymax {
  my $self = shift;
  my $arg  = shift;
  $self->{ymax} = $arg if defined $arg;
  return $self->{ymax};
}

=item C<title>

C<Chart::ThreeD::Pie::title(val)> I<object method>

This allows you to change the title of the pie if val is defined.
The current value is returned.

Example:

      print "Current title is '", $pie->title, "'\n";
      # set it to 'my own title'.
      $pie->title('my own title');

=cut

sub title {
  my $self = shift;
  my $arg  = shift;
  $self->{title} = $arg if defined $arg;
  return $self->{title};
}

=item C<add>

C<Chart::ThreeD::Pie::add(val, color, label)> I<object method>

This method adds a part to a pie. The size of the part is specified by val.
Both color and label are optional. The default color is '#DDDDDD' and the
default label is ''.

=cut

sub add {
  my $self  = shift;
  my $value = shift;
  my $color = shift || "#DDDDDD";
  my $label = shift || '';
  push @{$self->{data}}, [ $value, $color, $label ];
}

=item C<plot>

C<Chart::ThreeD::Pie::plot()> I<object method>

Draw the pie. This method returns a GD object (see L<GD>).

=cut

sub plot {
  my $self = shift;

  my $pie = new GD::Image($self->xmax, $self->ymax);

  my $fontw = gdSmallFont->width;
  my $fonth = gdSmallFont->height;

  my $bgcolor = $pie->colorAllocate (&cvtcolor ($self->bgcolor));
  $pie->transparent ($bgcolor) if $self->transparent;
  $pie->fill (0, 0, $bgcolor);
  my $total = 0;
  map { $total += $$_[0] } @{$self->{data}};

  my $fgcolor = $pie->colorAllocate (&cvtcolor ($self->fgcolor));
  my $defaultcolor = $pie->colorAllocate (&cvtcolor (${$self->limit}[1]));
  my $defaultcolor2 = $pie->colorAllocate
    (&shadecolor (&cvtcolor (${$self->limit}[1])));

  my $orgx = $self->xmax / 2;
  my $orgy = $self->ymax / 2 - $self->thickness / 2 + gdGiantFont->height / 2;

  my $x = $self->radius * 11 / 6;
  my $y = $self->radius * 7 / 6;
  $pie->arc ($orgx, $orgy, $x, $y, 0, 360, $fgcolor);
  $pie->fill ($orgx, $orgy, $defaultcolor);
  $pie->arc ($orgx, $orgy + $self->thickness, $x, $y, 0, 180, $fgcolor);
  $pie->line ($orgx - $x / 2, $orgy, $orgx - $x / 2, $orgy + $self->thickness,
	      $fgcolor);
  $pie->line ($orgx + $x / 2, $orgy, $orgx + $x / 2, $orgy + $self->thickness,
	      $fgcolor);
  $pie->fill ($orgx, $orgy + $self->thickness * 3 / 4 + $y / 2,
	      $defaultcolor2);

  my @data = $self->want_sort ? sort {$$b[0] <=> $$a[0]} @{$self->{data}} :
    @{$self->{data}};
  my ($elem, $old);
  my $num = 0;
  my $a0 = 270;
  my $a = $a0;
  my $k = 0.55;
  for $elem (@data) {
    $num++;
    my $angle = 360 * $$elem[0] / $total;
    my $ang   = $a + $angle / 2;
    my $h = sin (&deg2rad ($ang - $a0));
    my $r = cos (&deg2rad ($ang - $a0));

    my $color = $pie->colorAllocate (&cvtcolor ($$elem[1]));
    my $color2 = $pie->colorAllocate (&shadecolor (&cvtcolor ($$elem[1])));

    my $dial = 0;
    $dial = 1 if $h >= 0 && $r >= 0;
    $dial = 2 if $h >= 0 && $r <  0;
    $dial = 3 if $h <  0 && $r <  0;
    $dial = 4 if $h <  0 && $r >= 0;
    if (!$self->want_sort || !${$self->limit}[0] ||
	($ {$self->limit}[0] > 0 && $angle > $ {$self->limit}[0] * 3.6)) {
      $pie->line ($orgx, $orgy, $orgx - $x / 2 * sin (&deg2rad ($a)),
		  $orgy - $y / 2 * cos (&deg2rad ($a)), $fgcolor)
	unless $$elem[0] == $total;

      $pie->line ($orgx, $orgy,
		  $orgx - $x / 2 * sin (&deg2rad ($a + $angle)),
		  $orgy - $y / 2 * cos (&deg2rad ($a + $angle)), $fgcolor)
	unless $$elem[0] == $total;
      $pie->fill ($orgx - $x / 4 * sin (&deg2rad ($a + $angle / 2)),
		  $orgy - $y / 4 * cos (&deg2rad ($a + $angle / 2)),
		  $color);
      $pie->line ($orgx - $x / 2 * sin (&deg2rad ($a + $angle)),
		  $orgy - $y / 2 * cos (&deg2rad ($a + $angle)),
		  $orgx - $x / 2 * sin (&deg2rad ($a + $angle)),
		  $orgy - $y / 2 * cos (&deg2rad ($a + $angle)) +
		  $self->thickness, $fgcolor)
	unless $a + $angle > 270 && $a + $angle < 450;
      $pie->fill ($orgx - $x / 2 * sin (&deg2rad ($a + $angle - 4)),
		  $orgy - $y / 2 * cos (&deg2rad ($a + $angle - 4)) +
		  $self->thickness / 2, $color2)
	unless ($a + $angle > 270 && $a + $angle < 450) ||
		($a + $angle > 610); # && $num != 1);
      $pie->fill ($orgx - $x / 2 * sin (&deg2rad ($a + $angle / 2)),
		  $orgy - $y / 2 * cos (&deg2rad ($a + $angle / 2)) +
		  $self->thickness / 2, $color2)
	if $a + $angle > 510 && $num != 1;
      $pie->fill ($orgx - $x / 2 * sin (&deg2rad (200)),
		  $orgy - $y / 2 * cos (&deg2rad (200)) + $self->thickness / 2,
		  $color2)
	if $angle == 360;

      my $text = $$elem[2];
      $text .= sprintf " (%.1f%%)", $angle / 3.6 if $self->{'percents'};
      my $dum = length $text;
      my ($tx, $ty);
      if ($dial == 1) {
	$tx = $orgx - $x * $k * sin (&deg2rad ($ang));
	$ty = $orgy - $y * $k * cos (&deg2rad ($ang)) - $fonth;
      } elsif ($dial == 2) {
	$tx = $orgx - $x * $k * sin (&deg2rad ($ang)) - $fontw * $dum;
	$ty = $orgy - $y * $k * cos (&deg2rad ($ang)) - $fonth;
      } elsif ($dial == 3) {
	$tx = $orgx - $x * $k * sin (&deg2rad ($ang)) - $fontw * $dum;
	$ty = $orgy - $y * $k * cos (&deg2rad ($ang)) +
	  3 / 4 * $self->thickness;
      } elsif ($dial == 4) {
	$tx = $orgx - $x * $k * sin (&deg2rad ($ang));
	$ty = $orgy - $y * $k * cos (&deg2rad ($ang)) +
	  3 / 4 * $self->thickness;
      }
      $pie->string (gdSmallFont, $tx, $ty, $text, $fgcolor);
    }
    else {
      $old = $a unless $old;
    }
    $a += $angle;
  }
  if ($old) {
    my $angle = 360 - $old + $a0 ;
    $a = $old;
    my $ang = $a + $angle / 2;
    my ($posTx, $posTy);
    my $msg = ${$self->limit}[2];
    $msg .= sprintf " (%.1f%%)", $angle / 3.6 if $self->{'percents'};
    if (cos (&deg2rad ($ang - $a0)) > 0) {
      $posTx = $orgx - $x * $k * sin (&deg2rad ($ang));
    }
    else {
      my $dum = length $msg;
      $posTx = $orgx - $x * $k * sin (&deg2rad ($ang)) - $fontw * $dum;
    }
    $posTy = $orgy - $y * $k * cos (&deg2rad ($ang)) +
	  3 / 4 * $self->thickness;
    $pie->string (gdSmallFont, $posTx, $posTy, $msg, $fgcolor);
  }
  $pie->string (gdGiantFont, 5, 3,  $self->title, $fgcolor) if $self->title;
  $pie->rectangle (0, 0, $self->xmax - 1, $self->ymax - 1, $fgcolor)
    if $self->{'border'};
  $self->{pict} = $pie;
  $pie;
}

=item C<gif>

C<Chart::ThreeD::Pie::gif()> I<object method>

This returns the image data in GIF format.  You can then print it,
pipe it to a display program, or write it to a file. You MUST call
the plot() method at least once before calling gif().

Example:

    $pie->plot;
    open (PIPE, "| xv -") || die "Error: $!";
    binmode PIPE;
    print PIPE $pie->gif;
    close PIPE;

=cut

sub gif {
  my $self = shift;

  unless ($self->{pict}) {
    carp "Error: you must call plot() once before calling gif()";
    return undef;
  }
  return $self->{pict}->gif;
}

sub cvtcolor ($) {
  my $in = shift || '';
  $in =~ m/^\#[\da-fA-F]{6}$/o || croak "Invalid color '$in'";
  map { hex $_ } ($in =~ m/^\#(..)(..)(..)$/);
}

sub shadecolor ($$$) {
  map { $_ * 0.75 } @_;
}

sub deg2rad ($) {
  my $angle = shift;
  $angle / 180 * 3.141592654;
}

=back

=head1 SEE ALSO

L<perl>, L<GD>

=head1 AUTHOR

Fabien Tassin (fta@oleane.net)

=head1 COPYRIGHT

Copyright 1998, 1999, Fabien Tassin. All rights reserved.
It may be used and modified freely, but I do request that
this copyright notice remain attached to the file. You may
modify this module as you wish, but if you redistribute a
modified version, please attach a note listing the modifications
you have made.

=cut
1;
