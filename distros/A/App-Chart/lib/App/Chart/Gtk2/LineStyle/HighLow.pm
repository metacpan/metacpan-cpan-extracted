# Copyright 2007, 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::Gtk2::LineStyle::HighLow;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);
use Math::Round qw(round);

use App::Chart;
use App::Chart::Series;

sub draw {
  my ($class, $graph, $series) = @_;

  my $win    = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $gc     = $graph->style->fg_gc ($graph->state);
  my $ret = 0;

  my $x_step = $graph->scale_x_step;
  # bars 2/3 of step and at least 1 pixel
  my $x_width = max (1, round ($x_step * 0.666));
  # centred in step, but preferring the left
  my $x_offset = int (($x_step - $x_width) / 2);

  my ($t_lo, $t_hi) = $graph->draw_t_range();
  my $scale_y = $graph->scale_y_proc();
  my $x = $graph->scale_x($t_lo) + $x_offset - $x_step;

  $series->fill ($t_lo, $t_hi);
  my $values = $series->values_array;
  my $highs  = $series->array('highs') // $values;
  my $lows   = $series->array('lows')  // $values;

  foreach my $t ($t_lo .. $t_hi) {
    $x += $x_step;
    my $high  = $highs->[$t] // $values->[$t];
    next if (! defined $high);
    $ret = 1;
    my $low   = $lows->[$t] // $values->[$t];

    my $y_high = $scale_y->($high);
    my $y_low  = $scale_y->($low);
    if ($y_low > $y_high) { my $t = $y_low; $y_low = $y_high; $y_high = $t; }
    next if ($y_high < 0);
    next if ($y_low >= $win_height);

    $y_low  = max ($y_low, 0);
    $y_high = min ($y_high, $win_height);

    $win->draw_rectangle ($gc, 1, $x, $y_low, $x_width, $y_high - $y_low + 1);
  }
  return $ret;
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::HighLow -- graph drawing of high/low bars
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
# =item C<< App::Chart::Gtk2::LineStyle::HighLow->draw ($graph, $series) >>
# 
# ...
# 
# =back
# 
# =cut
