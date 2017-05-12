# Copyright 2004, 2005, 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::KVO;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::KVOforce;
use App::Chart::Series::Derived::MACD;

use constant DEBUG => 0;

sub longname   { __('KVO - Klinger Volume Oscillator') }
sub shortname  { __('KVO') }
sub manual     { __p('manual-node','Klinger Volume Oscillator') }

use constant
  { type       => 'indicator',
    units      => 'KVO',
    hlines     => [ 0 ],
    parameter_info => [ { name     => __('Fast days'),
                          key      => 'kvo_fast_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 34,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Slow days'),
                          key      => 'kvo_slow_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 55,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Trigger'),
                          key      => 'kvo_trigger_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 13,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Histogram'),
                          key      => 'kvo_histogram',
                          type     => 'boolean',
                          default  => 1 } ],

    # FIXME: LineStyle solid for histogram
    line_colours => { values => App::Chart::UP_COLOUR(),
                      trigger => App::Chart::DOWN_COLOUR() },
  };

sub new {
  my ($class, $parent, $fast_N, $slow_N, $trigger_N, $histogram) = @_;

  $fast_N //= parameter_info()->[0]->{'default'};
  ($fast_N > 0) || croak "KVO bad fast N: $fast_N";

  $slow_N //= parameter_info()->[1]->{'default'};
  ($slow_N > 0) || croak "KVO bad slow N: $slow_N";

  $trigger_N //= parameter_info()->[2]->{'default'};
  ($trigger_N > 0) || croak "KVO bad trigger N: $trigger_N";

  $histogram //= parameter_info()->[3]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $fast_N, $slow_N, $trigger_N, $histogram ],
     arrays     => { values     => [],
                     trigger    => [],
                     ($histogram ? (histogram => []) : ()),
                   });
}

sub proc {
  my ($class_or_self, $fast_N, $slow_N, $trigger_N, $histogram) = @_;

  my $vf_proc = App::Chart::Series::Derived::KVOforce->proc();
  my $macd_proc = App::Chart::Series::Derived::MACD->proc
    ($fast_N, $slow_N, $trigger_N);

  return sub {
    my ($high, $low, $close, $volume) = @_;
    my $vf = $vf_proc->($high, $low, $close, $volume) // return;
    return $macd_proc->($vf);
  };
}
sub warmup_count_for_position {
  my ($self, $lo) = @_;
  if (DEBUG) { say "KVO warmup_count_for_position $lo"; }

  # MACD warmup
  my $macd_warmup_count
    = App::Chart::Series::Derived::MACD->warmup_count(@{$self->{'parameters'}});
  my $parent = $self->{'parent'};
  $lo = $parent->find_before ($lo, $macd_warmup_count);
  if (DEBUG) { say "  MACD $macd_warmup_count to $lo"; }

  return $self->App::Chart::Series::Derived::KVOforce::warmup_count_for_position($lo);
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;
  my $pv = $parent->array('volumes') || [];

  my $s_values = $self->array('values');
  my $s_trigger = $self->array('trigger');
  my $s_histogram = $self->array('histogram') || [];
  $hi = min ($hi, $#$p);
  if ($#$s_values   < $hi)  { $#$s_values = $hi;    }  # pre-extend
  if ($#$s_trigger < $hi)   { $#$s_trigger = $hi;   }  # pre-extend
  if ($#$s_histogram < $hi) { $#$s_histogram = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $close, $pv->[$i]);
  }

  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    ($s_values->[$i], $s_trigger->[$i], $s_histogram->[$i])
      = $proc->($ph->[$i], $pl->[$i], $close, $pv->[$i]);
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::KVO -- Klinger volume oscillator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->KVO($fast_N, $slow_N, $trigger_N, $histogram);
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
