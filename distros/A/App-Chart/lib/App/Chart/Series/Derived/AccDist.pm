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

package App::Chart::Series::Derived::AccDist;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

use constant DEBUG => 0;

sub longname  { __('Accumulation/Distribution Index') }
sub shortname { __("Acc/Dist") }
sub manual    { __p('manual-node','Accumulation/Distribution') }

use constant
  { type      => 'indicator',
    units     => 'AccDist',
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
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;
  my $pv = $parent->array('volumes') || [];
  sub {
    my ($i, $value) = @_;

    my $high   = $ph->[$i] // $value;
    my $low    = $pl->[$i] // $value;
    my $volume = $pv->[$i] // 0;
    my $range = $high - $low;

    return ($range == 0 ? 0
            : $volume * (-1 + 2 * ($value - $low) / $range));
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $lo_done = ($self->{'lo_done'} //= do {
    my $i;
    if ((($i = $parent->find_after($lo,1)) && defined $p->[$i])
        || (($i = $parent->find_before($lo,1)) && defined $p->[$i])) {
      $s->[$i] = 0;
      $i;
    } else {
      # no values at all in $parent
      $self->{'hi_done'} = $parent->hi;
      0
    }
  });
  my $hi_done = ($self->{'hi_done'} //= $lo_done);
  my $proc = $self->proc (@{$self->{'parameters'}});

  # extend $hi_done to $hi
  if ($hi > $hi_done) {
    if (DEBUG) { print "  extend forward from $hi_done to $hi\n"; }
    my $i = $parent->find_before ($hi_done, 1);
    my $acc = $s->[$i];

    for ( ; $i <= $hi; $i++) {
      my $value = $p->[$i] // next;
      $s->[$i] = ($acc += $proc->($i,$value));
    }
    $self->{'hi_done'} = $hi;
  }

  # extend $lo_done to $lo
  if ($lo < $lo_done) {
    if (DEBUG) { print "  extend backward from $lo_done to $lo\n"; }
    my $i = $parent->find_after ($lo_done, 1);
    my $acc = $s->[$i];

    for ( ; $i >= $lo; $i--) {
      my $value = $p->[$i] // next;
      $s->[$i] = ($acc -= $proc->($i,$value));
    }
    $self->{'lo_done'} = $hi;
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::AccDist -- accumulation/distribution index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->AccDist;
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
