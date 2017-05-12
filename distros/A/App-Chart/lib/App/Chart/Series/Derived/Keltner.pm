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

package App::Chart::Series::Derived::Keltner;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;

sub longname   { __('Keltner Channel') }
sub shortname  { __('Keltner') }
sub manual     { __p('manual-node','Keltner Channel') }

use constant
  { type       => 'average',
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'keltner_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 10 },
                        { name     => __('Width'),
                          key      => 'keltner_width',
                          type     => 'float',
                          default  => 1.0,
                          decimals => 1,
                          step     => 0.5,
                          minimum  => 0 }],
    line_colours => { upper => App::Chart::BAND_COLOUR(),
                      lower => App::Chart::BAND_COLOUR() },
  };

sub new {
  my ($class, $parent, $N, $width) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N >= 1) || croak "Keltner bad N: $N";

  $width //= parameter_info()->[1]->{'default'};
  ($width >= 0) || croak "Keltner bad width: $width";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N, $width ],
     arrays     => { middle   => [],
                     upper => [],
                     lower => [] },
     array_aliases => { values => 'middle' });
}

sub proc {
  my ($class_or_self, $N, $width) = @_;
  my $sma_tp_proc  = App::Chart::Series::Derived::SMA->proc($N);
  my $sma_range_proc = App::Chart::Series::Derived::SMA->proc($N);

  return sub {
    my ($high, $low, $close) = @_;
    $high //= $close;
    $low //= $close;
    my $sma_tp    = $sma_tp_proc->(($high + $low + $close) / 3);
    my $sma_range = $width * $sma_range_proc->($high - $low);
    return ($sma_tp, $sma_tp + $sma_range, $sma_tp - $sma_range);
  };
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;
  my $p_highs = $parent->array('highs') || $p;
  my $p_lows  = $parent->array('lows')  || $p;

  my $s_middle = $self->array('middle');
  my $s_upper  = $self->array('upper');
  my $s_lower  = $self->array('lower');
  $hi = min ($hi, $#$p);
  if ($#$s_middle < $hi) { $#$s_middle = $hi; }  # pre-extend
  if ($#$s_upper < $hi)  { $#$s_upper  = $hi; }  # pre-extend
  if ($#$s_lower < $hi)  { $#$s_lower  = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($p_highs->[$i], $p_lows->[$i], $close);
  }

  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    ($s_middle->[$i], $s_upper->[$i], $s_lower->[$i])
      = $proc->($p_highs->[$i], $p_lows->[$i], $close)
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Keltner -- Keltner channel indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Keltner($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>
# 
# =cut
