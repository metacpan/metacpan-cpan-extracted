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

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util;
use Math::Polynomial;
use Math::BigRat;
use Math::Matrix;
use Data::Dumper;

# Math::Polynomial->verbose(1);

# Bandini
{
  sub compose_weights {
    my ($w1, $w2) = @_;
    my @ret;
    foreach my $i (0 .. $#$w1) {
      foreach my $j (0 .. $#$w2) {
        $ret[$i+$j] += $w1->[$i] * $w2->[$j];
      }
    }
    return \@ret;
  }
  my $sma2 = [0.5, 0.5];
  my @bandini = ($sma2);
  while (@bandini < 10) {
    push @bandini, compose_weights($sma2, $bandini[-1]);
  }
  foreach my $aref (@bandini) {
    require Data::Dumper;
    say Data::Dumper->new([$aref],['B'])->Indent(0)->Dump;
  }
  say scalar @{$bandini[-1]};
  foreach my $aref (@bandini) {
    require Data::Dumper;
    $aref = [ map {$_*1024} @$aref ];
    say Data::Dumper->new([$aref],['B'])->Indent(0)->Dump;
  }
  exit 0;
}


sub wma {
  my ($N, $P) = @_;
  my @coeffs = (1 .. $N);
  my $total = List::Util::sum (@coeffs);
  @coeffs = map {Math::BigRat->new("$_/$total")} @coeffs;

  while (@coeffs < 30) { push @coeffs, Math::BigRat->new(0); }

  my $f = Math::Matrix->new ([@coeffs]);
  #   my $f = Math::Polynomial->new (@coeffs);
  #   if (defined $P) {
  #     $f *= $P;
  #   }
  # print Data::Dumper->Dump([$f],['matrix']);
  return $f;
}

sub weights {
  my %opt = @_;
  my $description = $opt{'description'}
    || die "weights: missing 'description'";
  my $basename = $opt{'basename'}
    || die "weights: missing 'basename'";
  my $method = $opt{'method'};
  my $N = $opt{'N'};
  my $show_count = $opt{'show_count'};
  # (proc (calc_proc count))

  my $warmup = 30 * $show_count;
  my @input = ((0) x $warmup,
               100,
               (0) x ($show_count - 1));

  my $in_series = ConstantSeries->new (array => \@input);
  my $ma_series = $in_series->$method ($N);
  my $hi = $ma_series->hi;
  $ma_series->fill (0, $hi);

  my $output = $ma_series->values_array;
  my @weights = @{$output}[$warmup .. $hi];

  print "$basename: ",Data::Dumper->Dump([\@weights],['weights']);
}

my $N = 15;
my $N2 = int($N/2);
my $NS = int(sqrt($N));

my $p = wma($N2);
print "N2  ",$p,"\n\n";

my $q = wma($N);
print "N   ",$q,"\n\n";

$p = $p->multiply_scalar(2); # - $q;
print "2*N ",$p,"\n\n";

$p -= $q;
print "2*N-N  ",$p,"\n\n";


exit 0;

$p = wma($NS, $p);
print $p,"\n\n";

foreach my $i (0 .. $p->degree) {
  print "$i  ",$p->coeff($i)->numify*100,"\n";
}

weights (description => "Hull moving average weights",
         basename    => "chart-hull-weights",
         method      => 'HullMA',
         N           => 15,
         show_count  => 20);
exit 0;


package ConstantSeries;
use strict;
use warnings;
use base 'App::Chart::Series';

sub new {
  my ($class, %option) = @_;
  my $array = delete $option{'array'} || die;
  $option{'hi'} = $#$array;
  $option{'name'} //= 'Const';
  $option{'timebase'} ||= do {
    require App::Chart::Timebase::Days;
    App::Chart::Timebase::Days->new_from_iso ('2008-07-23')
    };
  return $class->SUPER::new (arrays => { values => $array },
                             %option);
}
sub fill_part {}
