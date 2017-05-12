# Copyright 2002, 2003, 2004, 2005, 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::Ichimoku;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

# http://www.fmlabs.com/reference/IchimokuKinkoHyo.htm
#     Formulas, some description.


sub longname   { __('Ichimoku Kinko Hyo') }
sub shortname  { __('Ichimoku') }
sub manual     { __p('manual-node','Ichimoku Kinko Hyo') }

use constant
  { hlines     => [ 0 ],
    type       => 'average',
    minimum    => -10,
    maximum    => 10,
    parameter_info => [ { name    => __('Tenkan Days'),
                          key     => 'tenkan_N',
                          type    => 'integer',
                          minimum => 1,
                          default => 9 },
                        { name    => __('Kijun Days'),
                          key     => 'kijun_N',
                          type    => 'integer',
                          minimum => 1,
                          default => 26 },
                      ],
    line_colours => { tenkan   => 'orange',
                      kijun    => 'dark red',
                      chikou   => 'blue',
                      senkou_A => 'dark green',
                      senkou_B => 'dark green' },
  };

sub new {
  my ($class, $parent, $tenkan_N, $kijun_N) = @_;
  ### Ichimoku new(): "@_"

  $tenkan_N //= parameter_info()->[0]->{'default'};
  ($tenkan_N > 0) || croak "Ichimoku bad tenkan_N: $tenkan_N";

  $kijun_N //= parameter_info()->[1]->{'default'};
  ($kijun_N > 0) || croak "Ichimoku bad kijun_N: $kijun_N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $tenkan_N, $kijun_N ],
     tenkan_N   => $tenkan_N,
     kijun_N    => $kijun_N,
     hi         => $parent->hi + $kijun_N,
     arrays     => { tenkan   => [],
                     kijun    => [],
                     senkou_A => [],
                     senkou_B => [],
                     chikou   => [],
                   },
     array_aliases => { values => 'tenkan' });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent   = $self->{'parent'};
  my $kijun_N  = $self->{'kijun_N'};
  my $tenkan_N = $self->{'tenkan_N'};

  my $start = $parent->find_before ($lo, 3 * $kijun_N - 1);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $chikou_array   = $self->array('chikou');
  my $tenkan_array   = $self->array('tenkan');
  my $kijun_array    = $self->array('kijun');
  my $senkou_A_array = $self->array('senkou_A');
  my $senkou_B_array = $self->array('senkou_B');

  # $hi = min ($hi, $#$p);
  # if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  # chikou copy of input closes but $kijun_N days behind
  for (my $i = $lo; $i < $hi && $i + $kijun_N <= $#$p; $i++) {
    $chikou_array->[$i] = $p->[$i + $kijun_N];
  }

  my $array_N = 2 * $kijun_N;
  my @h;
  my @l;
  foreach my $i ($start .. $hi) {
    my $value = $p->[$i] // next;
    unshift @h, $ph->[$i] // $value;
    unshift @l, $pl->[$i] // $value;
    if (@h > $array_N) {
      pop @h;
      pop @l;
    }

    if ($i >= $lo) {
      my $h = max (@h[0 .. min ($#h, $tenkan_N - 1)]);
      my $l = min (@l[0 .. min ($#l, $tenkan_N - 1)]);
      my $tenkan = $tenkan_array->[$i] = ($h + $l) * 0.5;

      $h = max (@h[0 .. min ($#h, $kijun_N - 1)]);
      $l = min (@l[0 .. min ($#l, $kijun_N - 1)]);
      my $kijun = $kijun_array->[$i] = ($h + $l) * 0.5;

      my $s_i = $i + $kijun_N;
      if ($s_i >= $lo && $s_i <= $hi) {
        $senkou_A_array->[$s_i] = ($tenkan + $kijun) * 0.5;

        $h = max (@h);
        $l = min (@l);
        #     $h = max ($h, @h[$kijun_N .. $#h]);
        #     $l = min ($l, @l[$kijun_N .. $#l]);
        $senkou_B_array->[$s_i] = ($h + $l) * 0.5;
      }
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Ichimoku -- Ichimoku Kinko Hyo indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Ichimoku();
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
