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

package App::Chart::Gtk2::Graph::Plugin;
use strict;
use warnings;

use constant hrange => ();
use constant vrange => ();

sub region_overlaps_column {
  my ($region, $x, $y_lo, $y_hi) = @_;
  return ($region->rect_in
          (Gtk2::Gdk::Rectangle->new ($x,$y_lo, 1,$y_hi - $y_lo))
          ne 'out');
}

1;
__END__
