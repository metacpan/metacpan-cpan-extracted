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

package App::Chart::Series::Derived::ROC;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::Momentum;

sub longname   { __('ROC - Rate of Change') }
sub shortname  { __('ROC') }
sub manual     { __p('manual-node','Momentum and Rate of Change') }

use constant
  { type       => 'indicator',
    units      => 'roc_percent',
    hlines     => [ 0 ],
    parameter_info => App::Chart::Series::Derived::Momentum::parameter_info(),
  };

sub new {
  my ($class, $parent, $N) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] });
}
sub proc {
  my ($self_or_class, $N) = @_;

  # $a[0] is the newest point, $a[1] the prev, through to $a[$N-1]
  my @a;
  my $pos = $N-1;  # initial pre-extends

  return sub {
    my ($value) = @_;
    my $prev = $a[$pos];
    $a[$pos] = $value;
    if (++$pos >= $N) { $pos = 0; }

    if (defined $prev && $prev != 0) {
      return 100 * ($value - $prev) / $prev;
    } else {
      return undef;
    }
  };
}
*warmup_count = \&App::Chart::Series::Derived::Momentum::warmup_count;  # $N-1

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ROC -- rate of change indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ROC;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::Momentum>
# 
# =cut
