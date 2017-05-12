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

use strict;
use warnings;
use Test::More tests => 52;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


#-----------------------------------------------------------------------------
# ema2_omitted()

sub ref_ema_2_omitted {
  my ($f, $k) = @_;
  my $total;

  for (;;) {
    $k++;
    my $term = ($k+1) * $f**$k;
    $total += $term;
    if ($term / $total < 0.0001) {
      return (1-$f) * (1-$f) * $total;
    }
  }
}

sub nearly_eq {
  my ($ref, $got) = @_;
  my $ret = (abs($ref-$got) <= 0.01);
  if (! $ret) {
    diag "ref=$ref got=$got";
  }
  return $ret;
}

{
  my $N = 10;
  require App::Chart::Series::Derived::EMA;
  require App::Chart::Series::Derived::EMAx2;
  my $f = App::Chart::Series::Derived::EMA::N_to_f ($N);
  foreach my $k (1 .. 50) {
    my $ref = ref_ema_2_omitted ($f, $k);
    my $got = App::Chart::Series::Derived::EMAx2::ema2_omitted ($f, $k);
    ok (nearly_eq ($ref, $got),
        "ema2_omitted $k  (got=$got)");
  }
}

#-----------------------------------------------------------------------------
# warmup_count()

{ my $N = 1;
  is (App::Chart::Series::Derived::EMAx2->warmup_count($N),
      0,
      "warmup_count($N)");
}

{ my $N = 2;
  my $got = App::Chart::Series::Derived::EMAx2->warmup_count($N);
  ok ($got > 0,
      "warmup_count($N) got=$got");
}

exit 0;

