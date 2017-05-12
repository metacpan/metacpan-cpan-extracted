# Copyright 2002, 2003, 2004, 2005, 2006, 2007, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::Bollinger;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;


sub longname   { __('Bollinger Bands') }
sub shortname  { __('Bollinger') }
sub manual     { __p('manual-node','Bollinger Bands') }

use constant
  { type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'bollinger_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 },
                        { name     => __('Stddevs'),
                          key      => 'bollinger_stddevs',
                          type     => 'float',
                          default  => 2.0,
                          decimals => 2,
                          step     => 0.1,
                          minimum  => 0 }],
    line_colours => { upper => App::Chart::BAND_COLOUR(),
                      lower => App::Chart::BAND_COLOUR() },
  };

sub new {
  my ($class, $parent, $N, $stddev_factor) = @_;
  ### Bollinger new(): @_

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Bollinger bad N: $N";

  $stddev_factor //= parameter_info()->[1]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N, $stddev_factor ],
     arrays     => { middle => [],
                     upper  => [],
                     lower  => [] },
     array_aliases => { values => 'middle' });
}

sub proc {
  my ($class_or_self, $N, $stddev_factor) = @_;
  my $sma_stddev_proc = App::Chart::Series::Calculation->sma_and_stddev($N);

  return sub {
    my ($value) = @_;
    my ($sma, $stddev) = $sma_stddev_proc->($value);
    $stddev *= $stddev_factor;
    return ($sma, $sma + $stddev, $sma - $stddev);
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

  my $s_middle = $self->array('middle');
  my $s_upper = $self->array('upper');
  my $s_lower = $self->array('lower');
  $hi = min ($hi, $#$p);
  if ($#$s_middle < $hi) { $#$s_middle = $hi; }  # pre-extend
  if ($#$s_upper < $hi)  { $#$s_upper  = $hi; }  # pre-extend
  if ($#$s_lower < $hi)  { $#$s_lower  = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $proc->($value);
  }
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    ($s_middle->[$i], $s_upper->[$i], $s_lower->[$i]) = $proc->($value);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Bollinger -- bollinger bands
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Bollinger($N);
#  my $series = $parent->Bollinger($N, $stddev_factor);
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
