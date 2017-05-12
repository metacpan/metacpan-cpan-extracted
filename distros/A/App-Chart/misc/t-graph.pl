#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2 '-init';
use App::Chart::Gtk2::Graph;
use App::Chart::Gtk2::Graph::Plugin::Latest;
use App::Chart::Gtk2::Graph::Plugin::Today;
use App::Chart::Series::Database;
use Data::Dumper;

my $series = App::Chart::Series::Database->new ('TAH.AX');
{
  my @a = $series->Alerts_arrayref;
  print Dumper(\@a);
  @a = $series->initial_range (0, $series->hi);
  print Dumper(\@a);

  my $values = $series->values_array;
  print "values ", Dumper($values);

  my $closes = $series->array('closes');
  print "closes ", Dumper($closes);

  my $opens = $series->array('opens');
  print "opens ", Dumper($opens);

  exit 0;
}

my $series_list = [ $series ];
my $timebase = $series->timebase;

foreach my $t (0, $series->hi,
               App::Chart::Gtk2::Graph::Plugin::Latest->hrange (undef, $series_list),
               App::Chart::Gtk2::Graph::Plugin::Today->hrange (undef, $series_list),
               #             App::Chart::Gtk2::Graph::Plugin::Text->hrange ($self->{'upper'}, $series_list),
               #             App::Chart::Gtk2::Graph::Plugin::AnnLines->hrange ($self->{'upper'}, $series_list))
              ) {
  print "$t ",$timebase->to_iso($t),"\n";
}

exit 0;
