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

package App::Chart::Gtk2::Graph::Plugin::Today;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);

use base 'App::Chart::Gtk2::Graph::Plugin';
use App::Chart::Gtk2::GUI;
use App::Chart::TZ;

use constant TODAY_COLOUR => App::Chart::GREY_COLOUR;

sub draw {
  my ($class, $graph, $region) = @_;

  my $series_list = $graph->{'series_list'};
  my $series = $series_list->[0] || return;
  my $symbol = $series->symbol || return;

  my $timezone = App::Chart::TZ->for_symbol ($symbol);
  my $timebase = $series->timebase;
  my $today = $timebase->today ($timezone);
  my $win   = $graph->window;
  my ($win_width, $win_height) = $win->get_size;

  # next column after today's, and 1 pixel gap
  my $x = 1 + $graph->scale_x ($today + 1);
  ### today t: $today
  ### iso: $timebase->to_iso($today)
  ### $x

  if ($x < 0 || $x >= $win_width
      || $region->rect_in (Gtk2::Gdk::Rectangle->new ($x,0, 1,$win_height))
      eq 'out') {
    return;
  }

  my $dash_gc = App::Chart::Gtk2::GUI::gc_for_colour_dashed ($graph, TODAY_COLOUR);
  $win->draw_line ($dash_gc, $x,0, $x,$win_height-1);
}

sub hrange {
  my ($class, $graph, $series_list) = @_;
  my $series = $series_list->[0] || return;
  my $symbol = $series->symbol || return;

  my $timezone = App::Chart::TZ->for_symbol ($symbol);
  my $timebase = $series->timebase;

  my $upper = max (map {$_->hi} @$series_list);
  my $today = $timebase->today ($timezone);
  if ($today - $upper >= 14) {
    return;
  }
  return ($today, $today);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::Graph::Plugin::Today -- graph drawing of a dashed line at today
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::Today;
#  App::Chart::Gtk2::Graph::Plugin::Today->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
# 
# =cut
