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

package App::Chart::Series::Derived::GuppyMMA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;

# http://www.guppytraders.com/gup329.shtml
#     Summary.
#
# http://www.chartfilter.com/articles/technicalanalysis/movingaverage.htm
#     2004 article by Darryl Guppy.
#
# http://www.incrediblecharts.com/indicators/multiple_moving_averages.php
#     Sample of ASX.AX from 1999.
#

sub longname   { __('Guppy Multiple MA') }
sub shortname  { __('GMMA') }
sub manual     { __p('manual-node','Guppy Multiple Moving Average') }

use constant
  { type           => 'average',
    parameter_info =>
    [ map {; 0 || { name    => ($_ == 3 ? __('Days')
                                : $_ == 20 ? __p('long-moving-average','Long')
                                : ''),
                    key     => "guppy_mma_days_$_",
                    type    => 'integer',
                    min     => 0,
                    default => $_ } }
      3,   5,  8, 10, 12, 15,
      30, 35, 40, 45, 50, 60, ],
  };

sub new {
  my ($class, $parent, @parameters) = @_;
  if (@parameters) {
    @parameters = grep {defined && $_ != 0} @parameters;
  } else {
    @parameters = map {$_->{'default'}} @{$class->parameters};
  }
  foreach my $N (@parameters) {
    ($N > 0) or croak "Guppy MMA bad N: $N";
  }
  my @Ns_arrays;
  my %arrays;
  foreach my $i (0 .. $#parameters) {
    $arrays{"ma_$i"} = $Ns_arrays[$i] = [];
  }
  return $class->SUPER::new
    (parent     => $parent,
     parameters => \@parameters,
     Ns_arrays  => \@Ns_arrays,
     arrays     => \%arrays,
     array_aliases => { values => 'ma_0' });
}

sub warmup_count {
  my ($self) = @_;
  return App::Chart::Series::Derived::EMA->warmup_count
    (max (@{$self->{'parameters'}}));
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $Ns = $self->{'parameters'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;

  $hi = min ($hi, $#$p);
  my @procs = map {App::Chart::Series::Derived::EMA->proc($_)} @$Ns;

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    foreach (@procs) {
      $_->($value);
    }
  }

  my $arrays = $self->{'Ns_arrays'};
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;

    foreach my $j (0 .. $#procs) {
      $arrays->[$j]->[$i] = $procs[$j]->($value);
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::GuppyMMA -- Guppy multiple moving averages
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->GuppyMMA;
#  my $series = $parent->GuppyMMA (3, 5, 8, 10, ...);
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
