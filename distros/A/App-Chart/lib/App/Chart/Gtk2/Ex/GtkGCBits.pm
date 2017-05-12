# Copyright 2007, 2008, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::GtkGCBits;
use strict;
use warnings;
use Carp;
use Gtk2;

sub get_for_widget {
  my $class = shift;
  my $widget = shift;
  my $window = $widget->window || croak 'Widget not realized';
  return Gtk2::GC->get ($window->get_depth, $widget->get_colormap, @_);
}

1;
__END__

#   require App::Chart::Gtk2::Ex::GtkGCobj;
#   my $solid_gc = ($graph->{'solid_gc'} ||= App::Chart::Gtk2::Ex::GtkGCobj->new
#                   (widget     => $graph,
#                    foreground => $style->fg ($state),
#                    line_style => 'solid',
#                    line_width => 0));
