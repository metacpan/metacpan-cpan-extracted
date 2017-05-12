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

package App::Chart::Series::Derived::IMI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;

# http://www.prophet.net/learn/taglossary.jsp?index=I
#     Description.
#
# http://www.fmlabs.com/reference/IMI.htm
#     Formula, brief description.

sub longname   { __('IMI - Intraday Momentum Index') }
sub shortname  { __('IMI') }
sub manual     { __p('manual-node','Intraday Momentum Index') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    hlines     => [ 30, 70 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'imi_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 14 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "IMI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}


# Return a procedure which calculates an intraday momentum index over an
# accumulated window of $N values.
#
# Each call $proc->($open, $close) enters a new point into the window, and
# the return is the intraday momentum index up to (and including) that
# point.  If there's no value the return is undef, which can happen if every
# day has $open==$close.
#
# To prime the window initially, call $proc with $N-1 many points preceding
# the first desired.
#
sub proc {
  my ($class_or_self, $N) = @_;
  my $num_proc = App::Chart::Series::Calculation->sum ($N);
  my $den_proc = App::Chart::Series::Calculation->sum ($N);

  return sub {
    my ($open, $close) = @_;
    if (! defined $open) { return undef; }

    my $num = $num_proc->($close > $open ? $close - $open : 0);
    my $den = $den_proc->(abs ($open - $close));
    return ($den == 0 ? undef : 100 * $num / $den);
  };
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $pc = $parent->values_array;
  my $po = $parent->array('opens') || [];

  my $s = $self->values_array;
  $hi = min ($hi, $#$pc);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $pc->[$i] // next;
    $proc->($po->[$i], $close)
  }
  foreach my $i ($lo .. $hi) {
    my $close = $pc->[$i] // next;
    $s->[$i] = ($proc->($po->[$i], $close) // next);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::IMI -- intraday momentum index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->IMI($N);
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
