# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::VWMA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');
use Math::Trig ();

use base 'App::Chart::Series::Indicator';

use constant DEBUG => 0;

sub longname   { __('VWMA - Volume Weighted') }
sub shortname  { __('VWMA') }
sub manual     { __p('manual-node','Volume Weighted Moving Average') }

use constant
  { type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'vwma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  if (DEBUG >= 2) { require Data::Dumper;
                    print "VWMA->new ",Data::Dumper::Dumper(\@_); }
  my ($class, $parent, $N) = @_;

  $parent->array('volumes')
    or croak "No volumes in series '",$parent->name,"'";

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "VWMA bad N: $N";

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
  my $s = $self->values_array;
  my $pp = $parent->values_array;
  my $pv = $parent->array('volumes');

  $hi = min ($hi, $#$pp);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  # $a[0] is the newest point, $a[1] the prev, through to $a[$N-1]
  my @a;
  my @v;

  my $total_volume = 0;
  my $total_prod = 0;
  my $pos = 0;
  foreach my $i ($start .. $lo-1) {
    my $value  = $pp->[$i] // next;
    my $volume = $pv->[$i] // 0;
    $total_volume += ($v[$pos] = $volume);
    $total_prod   += ($a[$pos++] = $value * $volume);
  }
  my $count = $pos;
  if (DEBUG) { print "  warmed to total_volume=$total_volume count=$count\n";
               require Data::Dumper;
               print Data::Dumper->Dump([\@v,\@a],['v','a']); }

  foreach my $i ($lo .. $hi) {
    my $value  = $pp->[$i] // next;
    my $volume = $pv->[$i] // 0;

    if ($count < $N) {
      $count++;
    } else {
      # drop old
      $total_volume -= $v[$pos];
      $total_prod   -= $a[$pos];
    }
    # add new
    $total_volume += ($v[$pos] = $volume);
    $total_prod   += ($a[$pos++] = $value * $volume);
    if ($pos >= $N) { $pos = 0; }

    if ($total_volume != 0) {
      $s->[$i] = $total_prod / $total_volume;
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::VWMA -- volume weighted moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->VWMA($N);
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
