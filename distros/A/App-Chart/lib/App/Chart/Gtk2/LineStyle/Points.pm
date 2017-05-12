# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::LineStyle::Points;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util qw(min max);

use App::Chart::Series;

sub draw {
  my ($class, $graph, $series) = @_;

  my $win   = $graph->window;
  my ($win_width, $win_height) = $win->get_size();
  my $style = $graph->style;
  my $gc    = $style->fg_gc ($graph->state);
  my $ret = 0;

  my $scale_x_step = $graph->scale_x_step;
  #  print "x step $scale_x_step\n";
  # points 1/2 of step wide, but at least 1 pixel
  my $x_diameter = max (1, int ($scale_x_step * 0.5));
  my $y_diameter = max (1, int (widget_x_pixels_to_y_pixels
                                ($graph, $x_diameter)));
  $x_diameter = 1;
  $y_diameter= 1;

  my $y_lo = -$y_diameter;
  my $y_hi = $win_height;
  my ($t_lo, $t_hi) = $graph->draw_t_range();
  my $scale_y = $graph->scale_y_proc;
  my $scale_x = $graph->scale_x_proc;

  $series->fill ($t_lo, $t_hi);
  my $values = $series->values_array;

  if ($x_diameter > 1 || $y_diameter > 1) {
    foreach my $t ($t_lo .. $t_hi) {
      my $value  = $values->[$t];
      if (! defined $value) { next; }

      my $x = $scale_x->($t);
      my $y = $scale_y->($value);
      if ($y <= $y_lo || $y >= $y_hi) { next; }
      # print "$t $value   $x $y\n";

      $win->draw_arc ($gc, 1, $x, $y, $x_diameter, $y_diameter,
                      0, 360*64); # full 360 degree circle
    }

  } else {
    my @array;
    foreach my $t ($t_lo .. $t_hi) {
      my $value  = $values->[$t];
      if (! defined $value) { next; }
      $ret = 1;

      my $x = $scale_x->($t);
      my $y = $scale_y->($value);
      if ($y <= $y_lo || $y >= $y_hi) { next; }

      # print "$t $value   $x $y\n";
      push @array, $x, $y;
    }
    $win->draw_points ($gc, @array);
  }
  return $ret;
}


# =item C<< widget_x_pixels_to_y_pixels ($widget, $x) >>
# 
# Return a pixel count in the y direction which is the same distance as C<$x>
# horizontally.  This uses the aspect ratio of the screen of C<$widget>.  The
# return is a floating point value; you can round it to an integer as desired.
# 
# =cut

sub widget_x_pixels_to_y_pixels {
  my ($widget, $x) = @_;
  my $screen = $widget->get_screen
    or croak 'widget_x_pixels_to_y_pixels(): widget not on a screen yet';
  return $x
    * ($screen->get_width_mm / $screen->get_width)      # x->mm
      * ($screen->get_height_mm / $screen->get_height); # mm->y
}

1;
__END__

# =for stopwords datapoints
# 
# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::Points -- graph drawing of individual datapoints
# 
# =head1 SYNOPSIS
# 
#  # ...
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 FUNCTIONS
# 
# ...
# 
# =cut
