# Copyright 2010 Kevin Ryde

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


package App::Chart::Gtk2::Ex::GdkRectangleBits;
use 5.010;
use strict;
use warnings;
use Gtk2;

# return true if Gtk2::Gdk::Rectangle's $r1 and $r2 are equal, ie. have
# identical x,y,width,height
sub is_equal {
  my ($r1, $r2) = @_;
  return $r1->x == $r2->x
    && $r1->y == $r2->y
      && $r1->width == $r2->width
        && $r1->height == $r2->height;
}

# return a new Gtk2::Gdk::Rectangle which is the intersection of $rect with
# $region, or return undef if no intersection at all
sub rect_intersect_region {
  my ($rect, $region) = @_;
  if ($region->rect_in ($rect) eq 'out') { return undef; }

  $region = $region->copy;
  $region->intersect (Gtk2::Gdk::Region->rectangle ($rect));
  return $region->get_clipbox;
}

1;
__END__
