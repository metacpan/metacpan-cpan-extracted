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

package App::Chart::Series::Derived::ChaikinOsc;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;

sub longname   { __('Chaikin Oscillator') }
sub shortname  { __('Chaikin Osc') }
sub manual     { __p('manual-node','Chaikin Oscillator') }

use constant
  { type       => 'indicator',
    minimum    => -1,
    maximum    => 1,
    units      => 'ChaikinOsc',
    hlines     => [ 0 ],
    parameter_info => [ { name     => __('Fast Days'),
                          key      => 'chaikin_osc_fast_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 3,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('Slow Days'),
                          key      => 'chaikin_osc_slow_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 10,
                          decimals => 0,
                          step     => 1 }],
  };

sub new {
  my ($class, $parent, $N_fast, $N_slow) = @_;

  $N_fast //= parameter_info()->[0]->{'default'};
  ($N_fast > 0) || croak "ChaikinOsc bad N_fast: $N_fast";

  $N_slow //= parameter_info()->[0]->{'default'};
  ($N_slow > 0) || croak "ChaikinOsc bad N_slow: $N_slow";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N_fast, $N_slow ],
     arrays     => { values => [] },
     array_aliases => { },
     accdist    => $parent->AccDist);
}
sub warmup_count {
  my ($self_or_class, $N_fast, $N_slow) = @_;
  return App::Chart::Series::Derived::EMA->warmup_count (max($N_fast, $N_slow));
}

sub fill_part {
  my ($self, $lo, $hi) = @_;

  my ($N_fast, $N_slow) = @{$self->{'parameters'}};
  my $fast_proc = App::Chart::Series::Derived::EMA->proc ($N_fast);
  my $slow_proc = App::Chart::Series::Derived::EMA->proc ($N_slow);
  my $accdist = $self->{'accdist'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $accdist->find_before ($lo, $warmup_count);
  $accdist->fill ($start, $hi);
  my $p = $accdist->values_array;

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $fast_proc->($value);
    $slow_proc->($value);
  }
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    $s->[$i] = $fast_proc->($value) - $slow_proc->($value);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ChaikinOsc -- Chaikin money flow
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ChaikinOsc($N);
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
