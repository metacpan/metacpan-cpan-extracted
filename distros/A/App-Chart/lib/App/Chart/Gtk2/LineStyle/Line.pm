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

package App::Chart::Gtk2::LineStyle::Line;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);
use POSIX ();

use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Ex::LineClipper;

use constant DEBUG => 0;

sub draw {
  my ($class, $graph, $series) = @_;
  if (DEBUG) { say "LineStyle::Line draw $graph $series"; }

  my $win   = $graph->window;
  my $ret = 0;

  my $x_step = $graph->scale_x_step;
  my $x_offset = POSIX::floor ($x_step / 2);  # centred in step

  my ($lo, $hi) = $graph->draw_t_range;
  $series->fill ($lo, $hi);

  # go to the next value before and after the visible window, so as to show
  # lines going away off the window (esp if a big gap)
  $lo = $series->find_before ($lo, 1);
  $hi = $series->find_after ($hi, 1);

  my $scale_y = $graph->scale_y_proc;
  my $draw = App::Chart::Gtk2::Ex::LineClipper->new (drawable => $win);
  my $initial_x = $graph->scale_x($lo) + $x_offset;

  foreach my $arrayname ($series->array_names) {
    my $values = $series->array($arrayname);

    my $colour_name = ($series->can('line_colours')
                       ? $series->line_colours->{$arrayname}
                       : undef);
    my ($solid_gc, $dash_gc);
    if (($colour_name//'') eq 'solid') { # hack for ZigZag
      $solid_gc = $dash_gc = App::Chart::Gtk2::GUI::gc_for_colour ($graph, undef);
    } else {
      $solid_gc = App::Chart::Gtk2::GUI::gc_for_colour ($graph, $colour_name);
      $dash_gc = App::Chart::Gtk2::GUI::gc_for_colour_dashed ($graph, $colour_name);
    }

    if (DEBUG) { local $,=' ';
                 say "Line values ",
                   map {$_//'undef'} @{$values}[$lo .. $hi]; }

    my $x = $initial_x;
    my $value;
    my $gc = $solid_gc;
    for (my $t = $lo; $t <= $hi; $t++, $x += $x_step) {
      $value = $values->[$t];
      if (defined $value) {
        $ret = 1;
        $draw->add ($gc, $x, $scale_y->($value));
        $gc = $solid_gc;
      } else {
        $gc = $dash_gc;
      }
    }
    $draw->end;
  }
  return $ret;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::LineStyle::Line -- graph drawing of plain lines
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
# =item C<< App::Chart::Gtk2::LineStyle::Line->draw ($graph, $series) >>
# 
# ...
# 
# =back
# 
# =cut
