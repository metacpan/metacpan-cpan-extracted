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

package App::Chart::Gtk2::Graph::Plugin::Latest;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);
use List::MoreUtils;
use POSIX ();

use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Ex::GtkGCBits;

use base 'App::Chart::Gtk2::Graph::Plugin';
use App::Chart;

use constant DEBUG => 0;

use constant LATEST_COLOUR => 'orange';

# FIXME: do this by getting latest from series or some such
sub _series_want_type {
  my ($series) = @_;
  if ($series->isa('App::Chart::Series::Database')
      || $series->isa('App::Chart::Series::Derived::Adjust')) {
    return 'ohlc';
  } elsif ($series->isa('App::Chart::Series::Derived::Volume')) {
    return 'volume';
  }
}

sub draw {
  my ($class, $graph, $region) = @_;

  my $series_list = $graph->{'series_list'};
  my $series = $series_list->[0] || return;
  my $symbol = $series->symbol || return;
  my $type = _series_want_type($series) || return;

  my $latest = App::Chart::Latest->get($symbol) || return;
  my $timebase = $series->timebase;

  my $hi    = $series->hi;
  my $win   = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $x_step = $graph->scale_x_step;
  my $scale_y = $graph->scale_y_proc;

  my $gc = ($graph->{'latest_gc'} ||= do {
    my ($colour_str, $color_obj)
      = App::Chart::Gtk2::GUI::color_object ($graph, LATEST_COLOUR);
    my $bg_color = $graph->get_style->bg('normal');
    my $xor_color = Gtk2::Gdk::Color->new
      (0,0,0, $color_obj->pixel ^ $bg_color->pixel);

    App::Chart::Gtk2::Ex::GtkGCBits->get_for_widget ($graph, { function   => 'xor',
                                                   foreground => $xor_color });
  });

  $gc->set_clip_region ($region);

  if ($type eq 'ohlc') {

    if (my $quote_date = $latest->{'quote_date'}) {
      my $t = $timebase->from_iso_ceil ($quote_date);
      if ($t > $hi) {
        my $x = $graph->scale_x ($t);
        if (DEBUG) { print "  quote $t ",$timebase->to_iso($t)," x=$x\n"; }
        if ($region->rect_in (Gtk2::Gdk::Rectangle->new
                              ($x, 0, 2 * $x_step, $win_height))
            ne 'out') {

          my $hl_x = $x + POSIX::floor ($x_step/3);
          my $hl_width = max (1, POSIX::floor ($x_step/3));
          foreach my $p ($latest->{'bid'}, $latest->{'offer'}) {
            next if (! defined $p);
            my $y = $scale_y->($p);
            next if ($y < 0 || $y >= $win_height);
            $win->draw_rectangle ($gc, 1,
                                  $hl_x + $hl_width, $y,
                                  POSIX::ceil (1.3*$x_step), 1);
          }
        }
      }
    }

    if (my $last_date = $latest->{'last_date'}) {
      my $t = $timebase->from_iso_floor ($last_date);
      if ($t > $hi) {
        my $x = $graph->scale_x ($t);
        if (DEBUG) { print "  last $t ",$timebase->to_iso($t)," x=$x\n"; }

        my $hl_x = $x + POSIX::floor ($x_step/3);
        my $hl_width = max (1, POSIX::floor ($x_step/3));

        if ($region->rect_in (Gtk2::Gdk::Rectangle->new
                              ($x, 0, $x_step, $win_height)) ne 'out') {
          if (my $p = $latest->{'open'}) {
            my $y = $scale_y-> ($p);
            if ($y >= 0 && $y < $win_height) {
              $win->draw_rectangle ($gc, 1,
                                    $x, $y,
                                    $hl_x - $x, 1);  # to the HL bar
            }
          }
          if (my $ph = $latest->{'high'}) {
            if (my $pl = $latest->{'low'}) {
              my $yh = $scale_y-> ($ph);
              my $yl = $scale_y-> ($pl);
              if ($yl > $yh) { my $tmp = $yl; $yl = $yh; $yh = $tmp; }
              if ($yh >= 0 && $yl < $win_height) {
                $yl = max ($yl, 0);
                $yh = min ($yh, $win_height);
                $win->draw_rectangle ($gc, 1,
                                      $hl_x, $yl,
                                      $hl_width, $yh - $yl + 1);
              }
            }
          }
          if (my $p = $latest->{'last'}) {
            my $y = $scale_y-> ($p);
            if ($y >= 0 && $y < $win_height) {
              $win->draw_rectangle ($gc, 1,
                                    $hl_x + $hl_width, $y,
                                    POSIX::ceil ($x_step * 0.7), 1);
            }
          }
        }
      }
    }

  } else { # $type eq 'volume'

    if (my $last_date = $latest->{'last_date'}) {
      my $t = $timebase->from_iso_floor ($last_date);
      if ($t > $hi) {
        my $x = $graph->scale_x ($t);
        if (DEBUG) { print "  last volume $t ",$timebase->to_iso($t),
                       " x=$x\n"; }
        if ($region->rect_in (Gtk2::Gdk::Rectangle->new
                              ($x,0, $x_step,$win_height)) ne 'out') {
          my $volume = $latest->{'volume'};
          if (defined $volume) {
            my $y_zero = $scale_y->(0);
            my $y_value = $scale_y->($volume);
            my ($y_low, $y_high) = List::MoreUtils::minmax ($y_zero, $y_value);
            if ($y_high >= 0 || $y_low <= $win_height) {

              $y_low = max ($y_low, 0);
              $y_high = min ($y_high, $win_height);

              require App::Chart::Gtk2::LineStyle::Bars;
              my ($x_offset, $x_width)
                = App::Chart::Gtk2::LineStyle::Bars->x_offset_and_width ($graph);

              $win->draw_rectangle ($gc, 1,
                                    $x, $y_low,
                                    $x_width, $y_high - $y_low + 1);
            }
          }
        }
      }
    }

  }

  $gc->set_clip_region (undef);
}

sub vrange {
  my ($class, $graph, $series_list) = @_;
  my $series = $series_list->[0] || return;
  my $symbol = $series->symbol || return;
  my $type = _series_want_type ($series) || return;

  if (DEBUG) { print "Graph Latest '$symbol'\n"; }
  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);
  if ($type eq 'ohlc') {
    return ($latest->{'bid'},
            $latest->{'offer'},
            $latest->{'open'},
            $latest->{'high'},
            $latest->{'low'},
            $latest->{'close'});
  } else {
    return $latest->{'volume'};
  }
}

sub hrange {
  my ($class, $graph, $series_list) = @_;
  my $series = $series_list->[0];
  if (! $series) { return; }
  my $symbol = $series->symbol;
  if (! $symbol) { return; }
  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);
  if (! $latest) { return; }

  my $timebase = $series->timebase;
  my $q = $latest->{'quote_date'};
  my $l = $latest->{'last_date'};
  if (! defined $q && ! defined $l) { return; }

  if (defined $q) { $q = $timebase->from_iso_floor ($q); }
  if (defined $l) { $l = $timebase->from_iso_floor ($l); }

  if (DEBUG) { print "Latest hrange quote ",$q//'undef',
                 " last ",$l//'undef',"\n"; }
  return (App::Chart::min_maybe ($q,$l),
          App::Chart::max_maybe ($q,$l));
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::Graph::Plugin::Latest -- graph drawing of a latest quote
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::Latest;
#  App::Chart::Gtk2::Graph::Plugin::Latest->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
# 
# =cut
