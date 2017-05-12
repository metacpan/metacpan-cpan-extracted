# Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::TreePath::Circular;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Gtk2;
use App::Chart::Gtk2::Ex::TreePath::Subclass;
our @ISA = ('App::Chart::Gtk2::Ex::TreePath::Subclass', 'Gtk2::TreePath');

use constant DEBUG => 0;

sub goto_index {
  my ($self, $index) = @_;
  $self->up;
  $self->append_index ($index || 0);
}

sub next {
  my ($self, $model) = @_;
  if (! $model) { croak "TreePath::Circular next needs the tree model"; }
  $self->SUPER::next;
  my ($cur_index) = $self->get_indices;
  my $rows = $model->iter_n_children (undef);
  if ($cur_index >= $rows) {
    $self->goto_index (0);
  }
}

sub prev {
  my ($self, $model) = @_;
  if (! $model) { croak "TreePath::Circular next needs the tree model"; }
  if (! $self->SUPER::prev) {
    # was at position 0, wrap to end
    $self->goto_index (max (0, $model->iter_n_children (undef) - 1));
  }
}

sub row_inserted {
  my ($self, $model, $ins_path, $ins_iter) = @_;
  my ($cur_index) = $self->get_indices;
  my ($ins_index) = $ins_path->get_indices;
  # if inserted before current then advance
  if ($ins_index < $cur_index) { $self->next ($model); }
  if (DEBUG) { print "ins to ", $self->to_string, "\n"; }
}

sub row_deleted {
  my ($self, $model, $del_path) = @_;
  my ($del_index) = $del_path->get_indices;
  my ($cur_index) = $self->get_indices;
  # if deleted before current then decrement
  if ($del_index < $cur_index) { $self->prev ($model); }
  if (DEBUG) { print "del to ", $self->to_string, "\n"; }
}

sub rows_reordered {
  my ($self, $model, $reordered_path, $reordered_iter, $aref) = @_;
  my ($cur_index) = $self->get_indices;
  # follow to new index
  $self->goto_index ($aref->[$cur_index]);
  if (DEBUG) { print "reorder to ", $self->to_string, "\n"; }
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::Ex::TreePath::Circular -- managed path position with wraparound

=for test_synopsis my ($model)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::TreePath::Circular;
 my $path = My::TreePath::Circular->new;

 $path->next ($model);
 $path->prev ($model);

=head1 CLASS HIERARCHY

C<App::Chart::Gtk2::Ex::TreePath::Circular> is a Perl subclass of C<Gtk2::TreePath>,

    Glib::Boxed
      Gtk2::TreePath
        App::Chart::Gtk2::Ex::TreePath::Circular

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::TreePath::Circular> is a version of C<Gtk2::TreePath> designed
to maintain a position in the model's row data and to wrap round from the
end back to the beginning of the rows when necessary.  It's used for
instance by C<Gtk2::Ex::TickerView> to maintain the current item position in
that display.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::TreePath::Circular->new >>

Create and return a new path object.

=item C<< App::Chart::Gtk2::Ex::TreePath::Circular->new_first >>

Create and return a new path object positioned at index 0, ie. the start of
any model's data.

=item C<< App::Chart::Gtk2::Ex::TreePath::Circular->new_from_indices ($index) >>

Create and return a new path object positioned at the given index.  Index 0
is the first in any model.

=item C<< App::Chart::Gtk2::Ex::TreePath::Circular->new_from_string ($str) >>

Create and return a new path object positioned at an index given by a string.

=item C<< $circpath->next ($model) >>

=item C<< $circpath->prev ($model) >>

Step C<$circpath> to the next or previous row in the given C<$model>.  At
the end of the rows C<next> wraps around to the start again, and conversely
at the start C<prev> wraps around to the end.

=item C<< $circpath->row_inserted ($model, $path, $iter) >>

=item C<< $circpath->row_deleted ($model, $path) >>

=item C<< $circpath->rows_reordered ($model, $path, $iter, $aref) >>

Adjust C<$circpath> to maintain it's current position in the presence of the
given changes to C<$model>.  These functions can be called from the
respective model signal, the parameters are the same as to those signals.

=back

=head1 SEE ALSO

L<Gtk2::TreePath>

=cut
