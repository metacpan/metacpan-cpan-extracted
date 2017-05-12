# Copyright 2004, 2005, 2006, 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::MACD;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;


sub longname  { __('MACD - Momentum Advance/Decline') }
sub shortname { __('MACD') }
sub manual    { __p('manual-node','MACD') }

use constant
  { type       => 'indicator',
    units      => 'price',
    hlines     => [ 0 ],
    parameter_info => [ { name     => __('Fast days'),
                          key      => 'macd_fast_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 12,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Slow days'),
                          key      => 'macd_slow_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 26,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Smooth'),
                          key      => 'macd_smooth_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 9,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Histogram'),
                          key      => 'macd_histogram',
                          type     => 'boolean',
                          default  => 1 }],

    # FIXME: LineStyle solid for histogram
    line_colours => { macd   => App::Chart::UP_COLOUR(),
                      smooth => App::Chart::DOWN_COLOUR() },
  };

sub new {
  my ($class, $parent, $fast_N, $slow_N, $smooth_N, $histogram) = @_;

  $fast_N //= parameter_info()->[0]->{'default'};
  ($fast_N > 0) || croak "MACD bad fast N: $fast_N";

  $slow_N //= parameter_info()->[1]->{'default'};
  ($slow_N > 0) || croak "MACD bad slow N: $slow_N";

  $smooth_N //= parameter_info()->[2]->{'default'};
  ($smooth_N > 0) || croak "MACD bad smooth N: $smooth_N";

  $histogram //= parameter_info()->[3]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $fast_N, $slow_N, $smooth_N, $histogram ],
     arrays     => { macd      => [],
                     smooth    => [],
                     ($histogram ? (histogram => []) : ()),
                    },
     array_aliases => { values => 'macd' });
}
sub proc {
  my ($class_or_self, $fast_N, $slow_N, $smooth_N) = @_;
  # say "MACD proc $fast_N, $slow_N, $smooth_N";
  my $fast_proc = App::Chart::Series::Derived::EMA->proc($fast_N);
  my $slow_proc = App::Chart::Series::Derived::EMA->proc($slow_N);
  my $smooth_proc = App::Chart::Series::Derived::EMA->proc($smooth_N);

  return sub {
    my ($value) = @_;

    my $fast = $fast_proc->($value);
    my $slow = $slow_proc->($value);
    my $macd = $fast - $slow;
    my $smooth = $smooth_proc->($macd);
    return ($macd, $smooth, $macd-$smooth);
  };
}
sub warmup_count {
  my ($self_or_class, $fast_N, $slow_N, $smooth_N) = @_;
  # FIXME: as roughly EMA of EMA it should be a bit less than this ...
  return (App::Chart::Series::Derived::EMA->warmup_count(max($fast_N,$slow_N)),
          + App::Chart::Series::Derived::EMA->warmup_count($smooth_N));

}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;

  my $s_macd = $self->array('macd');
  my $s_smooth = $self->array('smooth');
  my $s_histogram = $self->array('histogram') || [];
  $hi = min ($hi, $#$p);
  if ($#$s_macd   < $hi) { $#$s_macd = $hi;   }  # pre-extend
  if ($#$s_smooth < $hi) { $#$s_smooth = $hi; }  # pre-extend
  if ($#$s_histogram < $hi) { $#$s_histogram = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $proc->($value);
  }

  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    ($s_macd->[$i], $s_smooth->[$i], $s_histogram->[$i]) = $proc->($value);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::MACD -- momentum advance/decline
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->MACD($fast_N, $slow_N, $smooth_N);
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
