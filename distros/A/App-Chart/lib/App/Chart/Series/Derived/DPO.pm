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

package App::Chart::Series::Derived::DPO;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;

# http://www.incrediblecharts.com/technical/detrended_price_oscillator.php
#     Formula, usage guidelines.
#
# http://www.marketscreen.com/help/AtoZ/default.asp?hideHF=&Num=41
#     Formula and description.
#

sub longname   { __('DPO - Detrended Price Oscillator') }
sub shortname  { __('DPO') }
sub manual     { __p('manual-node','Detrended Price Oscillator') }

use constant
  { hlines     => [ 0 ],
    type       => 'indicator',
    units      => 'price',
    parameter_info => [ { name    => __('Days'),
                          key     => 'dpo_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### DPO new(): "@_"

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "DPO bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $delta = N_to_delta ($N);

  my $sma_proc = App::Chart::Series::Derived::SMA->proc($N);
  my $delay_proc = App::Chart::Series::Calculation->delay($delta);

  return sub {
    my ($value) = @_;
    my $prevsma = $delay_proc->($sma_proc->($value));
    return (defined $prevsma ? $value - $prevsma : undef);
  };
}
sub warmup_count {
  my ($self_or_class, $N) = @_;
  my $delta = N_to_delta ($N);
  return $delta + App::Chart::Series::Derived::SMA->warmup_count($N);
}
sub N_to_delta {
  my ($N) = @_;
  return  1 + int ($N/2);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::DPO -- detrended price oscillator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->DPO($N);
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
