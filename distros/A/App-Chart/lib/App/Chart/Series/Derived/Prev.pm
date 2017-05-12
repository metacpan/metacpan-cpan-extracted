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

package App::Chart::Series::Derived::Prev;
use 5.008;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;
use App::Chart::TZ;
use base 'App::Chart::Series::Indicator';

sub longname   { __('Prev') }
*shortname = \&longname;

use constant
  { manual     => undef,
    type       => 'special',  # for programming mainly
    priority   => -1000,
    parameter_info => [ { name    => __('Days'),
                          key     => 'prev_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  my $p_timebase = $parent->timebase;
  my $timebase = bless { %$p_timebase }, ref $p_timebase;
  $timebase->{'base'} -= $N;

  return $class->SUPER::new
    (timebase => $timebase,
     N        => $N,
     parent   => $parent,
     arrays   => $parent->{'arrays'},
     array_aliases  => $parent->{'array_aliases'});
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  $parent->fill ($lo, $hi);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Prev -- ...
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Series::Derived::Prev;
#  my $series = App::Chart::Series::Derived::Prev->new ($parent, $N);
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
