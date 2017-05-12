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

package App::Chart::Gtk2::LineStyle::Bars;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);
use List::MoreUtils;
use Math::Round qw(round);
use POSIX ();

# uncomment this to run the ### lines
#use Smart::Comments '###';

use App::Chart::Series;

use constant WIDTH_FRAC => 0.666;

sub x_offset_and_width {
  my ($class, $graph) = @_;
  ### Bars x_offset_and_width()

  my $x_step = $graph->scale_x_step;
  ### $x_step

  # bars 2/3 of step and at least 1 pixel
  # offset rounded down so in 2 pixels the bar is to the left
  my $x_width = max (1, round ($x_step * WIDTH_FRAC));
  return (POSIX::floor (($x_step - $x_width) / 2),
          $x_width);
}

sub draw {
  my ($class, $graph, $series) = @_;
  ### Bars draw()

  my $win   = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $gc    = $graph->style->fg_gc ($graph->state);
  my $ret   = 0;

  my $x_step = $graph->scale_x_step;
  my ($x_offset, $x_width) = $class->x_offset_and_width ($graph);

  my ($lo, $hi) = $graph->draw_t_range;
  ### draw: "lo=$lo hi=$hi of series 0 to ".$series->hi

  $series->fill ($lo, $hi);
  my $values = $series->values_array;

  my $scale_y = $graph->scale_y_proc;
  my $x = $graph->scale_x($lo) + $x_offset;

  my $y_zero = $scale_y->(0);
  $y_zero = max (-1, min ($win_height, $y_zero));
  ### $y_zero

  for (my $t = $lo; $t <= $hi; $t++, $x += $x_step) {
    ### values[t]: $values->[$t]
    my $value = $values->[$t] // next;
    $ret = 1;

    my $y_value = $scale_y->($value);
    #### $value
    #### $y_value

    my ($y_low, $y_high) = List::MoreUtils::minmax ($y_zero, $y_value);
    #### $y_low
    #### $y_high
    next if ($y_high < 0);
    next if ($y_low >= $win_height);

    $y_low = max ($y_low, 0);
    $y_high = min ($y_high, $win_height);

    $win->draw_rectangle ($gc, 1,
                          $x, $y_low,
                          $x_width, $y_high - $y_low + 1);
  }
  ### end: "$hi x=$x"
  return $ret;
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::Bars -- graph drawing of volume style bars
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
# =over 4
# 
# =item C<< App::Chart::Gtk2::LineStyle::Bars->draw ($graph, $series) >>
# 
# ...
# 
# =back
# 
# =cut
