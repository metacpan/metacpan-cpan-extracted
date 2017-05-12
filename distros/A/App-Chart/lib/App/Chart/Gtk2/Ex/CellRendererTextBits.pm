# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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


package App::Chart::Gtk2::Ex::CellRendererTextBits;
use 5.008;
use Carp;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;

sub renderer_edited_set_value {
  my ($renderer, $dest, $column_num) = @_;
  defined $column_num or croak 'No column number supplied';
  my @userdata = ($dest, $column_num);
  require Scalar::Util;
  Scalar::Util::weaken ($userdata[0]);
  $renderer->signal_connect (edited => \&_renderer_edited_set_value_handler,
                             \@userdata);
}
sub _renderer_edited_set_value_handler {
  my ($renderer, $pathstr, $newtext, $userdata) = @_;
  my ($dest, $column_num) = @$userdata;

  if ($dest->can('get_tree_view')) {
    # on Gtk2::TreeViewColumn go to the Gtk2::TreeView
    $dest = $dest->get_tree_view || croak 'No viewer from get_tree_view';
  }
  if (my $pspec = $dest->find_property('model')) {
    if ($pspec->get_value_type eq 'Gtk2::TreeModel') {
      # on Gtk2::TreeView, or Gtk2::CellView, etc, go to the Gtk2::TreeModel
      $dest = $dest->get('model')
        || croak 'No model from get_model';
    }
  }
  my $path = Gtk2::TreePath->new_from_string ($pathstr);
  my $iter = $dest->get_iter ($path)
    || croak "Path $pathstr not found in model";
  ### renderer_edited_set_value() set_value "path=$pathstr col=$column_num"
  $dest->set_value ($iter, $column_num, $newtext);
}

1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::CellRendererTextBits -- helpers for Gtk2::CellRendererText objects

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::CellRendererTextBits;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::CellRendererTextBits::renderer_edited_set_value ($renderer, $view_or_model, $column_num) >>

Setup C<$renderer> so that when edited the new value is stored to the given
view or model C<$column_num> using a C<set_value()> such as ListStore and
TreeStore implement.

The underlying model doesn't have to be a ListStore or TreeStore, anything
with a C<set_value()> is fine.  C<$view_or_model> can be any of

=over 4

=item *

A viewer widget with a C<model> property, such as C<Gtk2::CellView>.  The
model it's showing when edited is used.

=item *

A viewer object with a C<get_tree_view> method, such as
C<Gtk2::TreeViewColumn> of Gtk 2.12 and up, returning a C<Gtk2::TreeView> or
similar which in turn has a C<model> property.  When packing a renderer in a
TreeViewColumn just pass that column and the TreeView and model it's showing
when edited is used.

=item *

A C<Gtk2::TreeModel> with a C<set_value> method, for direct use.  It might
sometimes make sense to store into a different model than the one being
viewed, but the paths (Gtk2::TreePath coordinates) must be the same.

=back

Usually the C<$column_num> to write back is the same column displayed by the
renderer, per C<add_attribute()>.  But there's no way to automatically
extract that from the renderer/viewer setup (as of Gtk 2.20) so it must be
supplied here.

If you're using a single renderer in multiple viewers or columns then this
function is no good because it records a single destination viewer/model and
column within the renderer.

=back

=head1 SEE ALSO

L<Gtk2::CellRendererText>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
