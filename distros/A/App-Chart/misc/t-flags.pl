#!/usr/bin/perl -w

# Copyright 2008, 2016 Kevin Ryde

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

use strict;
use warnings;
use Glib;
use Gtk2 '-init';

{
  my $w = Gtk2::Window->new ('toplevel');
  my $f = $w->flags;
  print $f,"\n";
  use Data::Dumper;
  print Dumper($f);

  $f += 'sensitive';

  print $f,"\n";
  use Data::Dumper;
  print Dumper($f);

  exit 0;
}

{
  my $f = Glib::ParamFlags->new (['readable']);
  print $f,"\n";
  use Data::Dumper;
  print Dumper($f);

  my $g = $f;
  print $g,"\n";
  print Dumper($g);

  $g += 'writable';
  print $g,"\n";
  print Dumper($g);
}
