#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use lib::abs '.';
use MyExtractUse;
use Data::Dumper;

my @used = MyExtractUse->from_string (<<'HERE');


package MyNewFilterModel;
use strict;
use warnings;
use Gtk2;
use base 'Gtk2::Ex::TreeModelFilter::Change';
use Glib::Object::Subclass
  'Gtk2::TreeModelFilter';

HERE
print Data::Dumper->new([\@used],['used'])->Sortkeys(1)->Dump;

exit 0;
