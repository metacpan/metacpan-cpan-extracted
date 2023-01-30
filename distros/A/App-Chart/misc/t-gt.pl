#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2016, 2020 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

# BEGIN { push @INC, '/usr/share/perl5'; }

use strict;
use warnings;
use GT::Prices;
use GT::DB::Chart;
use GT::Prices;
use GT::Conf;
use GT::Eval;
use GT::DateTime;
use GT::Tools qw(:timeframe);

GT::Conf::load();

{
  my $symbol = 'IIF.AX';
  $symbol = 'GXY.AX';


  # my $indicator = create_standard_object("I:BOL");
  # my $indicator = create_standard_object("I:SMA", 10);

  require GT::Indicators::LinearRegression;
  # my $indicator = create_standard_object("I:LinearRegression", 10);
  #
  # FIXME: Is this one supposed to work?
   my $indicator = GT::Indicators::LinearRegression->new([10,10]);

  # require GT::Indicators::SMA;
  # my $indicator = GT::Indicators::SMA->new;

  print "indicator $indicator\n";
  print "indicator name ",$indicator->get_name,"\n";


  my $db = GT::DB::Chart->new;
  print "db name of $symbol ", $db->get_name($symbol), "\n";

  # my $prices = $db->get_prices ($symbol, $DAY);

  # my $indicator = GT::Eval::create_standard_object("I:SMA",
  #                                                  "12 {I:Prices CLOSE\}");

  my $nb_values = $indicator->get_nb_values;
  print "indicator nb_values $nb_values\n";

  my $code = $symbol;
  my $timeframe = $DAY;
  my $full = 0;
  my $start = '2008-03-02';
  my $end = '2008-04-01';
  my $nb_item = 10;
  my $max_loaded_items = -1;

  print "timeframe $DAY\n";

  my ($calc, $first, $last) = find_calculator
    ($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);

  print "calc  $calc\n";
  print "first $first\n";
  print "last  $last\n";

  print "calc indicators ", $calc->indicators, "\n";

  print "name ", $indicator->get_name, "\n";

  # $indicator->calculate_all ($calc);
  $indicator->calculate_interval ($calc, $first, $last);

  for (my $n = 0; $n < $nb_values; $n++) {
    my $name = $indicator->get_name ($n);
    print "indicator name $n $name\n";
  }

  use Data::Dumper;
  print Dumper($calc->indicators);

  my $prices = $calc->prices;

  for (my $n = 0; $n < $nb_values; $n++) {
    my $name = $indicator->get_name ($n);
    for (my $i = $first; $i <= $last; $i++) {
      print "$n $i ";
      if ($calc->indicators->is_available ($name, $i)) {
        my $value = $calc->indicators->get($name, $i);
        my $date = $prices->at($i)->[$DATE];
        print "$date $value\n";
      } else {
        print "not avail\n";
      }
    }
  }

  exit 0;
}

{
  my $available_timeframes = GT::Conf::get('DB::timeframes_available');
  require Data::Dumper;
  print  Data::Dumper->Dump([$available_timeframes],['available_timeframes']);

  my @tf = GT::DateTime::list_of_timeframe;
  print  Data::Dumper->Dump([\@tf],['list_of_timeframe']);

  exit 0;
}

{
  exit 0;
}
