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

package App::Chart::Series::Derived::ForceIndex;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::Stddev;
use App::Chart::Series::Derived::WilliamsR;


# http://www.linnsoft.com/tour/techind/efi.htm
#     Formula, but sample only an intraday.
#

sub longname   { __('Force Index') }
sub shortname  { __('Force') }
sub manual     { __p('manual-node','Force Index') }

use constant
  { hlines     => [ 0 ],
    type       => 'indicator',
    units      => 'ForceIndex',
    parameter_info => [ { name     => __('Smooth Days'),
                          key      => 'force_index_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 2,
                          decimals => 0,
                          step     => 1 }],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "ForceIndex bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub warmup_count {
  my ($class_or_self, $N) = @_;
  return 1 + App::Chart::Series::Derived::EMA->warmup_count($N);
}

# Return a procedure which calculates a relative volatility index, using
# Dorsey's original 1993 definition, over an accumulated window.
#
sub proc {
  my ($class_or_self, $N) = @_;

  my $ema_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $prev;

  return sub {
    my ($close, $volume) = @_;
    my $force;
    if (defined $prev) {
      $force = $ema_proc->(($close - $prev) * ($volume // 0));
    }
    $prev = $close;
    return $force;
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $pv = $parent->array('volumes') || [];

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($close, $pv->[$i]);
  }
  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    $s->[$i] = $proc->($close, $pv->[$i]);
  }
}
1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ForceIndex -- force index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ForceIndex($N);
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
