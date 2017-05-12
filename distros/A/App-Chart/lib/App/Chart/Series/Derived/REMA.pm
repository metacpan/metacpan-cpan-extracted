# Copyright 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::REMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');
use Math::Trig ();

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;

# http://www.traders.com/Documentation/FEEDbk_docs/Archive/072003/Abstracts_new/Satchwell/satchwell.html
#     Start of TASC August 2003 article by Chris Satchwell.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/072003/TradersTips/TradersTips.html
#     TASC Traders' Tips August 2003, regularization formulas.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/092003/Letters/Letters.html
#     TASC letters September 2003, Chris Satchwell clarifying derivation of
#     formula.
#
# http://www.equis.com/Customer/Resources/TASC/Article.aspx?Id=50
#     Metastock code for regularized EMA and regularized momentum.
#
# http://trader.online.pl/ELZ/t-i-Regularization.html
#     Easylanguage code, copy of trader's tips.
#

sub longname   { __('REMA - Regularized EMA') }
sub shortname  { __('REMA') }
sub manual     { __p('manual-node','Regularized Exponential Moving Average') }

use constant
  { type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'rema_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 21 },
                        { name     => __('Days'),
                          key      => 'rema_lambda',
                          type     => 'float',
                          decimals => 1,
                          minimum  => 0,
                          default  => 0.5,
                          step     => 0.1 }],
  };

sub new {
  my ($class, $parent, $N, $lambda) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "REMA bad N: $N";

  $lambda //= parameter_info()->[1]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N, $lambda ],
     arrays     => { values => [] },
     array_aliases => { });
}

# A REMA is in theory influenced by all preceding data, but warmup_count()
# is designed to determine a warmup count.  After calling $proc with
# warmup_count() many values, the next call will have an omitted weight of
# no more than 0.1% of the total.  Omitting 0.1% should be negligable,
# unless past values are ridiculously bigger than recent ones.
#
# FIXME: probably shorter than the full EMA when lambda > 0
#
sub warmup_count {
  my ($class_or_self, $N, $lambda) = @_;
  return 2 * App::Chart::Series::Derived::EMA->warmup_count ($N / $lambda);
}

# The formula
#
#            Rprev * (2L+1) + alpha*(close - Rprev) - L*Rprevprev
#     REMA = ----------------------------------------------------
#                                L+1
#
# is turned into the followering, in the style of the AmiBroker code in
# Trader's Tips above,
#
#            a*close + b*Rprev + c*Rprevprev
#     REMA = -------------------------------
#                         L+1
#
# with constants
#
#         alpha         2*L+1-alpha        -L
#     a = -----     b = -----------    c = ---
#          L+1              L+1            L+1
#
sub proc {
  my ($class, $N, $lambda) = @_;

  my $alpha = App::Chart::Series::Derived::EMA::N_to_alpha ($N);
  my $den = $lambda + 1;
  my $a = $alpha                   / $den;
  my $b = (2*$lambda + 1 - $alpha) / $den;
  my $c = -$lambda                 / $den;

  my $rP = 0;
  my $rP_weight = 0;
  my $rPP = 0;
  my $rPP_weight = 0;

  return sub {
    my ($value) = @_;

    my $r = $a*$value + $b*$rP + $c*$rPP;
    my $r_weight = $a + $b*$rP_weight + $c*$rPP_weight;

    $rPP = $rP;
    $rPP_weight = $rP_weight;
    $rP = $r;
    $rP_weight = $r_weight;

    return $r / $r_weight;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::REMA -- Regularized exponential moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->REMA($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::REMA_Momentum>
# 
# =cut
