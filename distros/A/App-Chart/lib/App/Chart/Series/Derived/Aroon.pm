# Copyright 2009 Kevin Ryde

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

package App::Chart::Series::Derived::Aroon;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

use constant DEBUG => 0;

sub longname   { __('Aroon') }
sub shortname  { __('Aroon') }
sub manual     { __p('manual-node','Aroon') }

use constant
  { type       => 'indicator',
    minimum    => -100,
    maximum    => 100,
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'aroon_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 25 } ],
    decimals   => 0, # none needed normally

    line_colours => { up   => App::Chart::UP_COLOUR(),
                      down => App::Chart::DOWN_COLOUR() },
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { up         => [],
                     down       => [],
                     oscillator => [] },
     array_aliases => { values => 'oscillator' });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $N = $self->{'N'};

  my $start = $parent->find_before ($lo, $N-1);
  $parent->fill ($start, $hi);

  my $p = $parent->array('values');
  $hi = min ($hi, $#$p);

  my $up   = $self->array('up');
  my $down = $self->array('down');
  my $osc  = $self->array('oscillator');
  if ($#$up   < $hi) { $#$up   = $hi; }  # pre-extend
  if ($#$down < $hi) { $#$down = $hi; }
  if ($#$osc  < $hi) { $#$osc  = $hi; }

  my @a;
  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    unshift @a, $value;
  }

  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;

    # keep last $N + 1 many points
    if (@a > $N) {
      pop @a;  # drop old
    }
    unshift @a, $value;  # add new

    # for equal highs or equal lows, the oldest is taken, on the
    # theory that a new high/low has not been established but rather
    # the old one is still in force
    #
    if (DEBUG) { require Data::Dumper;
                 print "Aroon on ",Data::Dumper->Dump([\@a],['a']); }
    my $high_val = my $low_val = $a[0];
    my $high_pos = my $low_pos = 0;
    foreach my $pos (1 .. $#a) {
      $value = $a[$pos];
      if ($value >= $high_val) { $high_val = $value; $high_pos = $pos; }
      if ($value <= $low_val)  { $low_val  = $value; $low_pos  = $pos; }
    }

    if (DEBUG) { print "  high_val=$high_val high_pos=$high_pos",
                   " low_val=$low_val low_pos=$low_pos  in N=$N\n"; }
    $up->[$i]   = $high_pos = 100 - 100 * $high_pos / $N;
    $down->[$i] = $low_pos  = 100 - 100 * $low_pos / $N;
    $osc->[$i]  = $high_pos - $low_pos;
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Aroon -- aroon oscillator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Aroon($N);
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
