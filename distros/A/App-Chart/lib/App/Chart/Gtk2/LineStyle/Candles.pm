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

package App::Chart::Gtk2::LineStyle::Candles;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);

use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Ex::LineClipper;

use constant DEBUG => 0;

sub draw {
  my ($class, $graph, $series) = @_;

  my $win    = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $ret = 0;

  my $solid_gc = App::Chart::Gtk2::GUI::gc_for_colour ($graph, undef);
  my $dash_gc  = App::Chart::Gtk2::GUI::gc_for_colour_dashed ($graph, undef);
  my $up_gc   = App::Chart::Gtk2::GUI::gc_for_colour($graph,App::Chart::UP_COLOUR);
  my $down_gc = App::Chart::Gtk2::GUI::gc_for_colour($graph,App::Chart::DOWN_COLOUR);

  my $x_step = $graph->scale_x_step;

  # body is 3/4 of step and shadow 1/4
  # shadow at least 1 pixel, and body try to be 3 times shadow
  my $shadow_width  = max(1, int ($x_step / 4));
  my $body_width = min ($x_step, $shadow_width * 3);

  # centred in step, and on the left if odd number of pixels
  my $body_offset = int (($x_step - $body_width) / 2);
  # centred in body, and on the left if odd number of pixels
  my $shadow_offset = $body_offset + int (($body_width - $shadow_width) / 2);

  # line segments centred in step
  my $line_offset = int ($x_step / 2);

  if (DEBUG) {
    print "shadow $shadow_width at $shadow_offset\n";
    print "body $body_width at $body_offset\n";
  }

  my ($lo, $hi) = $graph->draw_t_range;
  my $scale_y = $graph->scale_y_proc;
  if (DEBUG) { print "candles: draw $lo to $hi of series 0 to ",
                 $series->hi, "\n"; }

  $series->fill ($lo, $hi);
  my $opens  = $series->array('opens') // [];
  my $highs  = $series->array('highs') // [];
  my $lows   = $series->array('lows')  // [];
  my $closes = $series->array('closes') // $series->values_array;

  # go to the next value before and after the visible window in case we're
  # showing just lines there, to get going away off the window
  $lo = $series->find_before ($lo, 1);
  $hi = $series->find_after ($hi, 1);

  if (DEBUG) { print " extra at ends is $lo to $hi  ",
                 $series->timebase->to_iso($lo)," to ",
                   $series->timebase->to_iso($hi),"\n"; }

  my $x = $graph->scale_x ($lo);
  my $draw = App::Chart::Gtk2::Ex::LineClipper->new (drawable => $win,
                                                     draw_point => 1);
  my $prev;
  my $close;
  for (my $t = $lo; $t <= $hi; $t++, $x += $x_step, $prev = $close) {
    $close = $closes->[$t] // next;
    $ret = 1;
    my $open   = $opens->[$t];
    my $high   = $highs->[$t];
    my $low    = $lows->[$t];

    my $y_close = $scale_y->($close);
    if (! defined $open || ! defined $high || ! defined $low) {
      $draw->add (defined $prev ? $solid_gc : $dash_gc,
                  $x + $line_offset, $y_close);
    } else {
      $draw->end;

      my $y_open = $scale_y->($open);
      my $y_high = $scale_y->($high);
      my $y_low  = $scale_y->($low);

      my $gc = ($close > $open    ? $up_gc
                : $close == $open ? $solid_gc
                :                   $down_gc);

      # high/low should be the right way around from the database, but swap
      # if necessary to ensure we don't pass a bad height to the server
      if ($y_low > $y_high) {
        my $tmp = $y_low; $y_low = $y_high; $y_high = $tmp;
      }

      # swap to make the "open" the low Y
      if ($y_open > $y_close) {
        my $tmp = $y_open; $y_open = $y_close; $y_close = $tmp;
      }

      if ($y_high >= 0 && $y_low < $win_height) {
        $y_low  = max ($y_low, 0);
        $y_high = min ($y_high, $win_height);
        $win->draw_rectangle ($gc, 1,
                              $x + $shadow_offset, $y_low,
                              $shadow_width, $y_high - $y_low + 1);
      }

      if ($y_close >= 0 && $y_open < $win_height) {
        $y_open  = max ($y_open, 0);
        $y_close = min ($y_close, $win_height);
        $win->draw_rectangle ($gc, 1,
                              $x + $body_offset, $y_open,
                              $body_width, $y_close - $y_open + 1);
      }

    }
  }
  return $ret;
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::Candles -- graph drawing of Japanese candlesticks
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
# =item C<< App::Chart::Gtk2::LineStyle::Candles->draw ($graph, $series) >>
# 
# ...
# 
# =back
# 
# =cut
