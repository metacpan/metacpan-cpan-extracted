# wrong angle on coming back after multiple skipped off screen, Kirshenbaum BHP



# x1,y1 x2,inf -> x1,y1

# x1,-inf x2,inf -> mean x1,x2

# x1,y1 inf,inf -> 45deg to corner

# x1,-inf inf,inf -> mean is inf, offscreen


# segments drawing with clip, for annotation lines




# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Gtk2::Ex::LineClipper;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util qw(min max);

use constant DEBUG => 0;

sub new {
  my ($class, %self) = @_;

  if (! exists $self{'drawable'}) {
    croak "Missing drawable for LineClipper";
  }

  # default yes for draw_points
  if (! exists $self{'draw_points'}) {
    $self{'draw_points'} = 1;
  }

  $self{'points'} = [];
  return bless \%self, $class;
}

sub add {
  my ($self, $gc, $x, $y) = @_;
  my $points = $self->{'points'};

  # if the next segment is a new gc and there's more than a single point,
  # then draw the previous segments with the previous gc
  if (@$points > 2 && $gc != $self->{'gc'}) {
    my $x1 = $points->[-2];
    my $y1 = $points->[-1];
    $self->end;
    @$points = ($x1, $y1, $x, $y);
  } else {
    push @$points, $x, $y;
  }
  $self->{'gc'} = $gc;
}

sub end {
  my ($self) = @_;

  my $points = $self->{'points'};
  if (! @$points) {
    # nothing to draw at all
    return
  }

  if (@$points == 2 && ! $self->{'draw_point'}) {
    # only a single point, and single point drawing not wanted
    @$points = ();
    return;
  }

  clipped_draw_lines ($self->{'drawable'},
                      $self->{'gc'},
                      max (1, $self->{'line_width'} || 1),
                      $points);
  @$points = ();
}

sub clipped_draw_lines {
  my ($drawable, $gc, $line_width,  $points) = @_;

  my ($width, $height) = $drawable->get_size;
  my $clip_x_low  = 0 - $line_width;
  my $clip_x_high = $width + $line_width;
  my $clip_y_low  = 0 - $line_width;
  my $clip_y_high = $height + $line_width;

  if (@$points == 2) {
    # single point
    my $x = $points->[0];
    my $y = $points->[1];
    if (DEBUG) { print "point $x,$y $line_width\n"; }
    if ($x < $clip_x_low || $x > $clip_x_high
        || $y < $clip_y_low || $y > $clip_y_high) {
      # outside the drawable, do nothing
      return;
    }

    if ($line_width <= 1) {
      $drawable->draw_point ($gc, $x, $y);
    } else {
      my $offset = int ($line_width / 2); # round down
      $drawable->draw_arc ($gc, 1,
                           $x - $offset, $y - $offset,
                           $line_width, $line_width,
                           0, 23040); # 360*64 for full circle
    }
    return;
  }

  if (DEBUG) { print "draw $gc ", scalar(@$points), " coords\n"; }

  my @draw = ();
  my $x1 = $points->[0];
  my $y1 = $points->[1];

  for (my $i = 2; $i+1 <= $#$points; $i += 2) {
    my $x2 = $points->[$i];
    my $y2 = $points->[$i+1];

    if (   ($x1 <= $clip_x_low  && $x2 <= $clip_x_low)
        || ($x1 >= $clip_x_high && $x2 <= $clip_x_high)) {
      if (DEBUG) { print "  X coords outside drawable, skip: $x1 $x2\n"; }
      $x1 = $x2;
      $y1 = $y2;
      next;
    }

    my $end_clipped = 0;

    if ($x1 <= $clip_x_low && $x2 > $clip_x_low) {
      $y1 = ($y1 * ($x2 - $clip_x_low) + $y2 * ($clip_x_low - $x1))
            / ($x2 - $x1);
      $x1 = $clip_x_low;
    } elsif ($x2 <= $clip_x_low && $x1 > $clip_x_low) {
      $y2 = ($y2 * ($x1 - $clip_x_low) + $y1 * ($clip_x_low - $x2))
            / ($x1 - $x2);
      $x2 = $clip_x_low;
      $end_clipped = 1;
    }

    if ($x1 <= $clip_x_high && $x2 > $clip_x_high) {
      $y2 = ($y2 * ($x1 - $clip_x_high) + $y1 * ($clip_x_high - $x2))
            / ($x1 - $x2);
      $x2 = $clip_x_high;
      $end_clipped = 1;
    } elsif ($x2 <= $clip_x_high && $x1 > $clip_x_high) {
      $y1 = ($y1 * ($x2 - $clip_x_high) + $y2 * ($clip_x_high - $x1))
            / ($x2 - $x1);
      $x1 = $clip_x_high;
    }

    if (   ($y1 <= $clip_y_low  && $y2 <= $clip_y_low)
        || ($y1 >= $clip_y_high && $y2 >= $clip_y_high)) {
      if (DEBUG) { print "  Y coords outside drawable, skip: $y1 $y2\n"; }
      $x1 = $x2;
      $y1 = $y2;
      next;
    }

    if ($y1 <= $clip_y_low && $y2 > $clip_y_low) {
      $x1 = ($x1 * ($y2 - $clip_y_low) + $x2 * ($clip_y_low - $y1))
            / ($y2 - $y1);
      $y1 = $clip_y_low;
    } elsif ($y2 <= $clip_y_low && $y1 > $clip_y_low) {
      $x2 = ($x2 * ($y2 - $clip_y_low) + $x1 * ($clip_y_low - $y1))
            / ($y2 - $y1);
      $y2 = $clip_y_low;
      $end_clipped = 1;
    }

    if ($y1 <= $clip_y_high && $y2 > $clip_y_high) {
      $x2 = ($x2 * ($y2 - $clip_y_high) + $x1 * ($clip_y_high - $y1))
            / ($y2 - $y1);
      $y2 = $clip_y_high;
      $end_clipped = 1;
    } elsif ($y2 <= $clip_y_high && $y1 > $clip_y_high) {
      $x1 = ($x1 * ($y2 - $clip_y_high) + $x2 * ($clip_y_high - $y1))
            / ($y2 - $y1);
      $y1 = $clip_y_high;
    }

    if (! @draw) {
      push @draw, $x1, $y1;
    }
    push @draw, $x2, $y2;
    if ($end_clipped) {
      if (DEBUG) { print "  end clipped, draw ", join(' ', @draw), "\n"; }
      $drawable->draw_lines ($gc, @draw);
      @draw = ();
    }
    $x1 = $x2;
    $y1 = $y2;
  }
  if (DEBUG) { print "  final draw ", join(' ', @draw), "\n"; }
  if (@draw) {
    $drawable->draw_lines ($gc, @draw);
  }
}

sub DESTROY {
  my ($self) = @_;
  $self->end;
}



1;
__END__

=for stopwords Gdk pixmap Eg GC LineClipper ie GCs

=head1 NAME

App::Chart::Gtk2::Ex::LineClipper -- accumulate and/or draw connected line segments

=for test_synopsis my ($drawable, $gc, $line_width, $points_list, $x1, $y1, $x2, $y2)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::LineClipper;

 # direct draw
 App::Chart::Gtk2::Ex::LineClipper::clipped_draw_lines
     ($drawable, $gc, $line_width, $points_list);

 # OOP accumulator
 my $linedrawer = App::Chart::Gtk2::Ex::LineClipper->new (drawable => $drawable);
 $linedrawer->add ($gc, $x1, $y1);
 $linedrawer->add ($gc, $x2, $y2);
 $linedrawer->end;

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::LineClipper> helps you draw connected line segments like
C<< Gtk2::Drawable->draw_lines >> does, but with benefits of clipping wild
coordinates (and not even sent to the server if not visible), and an
accumulator mechanism to build line sequences.

Clipping wild X,Y values on the client side is important because Gdk
silently takes just the low 16 bits of each.  For example if you draw a line
from 100,50 to 65736,50 you'll be unpleasantly surprised to find X=65736
comes out as X=200 (its low 16 bits), instead of extending to the far right
hand end of the window.

The object-oriented accumulator is helpful if you've got a tricky loop
generating points and colours for each segment and want someone else to keep
track of what, if anything, you build up to draw.

=head1 DIRECT DRAWING

=over 4

=item C<< App::Chart::Gtk2::Ex::LineClipper::clipped_draw_lines ($drawable, $gc, $line_width, $points) >>

Draw lines connecting the X,Y points in C<$points>, like
C<Gtk2::Drawable::draw_lines> does, but clipping to the size of the drawable
so huge coordinate values don't wrap around, and indeed are not sent to the
server at all if completely off-screen.

C<$points> is a reference to an array of X,Y values, one after the other.
C<$drawable> is a C<Gtk2::Gdk::Drawable> (window, pixmap, etc) and C<$gc> is
a C<Gtk2::Gdk::GC>.  Eg.

    App::Chart::Gtk2::Ex::LineClipper::clipped_draw_lines
        ($drawable, $gc, 1, [ 100,100, 200,200, 300,100 ]);

C<$line_width> should be the width in pixels of the lines C<$gc> will draw.
This is used to know how far off the drawable the clipping must extend so
the C<cap_style> doesn't show.  C<clipped_draw_lines> doesn't simply read
C<$line_width> from C<< $gc->get_values >> because that call does a
round-trip to the X server.  A width bigger than actually in use is fine;
for instance you might just pass 20 pixels if you know you never draw lines
wider than that.  A width 0 is interpreted as a 1 pixel "thin line", the
same as happens in the GC.

If C<$points> is an empty array, or an array of just one X,Y point, then
nothing at all is drawn.  This handling of one point adds certainty to what
plain C<< $win->draw_lines >> does; for it a single X,Y of a 0-width "thin
line" might or might not be drawn, depending on the server.

=back

=head1 ACCUMULATOR OBJECT

=over 4

=item C<< App::Chart::Gtk2::Ex::LineClipper->new (drawable => $drawable, ...) >>

Create and return a new LineClipper object to accumulate and draw connected
line segments on C<$drawable> using C<clipped_draw_lines> above.
C<$drawable> is a C<Gtk2::Gdk::Drawable> object as above, and a
C<line_width> parameter can be passed to set that for the clipping (again as
above).

    my $linedrawer = App::Chart::Gtk2::Ex::LineClipper->new
                         (drawable => $drawable,
                          line_width => 5); # pixels

By default a single solitary X,Y point is not drawn, on the principle that
it's not a line segment, but the C<draw_point> option can be set true to
have it shown as a circle of the given C<line_width>.  Eg.

    my $linedrawer = App::Chart::Gtk2::Ex::LineClipper->new
                         (drawable => $drawable,
                          line_width => 5,  # pixels
                          draw_point => 1); # true

If you're wondering that C<line_width> used as a diameter won't come out
circular if the pixels aren't square, well, yes, but the same is true of the
line drawing.  The single width used vertically and horizontally for the
line segments makes them appear wider or narrower according to their angle.

=item C<< $linedrawer->add ($gc, $x, $y) >>

Add a point to C<$linedrawer>.  The points accumulated will have connected line
segments drawn from each to the next, in the order they're added.

C<$gc> is a C<Gtk2::Gdk::GC> for the new segment, ie. from the current
endpoint to the new C<$x>,C<$y>.  Different GCs can be used for different
segments and the LineClipper takes care of passing runs of the same GC to
C<clipped_draw_lines>.

=item C<< $linedrawer->end() >>

Draw the line segments accumulated, if any, and set C<$linedrawer> back to
empty, ready to start a new completely separate sequence of points.

You can use this to force a gap between points, ie. draw everything
accumulated so far and make subsequent points a new run.

C<end> is called automatically when C<$linedrawer> is destroyed, which means
that if you've got a complicated loop generating the points then you can
just C<return> or jump out from multiple places, confident that letting the
LineClipper go out of scope will flush what you've accumulated.

=back

=head1 OTHER NOTES

The choice between the direct C<clipped_draw_lines> and the accumulator
object is purely a matter of convenience.  If you've got all your values in
an array and want to draw just one colour (one GC) then the best idea is to
C<map> or whatever to scale and build an X,Y array, then call
C<clipped_draw_lines>.  But if you're going to make decisions about skipping
some points or changing colours or leaving gaps while passing over the data
then you may find the accumulator easier.

When switching to a different GC with C<add>, the join between the lines in
the old and new GCs doesn't use the join style (C<Gtk2::Gdk::JoinStyle>) of
either GC, but rather merely gets the cap style (C<Gtk2::Gdk::CapStyle>) of
each where the C<draw_lines> from one ends and the other begins.  This means
you can't get a nice mitre or bevel when changing colours etc.  For now it
seems far too much trouble to try to do anything about that.  The suggestion
would be to use a cap style of C<round> which comes out looking nice at any
angle.  Or if you only do GC switching with lines a few pixels wide then one
or two slightly off where they meet will be hardly noticeable.

=head1 SEE ALSO

L<Gtk2::Gdk::Drawable>, L<Gtk2::Gdk::GC>, L<Gtk2::Ex::WidgetBits>

=cut
