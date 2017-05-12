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

package App::Chart::Series::Derived::ParabolicSAR;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::MFI;
use App::Chart::Series::Derived::TrueRange;


sub longname   { __('Parabolic SAR') }
sub shortname  { __('SAR') }
sub manual     { __p('manual-node','Parabolic SAR') }

use constant
  { type       => 'average',
    parameter_info => [ { name     => __('Initial accel'),
                          key      => 'parabolic_sar_initial_accel',
                          type     => 'float',
                          decimals => 2,
                          minimum  => 0,
                          maximum  => 1,
                          default  => 0.02,
                          step     => 0.01 },
                        { name     => __('Max accel'),
                          key      => 'parabolic_sar_max_accel',
                          type     => 'float',
                          decimals => 2,
                          minimum  => 0,
                          maximum  => 1,
                          default  => 0.2,
                          step     => 0.1 } ],
    default_linestyle => 'Stops',
  };

sub new {
  my ($class, $parent, $initial_accel, $max_accel) = @_;

  $initial_accel //= parameter_info()->[0]->{'default'};
  #  ($initial_accel >= 0) || croak "ParabolicSAR bad initial accel: $initial_accel";

  $max_accel //= parameter_info()->[0]->{'default'};
  #  ($max_accel >= 0) || croak "ParabolicSAR bad max accel: $max_accel";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $initial_accel, $max_accel ],
     arrays     => { values => [] },
     hi         => $parent->hi + 1,
     array_aliases => { values => 'high' });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my ($initial_accel, $max_accel) = @{$self->{'parameters'}};

  my $parent = $self->{'parent'};
  $lo = 0;
  $hi = $parent->hi;

  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my ($extreme, $sar, $accel);
  my ($rising, $falling, $proc);
  my ($high, $low);

   $rising = sub {
    if ($high > $extreme) {
      $extreme = $high;
      $accel = min ($max_accel, $accel + $initial_accel);
    }

    $sar += $accel * ($extreme - $sar);

    # if SAR penetrated, reverse
    if ($low <= $sar) {
      $sar = $extreme;
      $extreme = $low;
      $accel = $initial_accel;
      $proc = $falling;
    }
  };

  $falling = sub {
    if ($low < $extreme) {
      $extreme = $low;
      $accel = min ($max_accel, $accel + $initial_accel);
    }

    $sar += $accel * ($extreme - $sar);

    # if SAR penetrated, reverse
    if ($high >= $sar) {
      $sar = $extreme;
      $extreme = $high;
      $accel = $initial_accel;
      $proc = $rising;
    }
  };

  $proc = sub {
    $extreme = $high;
    $accel = $initial_accel;
    $sar = $low;
    $proc = $rising;
  };

  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    $high = $ph->[$i] // $value;
    $low  = $pl->[$i] // $value;
    $proc->($ph->[$i], $pl->[$i], $value);
    $s->[$i] = $sar;
  }

  # prospective stop one beyond parent series
  $sar += $accel * ($extreme - $sar);
  $s->[$hi+1] = $sar;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ParabolicSAR -- parabolic stop and reverse
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ParabolicSAR($initial_accel, $max_accel);
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
