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

require App::Chart::Series::Derived::DEMA;

#-----------------------------------------------------------------------------
# dema_omitted()

# return the coefficient of the f^k term in an EMA
sub ref_ema_coef {
  my ($f, $k) = @_;
  return 1 - $f;
}
# return the coefficient of the f^k term in an EMAofEMA
sub ref_ema2_coef {
  my ($f, $k) = @_;
  return (1 - $f) * (1 - $f) * ($k + 1);
}
# return the coefficient of the f^k term in a DEMA
sub ref_dema_coef {
  my ($f, $k) = @_;
  return 2*ref_ema_coef($f,$k) - ref_ema2_coef($f,$k);
}

sub ref_dema_total_abs_weight {
  my ($N, $f) = @_;
  return 1 + 2 * $f**($N+1);
}

sub ref_dema_omitted {
  my ($N, $f, $k) = @_;
  my $total = 0;
  my $terms = 0;

  for (;;) {
    $terms++;
    $k++;
    my $weight = abs($f**$k * ref_dema_coef($f,$k));
    if ($terms >= $N*5 && $weight/$total < 0.0000001) {
      last;
    }
    $total += $weight;
  }
  return $total / ref_dema_total_abs_weight($N,$f);
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
  my $f = App::Chart::Series::Derived::EMA::N_to_f ($N);
  foreach my $k (1 .. 50) {
    # diag "$N $f $k";
    my $ref = ref_dema_omitted ($N, $f, $k);
    my $got = App::Chart::Series::Derived::DEMA::dema_omitted ($N, $f, $k);
    ok (nearly_eq ($ref, $got),
        "ema2_omitted $k  (got=$got)");
  }
}

#-----------------------------------------------------------------------------
# warmup_count()

{ my $N = 1;
  is (App::Chart::Series::Derived::DEMA->warmup_count($N),
      0,
      "warmup_count($N)");
}

{ my $N = 2;
  my $got = App::Chart::Series::Derived::DEMA->warmup_count($N);
  ok ($got > 0,
      "warmup_count($N) got=$got");
}

exit 0;

