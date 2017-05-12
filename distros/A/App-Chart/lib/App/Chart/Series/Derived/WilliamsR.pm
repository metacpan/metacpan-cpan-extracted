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

package App::Chart::Series::Derived::WilliamsR;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;

sub longname  { __('Williams %R') }
sub shortname { __('%R') }
sub manual    { __p('manual-node','Williams %R') }

use constant
  { type       => 'indicator',
    units      => 'negative_percentage',
    minimum    => -100,
    maximum    => 0,
    hlines     => [-20, -80],
    parameter_info => [ { name    => __('Days'),
                          key     => 'williams_r_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 10 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "WilliamsR bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub proc {
  my ($class_or_self, $N) = @_;
  my @h;
  my @l;
  return sub {
    my ($high, $low, $close) = @_;

    unshift @h, $high // $close;
    unshift @l, $low  // $close;
    if (@h > $N) {
      pop @h;
      pop @l;
    }

    my $highhigh = List::Util::max (@h);
    my $lowlow   = List::Util::min (@l);
    my $range = $highhigh - $lowlow;
    return ($range == 0 ? -50 : 100 * ($close - $highhigh) / $range);
  };
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

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $close);
  }
  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    $s->[$i] = $proc->($ph->[$i], $pl->[$i], $close);
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::WilliamsR -- Williams %R indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->WilliamsR($N);
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
