# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Gtk2::Ex::WidgetBits;
use 5.010;
use strict;
use warnings;

# allowing gtk pre-2.12...
#
sub error_bell {
  my ($widget) = @_;
  my $display;

  if (! Gtk2::Widget->can('get_screen')) {
    return;
  }

  # actually the 2.12 one doesn't beep if the widget has no display
  if ($widget && $widget->has_screen) {
    if ($widget->can('error_bell')) {
      $widget->error_bell;
      return;
    }
    if ($widget->can('get_display')) {
      $display->beep;
      return;
    }
  }

  # Gtk 2.0.x or widget without a screen
  Gtk2::Gdk->beep;
}

1;
__END__
