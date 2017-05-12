# Copyright 2009, 2010 Kevin Ryde

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

package App::Chart::Tie::GetSetMethod;
use strict;
use warnings;

sub TIESCALAR {
  my ($class, $obj, $method) = @_;
  my $oldval = $obj->$method;
  return bless [$obj, $method, $oldval], $class;
}
sub FETCH {
  my ($self) = @_;
  my ($obj, $method) = @$self;
  return $obj->$method;
}
sub STORE {
  my ($self, $value) = @_;
  my ($obj, $method) = @$self;
  return $obj->$method ($value);
}
sub UNTIE {
  my ($self) = @_;
  my ($obj, $method, $oldval) = @$self;
  return $obj->$method ($oldval);
}

1;
__END__
