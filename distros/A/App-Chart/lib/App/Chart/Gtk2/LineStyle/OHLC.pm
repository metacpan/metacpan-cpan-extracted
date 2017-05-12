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

package App::Chart::Gtk2::LineStyle::OHLC;
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

  # FIXME: clip to window height in case wild scaling ...

  my $win    = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $ret = 0;

  my $solid_gc = App::Chart::Gtk2::GUI::gc_for_colour ($graph, undef);
  my $dash_gc  = App::Chart::Gtk2::GUI::gc_for_colour_dashed ($graph, undef);

  my $x_step = $graph->scale_x_step;

  my $open_offset = 0;
  my $open_width = POSIX::ceil ($x_step * 0.5);

  my $close_width = $open_width;
  my $close_offset = $x_step - $close_width;

  my $hl_width  = max(1, int ($x_step * 0.25));
  my $hl_offset = int (($x_step - $hl_width) / 2);

  # line segments centred in step
  my $line_offset = int ($x_step / 2);

  #   if (DEBUG) {
  #     print "shadow $hl_width at $shadow_offset\n";
  #     print "body $body_width at $body_offset\n";
  #   }

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
    if (! defined $open && ! defined $high && ! defined $low) {
      $draw->add (defined $prev ? $solid_gc : $dash_gc,
                  $x + $line_offset, $y_close);
    } else {
      $draw->end;

      if (defined $open) {
        my $y = $scale_y->($open);
        $win->draw_rectangle ($solid_gc, 1,
                              $x + $open_offset, $y,
                              $open_width, 1);
        $ret = 1;
      }

      if (defined $close) {
        $win->draw_rectangle ($solid_gc, 1,
                              $x + $close_offset, $y_close,
                              $close_width, 1);
        $ret = 1;
      }

      if (defined $high && defined $low) {
        my $y_high = $scale_y->($high);
        my $y_low  = $scale_y->($low);
        $win->draw_rectangle ($solid_gc, 1,
                              $x + $hl_offset, min ($y_low, $y_high),
                              $hl_width, abs($y_low - $y_high) + 1);
        $ret = 1;
      } elsif (defined $high || defined $low) {
        my $y = $scale_y->($high // $low);
        $win->draw_rectangle ($solid_gc, 1,
                              $x + $hl_offset, $y,
                              $hl_width, 1);
        $ret = 1;
      }
    }
    $prev = $close;
  }
  return $ret;
}

1;
__END__

# =for stopwords OHLC
# 
# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::OHLC -- graph drawing of OHLC figures
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
# =item C<< App::Chart::Gtk2::LineStyle::OHLC->draw ($graph, $series) >>
# 
# ...
# 
# =back
# 
# =cut
