#!/usr/bin/perl
# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
# Copyright (C) 2020       Christian Carey
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

package Traveller::Util;
use Modern::Perl;
require Exporter;
use POSIX qw(ceil);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(in distance nearby flush d);

# These global functions work on things that have x and y members.

sub in {
  my $item = shift;
  foreach (@_) {
    return $item if $item == $_;
  }
}

# Some functions cache their result. You must use the flush function to clear
# the cache!

my %cache;

sub nearby {
  my ($start, $distance, $candidates) = @_;
  return @{$cache{"@_"}} if exists $cache{"@_"};
  $distance = 1 unless $distance; # default
  my @result = ();
  foreach my $candidate (@$candidates) {
    next if $candidate == $start;
    if (Traveller::Util::distance($start, $candidate) <= $distance) {
      push(@result, $candidate);
    }
  }
  $cache{"@_"} = \@result;
  return @result;
};

sub distance {
  my ($from, $to) = @_;
  return $cache{"@_"} if exists $cache{"@_"};
  my ($x1, $y1, $x2, $y2) = ($from->x, $from->y, $to->x, $to->y);
  # transform the Traveller coordinate system into a decent system with one axis
  # tilted by 60°
  $y1 = $y1 - POSIX::ceil($x1/2);
  $y2 = $y2 - POSIX::ceil($x2/2);
  my $d = d($x1, $y1, $x2, $y2);
  $cache{"@_"} = $d;
  return $d;
};

sub d {
  my ($x1, $y1, $x2, $y2) = @_;
  if ($x1 > $x2) {
    # only consider moves from left to right and transpose start and
    # end point to make it so
    return d($x2, $y2, $x1, $y1);
  } elsif ($y2>=$y1) {
    # if it the move has a downwards component add Δx and Δy
    return $x2-$x1 + $y2-$y1;
  } else {
    # else just take the larger of Δx and Δy
    return $x2-$x1 > $y1-$y2 ? $x2-$x1 : $y1-$y2;
  }
}

# In order to prevent memory leaks, flush the cache after generating a
# sector or subsector.
sub flush {
  %cache = ();
}

1;
