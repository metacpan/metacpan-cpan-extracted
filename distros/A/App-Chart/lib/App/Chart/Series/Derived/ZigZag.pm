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

package App::Chart::Series::Derived::ZigZag;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

# http://stockcharts.com/education/IndicatorAnalysis/indic_ZigZag.html
#     Sample HPQ chart 1999/2000.

sub longname { __('Zig Zag') }
*shortname = \&longname;
sub manual   { __p('manual-node','Zig Zag Indicator') }

use constant
  { type      => 'average',
    parameter_info => [ { name      => __('% Change'),
                          key       => 'zigzag_percent',
                          type      => 'float',
                          type_hint => 'percent',
                          minimum   => 0,
                          default   => 5,
                          step      => 1 },
                        { name    => __('Closes'),
                          key     => 'zigzag_closes',
                          type    => 'boolean',
                          default => 0 },
                      ],
#    default_linestyle => 'ZigZag',
    line_colours => { values  => 'solid' },
  };

sub new {
  my ($class, $parent, $percent, $closes_flag) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $percent, $closes_flag ],
     arrays     => { values => [] },
     array_aliases => { });
}

# This does the whole series from start to end.  It might be possible to
# work back looking for a PERCENT move which would establish the direction
# and hence a starting point in the middle of the data.
#
sub fill {
  my ($self, $lo, $hi) = @_;
  if ($self->{'filled'}) { return; }
  $self->{'filled'} = 1;

  my $parent = $self->{'parent'};
  my ($percent, $closes_flag) = @{$self->{'parameters'}};

  $hi = $self->hi;
  $parent->fill (0, $hi);
  my $p = $parent->values_array;
  my $ph = $closes_flag ? $p : $parent->array('highs');
  my $pl = $closes_flag ? $p : $parent->array('lows');

  my $s = $self->values_array;

  my $factor_increase = 1 + $percent / 100;
  my $factor_decrease = 1 / $factor_increase;
  my $direction = sub {};
  my $extreme;
  my $target;
  my $extreme_pos;

  my ($rising, $falling);
  $rising = sub {
    my ($pos, $high, $low) = @_;
    if (! defined $extreme || $high > $extreme) {
      $extreme = $high;
      $extreme_pos = $pos;
      $target = $extreme * $factor_decrease;
      return;
    }
    if ($low <= $target) {
      my $ret_pos = $extreme_pos;
      my $ret_val = $extreme;
      $direction = $falling;
      $extreme = $low;
      $extreme_pos = $pos;
      $target = $extreme * $factor_increase;
      return $ret_pos, $ret_val;
    }
    return;
  };
  $falling = sub {
    my ($pos, $high, $low) = @_;
    if (! defined $extreme || $low < $extreme) {
      $extreme = $low;
      $extreme_pos = $pos;
      $target = $extreme * $factor_increase;
      return;
    }
    if ($low >= $target) {
      my $ret_pos = $extreme_pos;
      my $ret_val = $extreme;
      $direction = $rising;
      $extreme = $high;
      $extreme_pos = $pos;
      $target = $extreme * $factor_decrease;
      return $ret_pos, $ret_val;
    }
    return;
  };

  # decide initial direction rising or falling
  {
    my $high;
    my $high_pos;
    my $low;
    my $low_pos;

    foreach my $i (0 .. $hi) {
      my $value = $p->[$i] // next;
      my $this_high = $ph->[$i] // $value;
      my $this_low  = $pl->[$i] // $value;

      if (! defined $high || $this_high > $high) {
        $high = $this_high;
        $high_pos = $i;
      }
      if (! defined $low || $this_low < $low) {
        $low = $this_low;
        $low_pos = $i;
      }

      if ($high >= $low * $factor_increase) {
        if ($high_pos > $low_pos) {
          $direction = $rising;
          $s->[0] = $s->[$low_pos] = $low;
          last;
        }
        if ($low_pos >= $high_pos) {
          $direction = $falling;
          $s->[0] = $s->[$high_pos] = $high;
          last;
        }
      }
    }
  }

  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;

    my ($pos, $val) = $direction->($i,
                                   $ph->[$i] // $value,
                                   $pl->[$i] // $value);
    if (defined $pos) {
      $s->[$pos] = $val;
    }
  }
  if ($extreme_pos) {
    $s->[$extreme_pos] = $s->[$hi] = $extreme;
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ZigZag -- zig zag indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ZigZag;
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
