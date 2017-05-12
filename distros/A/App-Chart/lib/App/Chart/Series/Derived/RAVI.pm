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

package App::Chart::Series::Derived::RAVI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;

sub longname   { __('RAVI') }
*shortname = \&longname;
sub manual     { __p('manual-node','RAVI') }

use constant
  { type       => 'indicator',
    units      => 'units',
    minimum    => 0,
    hlines     => [ 3 ],
    parameter_info => [ { name    => __('Short Days'),
                          key     => 'ravi_short_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 7 },
                        { name    => __('Long Days'),
                          key     => 'ravi_long_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 65 }],
  };

sub new {
  my ($class, $parent, $short_N, $long_N) = @_;

  $short_N //= parameter_info()->[0]->{'default'};
  ($short_N > 0) || croak "RAVI bad short N: $short_N";

  $long_N //= parameter_info()->[1]->{'default'};
  ($long_N > 0) || croak "RAVI bad long N: $long_N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $short_N, $long_N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($class_or_self, $short_N, $long_N) = @_;
  return App::Chart::Series::Derived::SMA->warmup_count
    (max ($short_N, $long_N));
}
sub proc {
  my ($self_or_class, $short_N, $long_N) = @_;
  my $short_proc = App::Chart::Series::Derived::SMA->proc ($short_N);
  my $long_proc  = App::Chart::Series::Derived::SMA->proc ($long_N);
  return sub {
    my ($value) = @_;
    my $short = $short_proc->($value);
    my $long  = $long_proc->($value);
    return ($long == 0 ? undef : 100 * abs($short-$long) / $long);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::RAVI -- RAVI indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->RAVI;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::REMA>
# 
# =cut
