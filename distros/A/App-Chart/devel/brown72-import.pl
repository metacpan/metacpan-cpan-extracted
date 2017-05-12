#!/usr/bin/perl -w

# Copyright 2007, 2009, 2010, 2011, 2016 Kevin Ryde

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


# Usage: perl brown72-import.pl [brown72.h]
#

use 5.010;
use strict;
use warnings;
use List::Util;
use Scalar::Util;
use App::Chart::Download;

use FindBin;
my $progname = $FindBin::Script;

my $filename = $ARGV[0] || 'brown72.h';

my $mean;
{
  my $symbol = 'BROWN72-DIFFS.DATA';
  my @data = ();
  my $h = { source          => $progname,
            prefer_decimals => 2,
            data            => \@data };

  my $tdate = App::Chart::ymd_to_tdate_floor (1980,1,1);

  open my $in, '<', $filename or die;
  while (defined (my $line = <$in>)) {
    $line =~ s/,//;
    Scalar::Util::looks_like_number($line) or next;
    push @data, { symbol => $symbol,
                  date   => App::Chart::tdate_to_iso($tdate),
                  close  => $line,
                };
    $tdate++;
  }
  close $in or die;

  print "$symbol @{[scalar @data]} values imported\n";
  App::Chart::Database->add_symbol ($symbol);
  App::Chart::Download::write_daily_group ($h);

  $mean = List::Util::sum (map {$_->{'close'}} @data) / scalar @data;
  print "mean $mean\n";
}

{
  my $symbol = 'BROWN72-CUMUL.DATA';
  my @data = ();
  my $h = { source          => $progname,
            prefer_decimals => 2,
            data            => \@data };

  my $tdate = App::Chart::ymd_to_tdate_floor (1980,1,1);
  my $total = 0;
  push @data, { symbol => $symbol,
                date   => App::Chart::tdate_to_iso($tdate),
                close  => $total,
              };
  $tdate++;

  open my $in, '<', $filename or die;
  while (defined (my $line = <$in>)) {
    $line =~ s/,//;
    Scalar::Util::looks_like_number($line) or next;
    $line -= $mean;
    $total += $line;
    push @data, { symbol => $symbol,
                  date   => App::Chart::tdate_to_iso($tdate),
                  close  => $total,
                };
    $tdate++;
  }
  close $in or die;

  print "$symbol @{[scalar @data]} values imported\n";
  App::Chart::Database->add_symbol ($symbol);
#   require Data::Dumper;
#   print Data::Dumper->Dump([$h],['h']);
  App::Chart::Download::write_daily_group ($h);
}

exit 0;
