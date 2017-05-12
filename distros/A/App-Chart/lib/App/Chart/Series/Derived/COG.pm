# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::COG;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';


# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/The%20CG%20Oscillator.pdf
#     Paper by John Elhers.
#
# http://www.linnsoft.com/tour/techind/cog.htm
#     Sample Intel (INTC) 2001/2.
#
# http://www.working-money.com/Documentation/FEEDbk_docs/Archive/082002/TradersTips/TradersTips.html
#     Trader's tips August 2002, formulas from May 2002.
#


sub longname   { __('Centre of Gravity') }
sub shortname  { __('COG') }
sub manual     { __p('manual-node','Centre of Gravity Oscillator') }

use constant
  { type       => 'indicator',
    maximum    => -1,
    parameter_info => [ { name    => __('Days'),
                          key     => 'cog_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 10 } ],
  };
sub minimum {
  my ($self) = @_;
  return (ref $self ? - $self->{'N'} : undef);
}


sub new {
  ### COG new()
  my ($class, $parent, $N) = @_;
  ($N > 0) || croak "COG bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $N = $self->{'N'};

  my $start = $parent->find_before ($lo, $N-1);
  $parent->fill ($start, $hi);
  my $s = $self->values_array;      # self
  my $p = $parent->values_array;    # parent

  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  # @a is current points accumulated, or undef in empty positions.  a[$pos]
  # is the oldest point.
  #
  # $den is the sum of the values in @a.
  #
  # $num is the sum a[$pos]*1 + a[$pos-1]*2 + ... + a[$pos-N-1]*N, with $pos
  # wrapping around in the $N elements of @a
  #
  my @a;
  $#a = $N-1; # pre-extend
  my $num = 0;
  my $den = 0;

  my $pos = 0;
  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    # step existing and add new point
    $num += $den + $value;
    $den += $value;
    $a[$pos++] = $value;
  }
  my $count = $pos;
  ### COG warmed to: "num=$num, den=$den, count=$count"

  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;

    if ($count < $N) {
      $count++;
    } else {
      # drop oldest point
      $num -= $N * $a[$pos];
      $den -= $a[$pos];
    }

    # step existing num, and add new point
    $num += $den + $value;
    $den += $value;

    $a[$pos++] = $value;
    if ($pos >= $N) { $pos = 0; }

    $s->[$i] = ($den == 0 ? -1 : - $num / $den);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::COG -- centre of gravity indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->COG($N);
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
