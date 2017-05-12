# Copyright 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::Momentum;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;


sub longname   { __('Momentum') }
*shortname = \&longname;
sub manual     { __p('manual-node','Momentum and Rate of Change') }

use constant
  { type       => 'indicator',
    units      => 'price',
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'momentum_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 40 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

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

    if (defined $prev) {
      return $value - $prev;
    } else {
      return undef;
    }
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Momentum -- momentum indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Momentum;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::ROC>
# 
# =cut
