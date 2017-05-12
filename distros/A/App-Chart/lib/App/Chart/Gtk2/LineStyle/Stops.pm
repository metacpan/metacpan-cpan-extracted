# Copyright 2006, 2007, 2009, 2011 Kevin Ryde

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

package App::Chart::Gtk2::LineStyle::Stops;
use 5.010;
use strict;
use warnings;
use Gtk2;
use POSIX ();

use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::Series;

use constant DEBUG => 0;

sub draw {
  my ($class, $graph, $series) = @_;
  if (DEBUG) { print "Stops draw\n"; }

  my $win   = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $gc    = App::Chart::Gtk2::GUI::gc_for_colour ($graph, App::Chart::GREY_COLOUR);
  my $ret   = 0;
  my $last_y = -1;

  my $x_step = $graph->scale_x_step;
  my $x_width = $x_step - 1; # full width of column

  my ($lo, $hi) = $graph->draw_t_range;
  if (DEBUG) { print "  draw lo=$lo hi=$hi of series 0 to @{[$series->hi]}\n";}

  $series->fill ($lo, $hi);

  my $scale_y = $graph->scale_y_proc;
  my $x_lo = $graph->scale_x($lo);

  foreach my $arrayname ($series->array_names) {
    my $values = $series->array($arrayname);

    my @segments;
    for (my $t = $lo, my $x = $x_lo;
         $t <= $hi;
         $t++, $x += $x_step) {
      if (defined (my $value = $values->[$t])) {
        $ret = 1;

        my $y = $scale_y->($value);
        if (DEBUG >= 2) { print "  t=$t value=$value y=$y\n"; }
        if ($y >= 0 && $y <= $win_height) {
          if ($y == $last_y) {
            $segments[-2] = $x + $x_width; # extend last entry
          } else {
            push @segments, $x,$y, $x+$x_width,$y;
          }
          next;
        }
      }
      # undef or outside window, don't extend segment
      $last_y = -1;
    }
    if (DEBUG) { local $,=' ', say "  segments", @segments; }
    if (@segments) { # Gtk2 1.220 doesn't allow no segments
      $win->draw_segments ($gc, @segments);
    }
  }
  return $ret;
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::Stops -- graph drawing of stop-loss levels
# 
# =head1 SYNOPSIS
# 
#  # ...
# 
# =head1 DESCRIPTION
# 
# The series values are taken to be stop-loss levels to be drawn as a
# horizontal line segment for each day.
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< App::Chart::Gtk2::LineStyle::Stops->draw ($graph, $series) >>
# 
# ...
# 
# =back
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series::Derived::ParabolicSAR>
# 
# =cut
