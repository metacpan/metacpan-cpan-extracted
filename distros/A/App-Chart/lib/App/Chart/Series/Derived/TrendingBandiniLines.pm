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

package App::Chart::Series::Derived::TrendingBandiniLines;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;

# http://trader.online.pl/MSZ/e-w-Trending_Bandini.html
#     Formula.
#

sub longname   { __('Trending Bandini Lines') }
sub shortname  { __('Bandini') }
# FIXME: not in the manual yet
# sub manual     { __p('manual-node','Trending Bandini') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [],
  };

use constant { LINES_COUNT => 10 };


sub new {
  my ($class, $parent) = @_;

  my @arrays_array;
  my %arrays;
  foreach my $i (1 .. LINES_COUNT) {
    $arrays{"ma_$i"} = $arrays_array[$i] = [];
  }
  return $class->SUPER::new
    (parent        => $parent,
     parameters    => [],
     arrays_array  => \@arrays_array,
     arrays        => \%arrays,
     array_aliases => { values => 'ma_'.LINES_COUNT });
}
use constant warmup_count => LINES_COUNT;

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;

  $hi = min ($hi, $#$p);
  my @procs = map {App::Chart::Series::Derived::SMA->proc(2)} (1 .. LINES_COUNT);

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    foreach (@procs) {
      $value = $_->($value);
    }
  }

  my $arrays = $self->{'arrays_array'};
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;

    foreach my $j (0 .. $#procs) {
      $arrays->[$j]->[$i] = $value = $procs[$j]->($value);
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TrendingBandiniLines -- multiple SMA lines of Trending Bandini
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TrendingBandiniLines;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>
# 
# =cut
