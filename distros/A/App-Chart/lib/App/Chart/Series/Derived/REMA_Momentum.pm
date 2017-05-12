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

package App::Chart::Series::Derived::REMA_Momentum;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::REMA;

sub longname   { __('REMA Momentum') }
*shortname = \&longname;
sub manual     { __p('manual-node','REMA Momentum') }

use constant
  { hlines     => [ 0 ],
    type       => 'indicator',
    units      => 'roc_fraction',
    parameter_info => App::Chart::Series::Derived::REMA::parameter_info(),
  };

*new = \&App::Chart::Series::Derived::REMA::new;

sub warmup_count {
  my ($class_or_self, $N, $lambda) = @_;
  return 1 + App::Chart::Series::Derived::REMA->warmup_count ($N, $lambda);
}

sub proc {
  my ($class, $N, $lambda) = @_;
  my $rema_proc = App::Chart::Series::Derived::REMA->proc ($N, $lambda);
  my $roc1_proc = roc1_proc ();
  return sub {
    my ($value) = @_;
    return $roc1_proc->($rema_proc->($value));
  };
}
sub roc1_proc {
  my $prev;
  return sub {
    my ($value) = @_;
    my $ret;
    if (defined $prev && $prev != 0) {
      $ret = ($value - $prev) / $prev;
    }
    $prev = $value;
    return $ret;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::REMA_Momentum -- REMA momentum indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->REMA_Momentum;
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
