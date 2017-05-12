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

package App::Chart::Series::Derived::ElderPower;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;

# http://www.incrediblecharts.com/technical/elder_ray_index.php
#     Formula, sample All Ords (yahoo ^AORD) from Aug 2001.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=ELDR
#     Formula, sample Hilton Hotels (HLT) from 2002/2003, weekly scale.
#

sub longname  { __('Elder Bull/Bear Power') }
sub shortname { __('Elder Power') }
sub manual    { __p('manual-node','Elder Bull/Bear Power') }

use constant
  { type       => 'indicator',
    units      => 'momentum',
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'elder_power_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 13 } ],
    line_colours => { bull => App::Chart::UP_COLOUR(),
                      bear => App::Chart::DOWN_COLOUR() },
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "ElderPower bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { bull => [],
                     bear => [] },
     array_aliases => { values => 'bull' });
}
*warmup_count = \&App::Chart::Series::Derived::EMA::warmup_count;

sub proc {
  my ($class_or_self, $N) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($N);
  return sub {
    my ($high, $low, $close) = @_;
    my $ema = $ema_proc->($close);
    $high //= $close;
    $low  //= $close;
    return ($high - $ema, $low - $ema);
  };
}
sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $su = $self->array('bull');
  my $sl = $self->array('bear');
  $hi = min ($hi, $#$p);
  if ($#$su < $hi) { $#$su = $hi; }  # pre-extend
  if ($#$sl < $hi) { $#$sl = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $value);
  }
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    ($su->[$i], $sl->[$i]) = $proc->($ph->[$i], $pl->[$i], $value);
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ElderPower -- Elder bull power / bear power
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ElderPower($N);
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
