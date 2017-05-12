# Copyright 2003, 2004, 2005, 2006, 2007, 2008, 2009 Kevin Ryde

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

package App::Chart::Series::Derived::OBV;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

use constant DEBUG => 0;

sub longname  { __('OBV - On-balance Volume') }
sub shortname { __('OBV') }
sub manual    { __p('manual-node','On-Balance Volume') }

use constant
  { type      => 'indicator',
    units     => 'OBV',
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent => $parent,
     arrays => { values => [] },
     array_aliases => { });
}

sub proc {
  my ($self) = @_;
  my $parent = $self->parent;
  my $pv = $parent->array('volumes') || [];
  sub {
    my ($i, $value, $i_prev, $value_prev) = @_;
    my $volume = $pv->[$i] // 0;
    return ($value <=> $value_prev) * $volume;
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  $parent->fill ($lo-1, $hi+1);
  my $p = $parent->values_array;

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $multiply = (($self->{'accumulate'}||'') eq 'multiply');
  my $acc_forward = \&List::Util::sum;
  my $acc_backward = \&_sub;
  if ($multiply) {
    $acc_forward = \&_mul;
    $acc_backward = \&_div;
  }

  my $lo_done = ($self->{'lo_done'} //= do {
    my $i;
    if (do { $i = $parent->find_after($lo-1,1);
             defined $p->[$i] }
        || do { $i = $parent->find_before($lo+1,1);
                defined $p->[$i]
              }) {
      if (DEBUG) { print "  start at $i with acc==0\n"; }
      $s->[$i] = ($multiply ? 100 : 0);
      $i;
    } else {
      if (DEBUG) { print "  no values at all in parent\n"; }
      $self->{'hi_done'} = $parent->hi;
      0
    }
  });
  my $hi_done = ($self->{'hi_done'} //= $lo_done);
  my $proc = $self->proc (@{$self->{'parameters'}});

  # extend $hi_done to $hi
  if ($hi > $hi_done) {
    if (DEBUG) { print "  extend forward from $hi_done to $hi\n"; }
    my $i_prev = $parent->find_before ($hi_done+1, 1);
    my $acc = $s->[$i_prev];
    my $value_prev = $p->[$i_prev];

    for (my $i = $i_prev + 1; $i <= $hi; $i++) {
      my $value = $p->[$i] // next;

      $s->[$i] = ($acc = $acc_forward->
                  ($acc, $proc->($i, $value, $i_prev, $value_prev)));
      $value_prev = $value;
      $i_prev = $i;
    }
    $self->{'hi_done'} = $hi;
  }

  # extend $lo_done to $lo
  if ($lo < $lo_done) {
    if (DEBUG) { print "  extend backward from $lo_done to $lo\n"; }
    my $i = $parent->find_after ($lo_done-1, 1);
    my $acc = $s->[$i];
    my $value = $p->[$i];

    for (my $i_prev = $i - 1; $i_prev >= $lo; $i_prev--) {
      my $value_prev = $p->[$i_prev] // next;

      $s->[$i_prev] = ($acc = $acc_backward->
                       ($acc, $proc->($i, $value, $i_prev, $value_prev)));
      $i = $i_prev;
      $value = $value_prev;
    }
    $self->{'lo_done'} = $hi;
  }
}
sub _sub { $_[0] - $_[1] }
sub _mul { $_[0] * $_[1] }
sub _div { $_[0] / ($_[1]||1) }

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::OBV -- on-balance volume indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->OBV;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::Volume>
# 
# =cut
