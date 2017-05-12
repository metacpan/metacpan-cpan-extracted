#!/usr/bin/perl -w

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

use strict;
use warnings;
use 5.010;
use App::Chart::Gtk2::IndicatorModel;

my $model = App::Chart::Gtk2::IndicatorModel->new;
print "$model\n";
$model->foreach
  (sub {
     my ($model, $path, $iter) = @_;
     my $pathstr = $path->to_string;
     my $depth = $path->get_depth;
     my $key = $model->get($iter,$model->{'COL_KEY'}) // '[no key]';
     my $name = $model->get($iter,$model->{'COL_NAME'}) // '[no name]';
     my $type = $model->get($iter,$model->{'COL_TYPE'}) // '[no type]';
     my $priority = $model->get($iter,$model->{'COL_PRIORITY'}) // '[no prio]';
     my $pad = '  ' x $depth;
     printf "%-7s%s%s%s %s %s %s\n",
       $pathstr, $depth, $pad, $name, $key, $type, $priority;
     return 0;
   });

# require Module::Util;
# my $ret
#   = Module::Util::module_is_loaded('App::Chart::Gtk2::IndicatorModelGenerated');
# print "App::Chart::Gtk2::IndicatorModelGenerated ret $ret\n";

exit 0;
