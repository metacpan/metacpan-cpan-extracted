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

package App::Chart::Series::Derived::Mul;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Scalar::Util;

use App::Chart::Database;
use App::Chart::TZ;
use base 'App::Chart::Series';


use constant
  { longname  => 'Multiply',
    shortname => 'Mul',
    type      => 'overload',
  };

sub new {
  my ($class, $parent, @factors) = @_;
  my $factor = 1;
  foreach (@factors) {
    if (ref $_) {
      croak 'Can only multiply a App::Chart::Series by a constant';
    }
    $factor *= $_;
  }
  return $class->SUPER::new
    (parent => $parent,
     factor => $factor,
     arrays  => { map {; $_ => [] } keys %{$parent->{'arrays'}} });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $factor = $self->{'factor'};

  $parent->fill ($lo, $hi);
  my $arrays = $self->{'arrays'};
  while (my ($aname, $s) = each %$arrays) {
    my $p = $parent->array($aname);

    my $hi = min ($hi, $#$p);
    if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

    foreach my $i ($lo .. $hi) {
      if (defined $p->[$i]) {
        $s->[$i] = $p->[$i] * $factor;
      }
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Mul -- series multiplication
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent * 100.0;
# 
#  # or directly
#  my $series = $parent->mul(2.5);
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
