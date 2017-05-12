# Copyright 2006, 2007, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::VIDYAalpha;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::Stddev;


sub longname   { __('VIDYA alpha') }
sub shortname  { __('VIDYA alpha') }
sub manual     { __p('manual-node','Variable Index Dynamic Average') }

use constant
  { type       => 'indicator',
    priority   => -10,
    units      => 'ema_alpha',
    minimum    => 0,
    maximum    => 1,
    parameter_info => [ { name     => __('Fast Days'),
                          key      => 'vidya_fast_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 9 },
                        { name     => __('Slow Days'),
                          key      => 'vidya_slow_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 30 }],
  };

sub new {
  my ($class, $parent, $N_fast, $N_slow) = @_;

  $N_fast //= parameter_info()->[0]->{'default'};
  ($N_fast > 0) || croak "VIDYA bad N_fast: $N_fast";

  $N_slow //= parameter_info()->[1]->{'default'};
  ($N_slow > 0) || croak "VIDYA bad N_slow: $N_slow";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N_fast, $N_slow ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($self_or_class, $N_fast, $N_slow) = @_;
  return App::Chart::Series::Derived::Stddev->warmup_count
    (max ($N_fast, $N_slow));
}
sub proc {
  my ($class, $N_fast, $N_slow) = @_;
  ### VIDYAalpha proc(): $N_fast,$N_slow

  my $fast_proc = App::Chart::Series::Derived::Stddev->proc ($N_fast);
  my $slow_proc = App::Chart::Series::Derived::Stddev->proc ($N_slow);

  # Not sure if the ratio could go above 5, to make an alpha above 1,
  # probably yes with the right data and a small FAST-COUNT, so clamp to 1.

  return sub {
    my ($value) = @_;
    my $slow = $slow_proc->($value);
    my $fast = $fast_proc->($value);
    return ($slow == 0 ? 0
            : min (1, 0.2 * $fast / $slow));
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::VIDYAalpha -- alpha factor for Variable Index Dynamic Average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->VIDYAalpha($N_fast, $N_slow);
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
