#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw(min max);
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::Series::Database;

{
  my $series = App::Chart::Series::Database->new('AUDZAR.RBA');
  print Dumper (\$series);
  print "hi ", $series->hi, "\n";

  my $hi = $series->hi;
  $series->fill($hi-20, $hi);
  print Dumper (\$series);

  #  my $closes = $series->array('closes')->(8000, 8100);
  #  print "len ", $#$closes, "\n";
  #  print Dumper (\$closes);

  #   my @x = $series->fetch_values (6000, 6020);
  #   print Dumper (\@x);

  #   my $dates = $series->dates;
  #   print Dumper (\$dates);
  exit 0;
}

{
  require App::Chart::Gtk2::SeriesModel;
  my $series = App::Chart::Series::Database->new('000001.SS');
  my $model = App::Chart::Gtk2::SeriesModel->new (series => $series);
  my $iter = $model->get_iter_first;
  say $model->get($iter,$model->COL_DATE);
  say $model->get($iter,$model->COL_OPEN);
  say $model->get($iter,$model->COL_CLOSE);
  say $model->get($iter,$model->COL_VOLUME) // 'undef';

  $series->fill(0,0);
  my $volumes = $series->array('volumes');
  say $volumes->[0] // 'undef';
  exit 0;
}


{
  my $series = App::Chart::Series::Database->new('BHP.AX');
  my $adj = $series->Adjust(adjust_dividends=>1);
  print Dumper($adj);
  my $hi = $adj->hi;
  print "hi $hi\n";
  my $lo = $hi - 100;
  $adj->fill ($lo, $hi);

  my $closes = $adj->array('closes');
  print Dumper([ @{$closes}[$lo..$hi] ]);
  print Dumper([ @{$series->array('closes')}[$lo..$hi] ]);

  my ($p_lo, $p_hi) = $adj->range ($lo, $hi);
  print "range $p_lo, $p_hi\n";

   ($p_lo, $p_hi) = $adj->initial_range ($lo, $hi);
  print "initial range $p_lo, $p_hi\n";
  exit 0;
}

{
  my $series = App::Chart::Series::Database->new('BHP.AX');
  my $dividends = $series->dividends;
  print Dumper ($dividends);
  my $annotations = $series->annotations;
  print Dumper ($annotations);
  exit 0;
}

{
  my $series = App::Chart::Series::Database->new('BHP.AX');
  print Dumper (\$series);
  print "hi ", $series->hi, "\n";

  print "collapse\n";
  require App::Chart::Series::Collapse;
  my $collapse = App::Chart::Series::Collapse->derive($series, 'App::Chart::Timebase::Weeks');
  print "hi ", $collapse->hi, "\n";
  exit 0;
}



{
  {
    my $s1 = App::Chart::Series::Database->new('BHP.AX');
    print "s1 $s1\n";
    my $s2 = App::Chart::Series::Database->new('BHP.AX');
    print "s2 $s2\n";
    print $s1 == $s2 ? "equal\n" : "different\n";
  }
  print Dumper (\%App::Chart::Series::Database::cache);
  my $series = App::Chart::Series::Database->new('TEL.NZ');
  print Dumper (\%App::Chart::Series::Database::cache);
  print "series $series\n";
  exit 0;
}

