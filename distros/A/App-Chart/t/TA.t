#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

package ConstantSeries;
use strict;
use warnings;
use base 'App::Chart::Series';

sub new {
  my ($class, $aref, $timebase) = @_;
  require App::Chart::Timebase::Days;
  $timebase ||= App::Chart::Timebase::Days->new_from_iso ('2008-07-23');
  return $class->SUPER::new (timebase => $timebase,
                             arrays => { values => $aref },
                             hi => $#$aref);
}
sub fill_part {}
sub name { return 'Const'; }

package main;
use 5.005;
use strict;
use warnings;
use Test::More 0.82;

if (! eval { require Finance::TA; }) {
  plan skip_all => "Cannot load Finance::TA -- $@";
  exit 0;
}
plan tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

diag "TA_GetVersionString ",Finance::TA::TA_GetVersionString();

require App::Chart::Series::TA;


#------------------------------------------------------------------------------
# inname_to_arrays

is_deeply ([ App::Chart::Series::TA::input_paramName_to_arrays('inReal') ],
           [ 'values' ],
           "input_paramName_to_arrays 'inReal'");

is_deeply ([ App::Chart::Series::TA::input_paramName_to_arrays('inPriceHLC') ],
           [ 'highs','lows','closes' ],
           "input_paramName_to_arrays 'inPriceHLC'");

#------------------------------------------------------------------------------
diag "SMA";
{
  my $series = ConstantSeries->new (   [ 1, 1, 1, 1, 5, 5, 5, 5 ]);
  my $sma = $series->TA_SMA(2);
  $sma->fill (0, $sma->hi);
  diag explain $sma->values_array;
  is_deeply ($sma->values_array,[ undef, 1, 1, 1, 3, 5, 5, 5 ],
             'TA_SMA n=2');
  like ($sma->manual, qr/^http:/, 'manual()');
}

#------------------------------------------------------------------------------
diag "create all";
{
  my %skip; @skip{qw(ADD BETA CORREL DIV MULT SUB)} = ();
  my $parent = ConstantSeries->new ([ 1, 2, 3, undef ]);
  my @groups = Finance::TA::TA_GroupTable();
  @groups = grep {$_ ne '0'} @groups;

  #   my %exclude_groups = ('0',                   1,
  #                         'Math Operators',      1,
  #                         'Math Transform',      1,
  #                         'Pattern Recognition', 1);
  #   @groups = grep {!$exclude_groups{$_}} @groups;

  foreach my $group (@groups) {
    my @names = Finance::TA::TA_FuncTable($group);
    @names = grep {$_ ne '0'} @names;

    foreach my $name (@names) {
      next if exists $skip{$name};
      diag "group '$group' name '$name'";
      App::Chart::Series::TA->new ($name, $parent);
    }
  }
}

exit 0;
