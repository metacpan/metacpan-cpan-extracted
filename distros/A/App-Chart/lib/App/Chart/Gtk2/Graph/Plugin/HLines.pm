# Copyright 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::Graph::Plugin::HLines;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);

use base 'App::Chart::Gtk2::Graph::Plugin';
use App::Chart::Gtk2::GUI;

use constant HLINE_COLOUR => App::Chart::GREY_COLOUR;

sub draw {
  my ($class, $graph, $region) = @_;

  my @hlines = map { @{$_->hlines} } @{$graph->{'series_list'}}
    or return;

  my $scale_y_proc = $graph->scale_y_proc;
  my $win   = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $gc = App::Chart::Gtk2::GUI::gc_for_colour_dashed ($graph, HLINE_COLOUR);

  foreach my $p (@hlines) {
    my $y = $scale_y_proc->($p);
    ### hline
    ### $p
    ### $y

    if ($y < 0 || $y >= $win_height
        || $region->rect_in (Gtk2::Gdk::Rectangle->new (0,$y, $win_width,1))
        eq 'out') {
      next;
    }
    $win->draw_line ($gc, 0,$y, $win_width-1,$y);
  }
}

sub hrange {
  my ($class, $graph, $series_list) = @_;
  my $series = $series_list->[0];
  if (! $series) { return; }
  my $symbol = $series->symbol;
  if (! $symbol) { return; }

  require App::Chart::TZ;
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
# App::Chart::Gtk2::Graph::Plugin::HLines -- graph drawing of horizontal lines
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::HLines;
#  App::Chart::Gtk2::Graph::Plugin::HLines->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
# 
# =cut
