# Copyright 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::T3;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;

# http://www.traders.com/Documentation/FEEDbk_docs/Archive/0298/TradersTips/Tips9802.html
#     Traders Tips Feb 1998, implementations of T3 and GD.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/0898/Letters9808/Letters9808.html
#     TASC letters Oct 1998, George Herbert on GD as weighted average of
#     EMA and DEMA.
#
# http://trader.online.pl/ELZ/t-i-T3.html
#     Formula in terms of GD.  Sample S&P 500 (symbol ^GSPC) from 2001,
#     with N=6 and v=0.7.
#
# http://www.linnsoft.com/tour/techind/t3.htm
#

sub longname   { __('T3 Moving Average') }
sub shortname  { __('T3') }
sub manual     { __p('manual-node','T3 Moving Average') }

use constant
  { type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 't3_days',
                          type    => 'integer',
                          minimum => 0,
                          default => 20 },
                        { name     => __('Factor'),
                          key      => 't3_factor',
                          type     => 'float',
                          default  => 0.7,
                          step     => 0.1,
                          decimals => 1,
                          minimum  => 0,
                          maximum  => 1 } ],
  };

sub new {
  my ($class, $parent, $N, $vf) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "T3 bad N: $N";

  $vf //= parameter_info()->[1]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N, $vf ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N, $vf) = @_;

  my $c1 = -($vf**3);
  my $c2 = 3*($vf**2) + 3*($vf**3);
  my $c3 = -6*($vf**2) + -3*$vf + -3*($vf**3);
  my $c4 = 1 + 3*$vf + ($vf**3) + 3*($vf**2);

  my $ema_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema2_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema3_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema4_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema5_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema6_proc = App::Chart::Series::Derived::EMA->proc($N);

  return sub {
    my ($value) = @_;

    my $a = $ema_proc->($value);
    my $b = $ema2_proc->($a);
    my $c = $ema3_proc->($b);
    my $d = $ema4_proc->($c);
    my $e = $ema5_proc->($d);
    my $f = $ema6_proc->($e);

    return ($c4   * $c
            + $c3 * $d
            + $c2 * $e
            + $c1 * $f);
  };
}

# T3 is in theory influenced by all preceding data, but warmup_count() is
# designed to determine a warmup count.  The next point will have an omitted
# weight of no more than 0.1% of the total.  Omitting 0.1% should be
# negligable, unless past values are ridiculously bigger than recent ones.
#
# FIXME: this is the worst-case of $vf==0 which makes T3 an EMAx3.  Less
# warmup is needed for a DEMAx3.
#
sub warmup_count {
  my ($class_or_self, $N) = @_;
  require App::Chart::Series::Derived::EMAx3;
  return App::Chart::Series::Derived::EMAx3->warmup_count ($N);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::T3 -- T3 moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->T3($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::EMA>
# 
# =cut
