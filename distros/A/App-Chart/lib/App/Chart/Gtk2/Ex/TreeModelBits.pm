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


package App::Chart::Gtk2::Ex::TreeModelBits;
use 5.010;
use strict;
use warnings;
use Gtk2;

# return a new iter which is the last child under the given $iter
# $iter can be undef to get the last top-level
# if there's no children under $iter the return is undef
sub _model_iter_last_child {
  my ($model, $iter) = @_;
  my $nchildren = $model->iter_n_children ($iter);

  # $n==-1 returns undef already
  #  if ($nchildren == 0) { return undef; }

  return $model->iter_nth_child ($iter, $nchildren - 1);
}

1;
__END__
