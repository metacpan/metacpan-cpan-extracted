# Copyright 2006, 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::PGO;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::ATR;
use App::Chart::Series::Derived::WilliamsR;


# http://www.purebytes.com/archives/omega/1999/msg12885.html
#
# http://www.mjohnson.com/trecipes/pgoy2k.zip   [gone]
#
# http://trader.online.pl/MSZ/e-w-Pretty_Good_Oscillator.html
#    Sample CSCO
#
# http://xeatrade.com/trading/2/P/1139.html
#    Metastock formula copied from http://www.traderclub.com, showing EMA[89]
#
#
# http://www.elitetrader.com/vb/printthread.php?threadid=18598
#    Bit of discussion from Nov 2003.
#

sub longname   { __('PGO - Pretty Good Oscillator') }
sub shortname  { __('PGO') }
sub manual     { __p('manual-node','Pretty Good Oscillator') }

use constant
  { hlines     => [ -3, 0, 3, ],
    type       => 'indicator',
    units      => 'pgo',
    parameter_info => [ { name    => __('Days'),
                          key     => 'pgo_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 89 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "PGO bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $sma_proc = App::Chart::Series::Derived::SMA->proc($N);
  my $atr_proc = App::Chart::Series::Derived::ATR->proc
    (App::Chart::Series::Derived::EMA::N_to_Wilder_N($N));

  return sub {
    my ($high, $low, $close) = @_;
    my $avg = $sma_proc->($close);
    my $den = $atr_proc->($high, $low, $close);
    return ($den != 0 ? ($close - $avg) / $den : undef);
  };
}
sub warmup_count {
  my ($class_or_self, $N) = @_;
  return max (App::Chart::Series::Derived::SMA->warmup_count($N),
              App::Chart::Series::Derived::ATR->warmup_count($N));
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::PGO -- pretty good oscillator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->PGO($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>
# 
# =cut
