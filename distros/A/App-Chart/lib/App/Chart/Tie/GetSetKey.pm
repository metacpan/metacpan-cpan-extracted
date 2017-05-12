# Copyright 2010 Kevin Ryde

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

package App::Chart::Tie::GetSetKey;
use strict;
use warnings;

1;
__END__

sub new_ref {
  my $class = shift;
  tie (my $tie, @_);
  return \$tie;
}
sub TIESCALAR {
  my ($class, $obj, $key, $newval) = @_;
  my $oldval = $obj->get($key);
  my $self = bless [$obj, $key, $oldval], $class;
  Scalar::Util::weaken ($self->[1]);
  if (@_ >= 4) {
    $obj->set($key, $value);
  }
  return $self;
}
sub FETCH {
  my ($self) = @_;
  my $obj = $self->[0] || return;
  return $obj->get($self->[1]);
}
sub STORE {
  my ($self, $value) = @_;
  my $obj = $self->[0] || return;
  return $obj->set($self->[1], $value);
}
sub UNTIE {
  my ($self) = @_;
  my $obj = $self->[0] || return;
  return $obj->set($self->[1], $self->[2]);
}
  
1;
__END__
