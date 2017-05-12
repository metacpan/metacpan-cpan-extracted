# Copyright 2011 Kevin Ryde

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

package App::Chart::Math::Moving;
require 5;
use strict;

use constant warmup_count => 0;
use constant parameter_info_array => [];

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;
  foreach my $pinfo (@{$self->parameter_info_array}) {
    if (! exists $self->{$pinfo->{'name'}}) {
      $self->{$pinfo->{'name'}} = $pinfo->{'default'};
    }
  }
}

1;
__END__
