# Copyright 2007, 2008, 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::GdkColorAlloc;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util 1.18 'refaddr'; # 1.18 for pure-perl refaddr() fix
use base 'Gtk2::Gdk::Color';

# uncomment this to run the ### lines
#use Smart::Comments;


# %color_to_colormap is keyed by the address of a
# App::Chart::Gtk2::Ex::GdkColorAlloc object (refaddr()) and the value is
# the Gtk2::Colormap the pixel is allocated in.
#
# This is "instance data", but because Glib::Boxed, and therefore
# Gtk2::Gdk::Color, is only a reference to a scalar there's no room to hang
# extra data like this.
#
# %color_to_colormap is meant to be private, but it's an "our" so you can
# have a peek at it during development, for instance to know how many
# colours you've allocated, or whatnot.  But don't depend on it staying in
# its present form!
#
our %color_to_colormap = ();

sub new {
  my ($class, %param) = @_;

  # when called with more than one of 'colormap', 'window', 'widget' then
  # the idea is roughly to have an explicit 'colormap' trump a 'widget' or
  # 'window' parameter, and a window to trump a widget, but there's actually
  # no good reason for passing more than one of those three
  #
  my $colormap = delete $param{'colormap'};
  if (my $widget = delete $param{'widget'}) {
    $colormap ||= $widget->get_colormap;
  }
  if (my $window = delete $param{'window'}) {
    $colormap ||= $window->get_colormap;
  }
  if (! $colormap) {
    croak 'GdkColorAlloc: none of colormap/widget/window arguments given';
  }

  if (! exists $param{'color'}) {
    croak 'GdkColorAlloc: color argument not given';
  }
  my $color = delete $param{'color'};
  if (ref $color) {
    # Gtk2::Gdk::Color object -- copy so as not to modify the caller's object
    $color = $color->copy;
  } else {
    # string colour name
    my $parsed_color = Gtk2::Gdk::Color->parse ($color);
    if (! $parsed_color) {
      croak "GdkColorAlloc: cannot parse colour \"$color\"";
    }
    $color = $parsed_color;
  }

  my $writable = delete $param{'writable'};
  my $best_match
    = (exists $param{'best_match'}  ? delete $param{'best_match'}  : 1);
  my $raise_error
    = (exists $param{'raise_error'} ? delete $param{'raise_error'} : 1);

  # check remaining args before doing the alloc, so we don't leak an
  # allocated cell if we croak
  if (%param) {
    croak "GdkColorAlloc: unrecognised parameter(s): " . join(',', keys %param);
  }

  if (! $colormap->alloc_color ($color, $writable, $best_match)) {
    if ($raise_error) {
      croak 'GdkColorAlloc: cannot allocate colour cell';
    } else {
      return undef;
    }
  }

  my $self = bless $color, $class;  # rebless
  $color_to_colormap{refaddr($self)} = $colormap;

  ### added to color_to_colormap: \%color_to_colormap
  return $self;
}

sub alloc_color {
  my ($class, $colormap, $color, $writable, $best_match) = @_;
  if (@_ < 4) { $best_match = 1; }

  if (ref $color) {
    # Gtk2::Gdk::Color object -- copy so as not to modify the caller's object
    $color = $color->copy;
  } else {
    # string colour name
    my $parsed_color = Gtk2::Gdk::Color->parse ($color)
      or croak "App::Chart::Gtk2::Ex::GdkColorAlloc->new: cannot parse colour \"$color\"";
    $color = $parsed_color;
  }

  $colormap->alloc_color ($color, $writable, $best_match)
    or croak 'GdkColorAlloc: cannot allocate colour cell';

  my $self = bless $color, $class;  # rebless
  $color_to_colormap{refaddr($self)} = $colormap;
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  if (my $colormap = delete $color_to_colormap{refaddr($self)}) {
    $colormap->free_colors ($self);
  }
  ### DESTROY leaves color_to_colormap: \%color_to_colormap
  $self->SUPER::DESTROY;
}

sub colormap {
  my ($self) = @_;
  ### in color_to_colormap: \%color_to_colormap
  return $color_to_colormap{refaddr($self)};
}


1;
__END__

=for stopwords colormap GdkColorAlloc TrueColor PseudoColor Gtk GC Eg ie alloc undef

=head1 NAME

App::Chart::Gtk2::Ex::GdkColorAlloc -- object for allocated colormap cell

=for test_synopsis my ($my_widget, $my_gc)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::GdkColorAlloc;
 my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (widget => $my_widget,
                                                       color => 'red');
 $my_gc->set_foreground ($color);

 $color = undef;  # cell freed when destroyed

=head1 CLASS HIERARCHY

C<App::Chart::Gtk2::Ex::GdkColorAlloc> is a Perl subclass of C<Gtk2::Gdk::Color>

    Glib::Boxed
      Gtk2::Gdk::Color
        App::Chart::Gtk2::Ex::GdkColorAlloc

=head1 DESCRIPTION

A GdkColorAlloc object represents a colour cell allocated in a particular
C<Gtk2::Gdk::Colormap>.  When the GdkColorAlloc object is destroyed the cell
is freed.

GdkColorAlloc is a subclass of C<Gtk2::Gdk::Color> and can be used
everywhere such a colour object can be used, for instance setting a pixel
value in a C<Gtk2::Gdk::GC> for some drawing.

GdkColorAlloc object allocates a cell using
C<< Gtk2::Gdk::Colormap->alloc_color >>, and when the object is garbage
collected it calls C<< Gtk2::Gdk::Colormap->free_colors >> to free that
cell.  This means you can just forget the object when you don't need the
colour any more, without an explicit free.

Whether you actually need this depends on how you use your colours.  You
might be happy with the C<Gtk2::Gdk::Rgb> system.  Or if you allocate at the
start of a program and never change then freeing doesn't matter.  Or if you
only care about TrueColor visuals then colours are fixed and there's nothing
to free.  But for 8-bit PseudoColor with cells released on widget
destruction or colour scheme changes then C<GdkColorAlloc> is good.
(Despite the fact Cairo versions circa 1.4 broke most Gtk programs on 8-bit
displays.)

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::GdkColorAlloc->new (key => value, ...) >>

Allocate a colour cell and return a C<App::Chart::Gtk2::Ex::GdkColorAlloc> object
representing that cell.  The object will have the C<pixel> field set ready
for use in a GC or similar.  Eg.

    my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (color => 'red',
                                              widget => $my_widget);
    $my_gc->set_foreground ($color);

The following key parameters are accepted,

    color        Gtk2::Gdk::Color object, or string name
    colormap     Gtk2::Gdk::Colormap object
    widget       Gtk2::Widget, to use its colormap
    window       Gtk2::Gdk::Window, to use its colormap
    writable     boolean, ask for a writable cell (default 0)
    best_match   boolean, get closest matching colour (default 1)
    raise_error  boolean, croak() on error (default 1)

The most basic call is just with C<color> and C<colormap>, to ask for a
non-writable (ie. shared) best-match colour.  C<color> can be either a
string colour name to be parsed by C<< Gtk2::Gdk::Color->parse >>, or a
C<Gtk2::Gdk::Color> object with C<red>/C<green>/C<blue> fields set (which is
copied so the object you pass is unmodified).

    my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (colormap => $my_cmap,
                                              color => 'red');

    my $rgb = Gtk2::Gdk::Color->new (0x7F00, 0x0000, 0x0000);
    my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (color => $rgb,
                                              colormap => $my_cmap);

If you want a colour cell for use in a C<Gtk2::Widget> or
C<Gtk2::Gdk::Window>, then you can pass that to have its colormap used.

    my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (widget => $my_widget,
                                              color => 'blue');

    my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (window => $my_win,
                                              color => 'purple');

The C<writable> and C<best_match> options are passed on to
C<< $colormap->alloc_color >> (see L<Gtk2::Gdk::Colormap>).  The default is
C<writable> false and C<best_match> true.  If you change that then the
alloc can fail.  The default is to C<croak> on failure, but C<raise_error>
can be set to false to return undef instead.  Eg.

    my $color = App::Chart::Gtk2::Ex::GdkColorAlloc->new (widget => $my_widget,
                                              color => 'yellow',
                                              writable => 1,
                                              raise_error => 0);
    if (! $color) {
      print "cannot allocate writable colour\n";
    }

=item C<< $color->colormap >>

Return the C<Gtk2::Gdk::Colormap> in which C<$color> is allocated.

A GdkColorAlloc object keeps a reference to its colormap, so the colormap
will remain alive for as long as there's a GdkColorAlloc object using it.

=back

=head1 OTHER NOTES

Each C<< $colormap->alloc_color >> does a round-trip to the X server, which
may be slow if you've got thousands of colours to allocate.  An equivalent
to the mass-allocation of C<alloc_colors> or the plane-oriented
C<gdk_colors_alloc> would be wanted for big colour sets, but chances are if
you're working with thousands of colours you'll want a pattern in the pixel
values and so would be getting a private colormap anyway where the niceties
of cross-program sharing with allocate and free don't apply.

=head1 SEE ALSO

L<Gtk2::Gdk::Color>, L<Gtk2::Gdk::Colormap>

=cut

