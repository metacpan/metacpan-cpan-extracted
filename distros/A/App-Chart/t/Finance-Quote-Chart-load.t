#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


## no critic (RequireUseStrict, RequireUseWarnings)
BEGIN{
  my $found = 0;
  foreach my $dir (@INC) {
    if (ref $dir) {
      require Test::More;
      Test::More::plan (skip_all => 'due to code in @INC, maybe Module::Mask');
    }
    if (-r "$dir/GT/DB.pm") {
      $found = 1;
      last;
    }
  }
  if (! $found) {
    require Test::More;
    Test::More::plan (skip_all => 'due to Finance::Quote not available');
  }
}

use Finance::Quote::Chart;

use Finance::Quote;
my $q = Finance::Quote->new ('Chart');
my %quotes = $q->fetch('chartprog','BHP.AX','RS.WCE');

use Test::More tests => 1;
ok (1, 'Finance::Quote::Chart load as first thing');
exit 0;
