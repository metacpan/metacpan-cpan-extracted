# Copyright 2008, 2009, 2011, 2012 Kevin Ryde

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

package App::Chart::Series::Derived::Median;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use POSIX ();
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;


sub longname   { __('Moving Median') }
sub shortname  { __('Median') }
sub manual     { __p('manual-node','Moving Median') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [ { name    => __('Days'),
                          key     => 'median_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Median bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub proc {
  my ($class_or_self, $N) = @_;
  $N = max ($N, 1);

  my @array;
  my @sorted;
  my $mid1 = 0;
  my $mid2 = 0;
  return sub {
    my ($value) = @_;

    # add new
    unshift @array, $value;

    # drop old
    if (@array > $N) {
      pop @array;
    } else {
      # odd elems eg. 5 indexes 0,1,2,3,4 gives mid1==mid2==2   (N-1)/2
      # even elems eg. 4 indexes 0,1,2,3 gives mid1==1,mid2==2  f/c of (N-1)/2
      $mid1 = POSIX::floor ((@array - 1) / 2);
      $mid2 = POSIX::ceil ((@array - 1) / 2);
    }

    @sorted = sort {$a<=>$b} @array;
    return ($sorted[$mid1] + $sorted[$mid2]) / 2;
  };
}

1;
__END__

# # maintaining seq ...
# #
# sub fill_part {
#   my ($self, $lo, $hi) = @_;
#   my $parent = $self->{'parent'};
#   my $N = $self->{'N'};
# 
#   my $start = $parent->find_before ($lo, $N-1);
#   $parent->fill ($start, $hi);
#   my $s = $self->values_array;
#   my $p = $parent->values_array;
# 
#   $hi = min ($hi, $#$p);
#   if ($#$s < $hi) { $#$s = $hi; }  # pre-extend
# 
#   my $pos = 0;
#   my @seq;
# 
#   foreach my $i ($start .. $lo-1) {
#     my $value = $p->[$i] // next;
#     $seq[$pos++] = [ $value ];
#   }
#   my $count = $pos;
# 
#   my @sorted = sort {$a->[0] <=> $b->[0]} @seq;
#   $#seq = $N-1; # pre-extend
#   $#sorted = $N-1; # pre-extend
#   ### warmup to count: $count
# 
#   foreach my $t ($lo .. $hi) {
#     my $value = $p->[$t] // next;
# 
#     my $elem = $seq[$pos++];
#     if ($pos >= $N) { $pos = 0; }
#     if ($count < $N) { $count++; }
# 
#     if ($elem) {
#       @sorted = grep {$_ != $elem} @sorted;
#       $elem->[0] = $value;
#     } else {
#       $elem = [ $value ];
#     }
# 
#     my $i;
#     for ($i = 0; $i < $#sorted; $i++) {
#       if ($sorted[0]->[0] >= $value) {
#         last;
#       }
#     }
#     splice @sorted, $i,0, $elem;
# 
#     $s->[$t] = $sorted[$count/2]->[0];
#   }
# }


# =head1 NAME
# 
# App::Chart::Series::Derived::Median -- moving median
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->median($N);
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
