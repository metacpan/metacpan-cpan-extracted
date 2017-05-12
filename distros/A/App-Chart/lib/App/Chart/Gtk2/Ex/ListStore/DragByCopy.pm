# really should have a way to say what kinds of models are compatible
#     - same num columns
#     - same class, or subclass
# drop text to one column ...


# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Gtk2::Ex::ListStore::DragByCopy;
use 5.008;
use strict;
use warnings;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# drag source

# gtk_tree_drag_source_row_draggable ($self, $src_path)
sub ROW_DRAGGABLE {
  my ($self, $src_path) = @_;
  ### DragByCopy ROW_DRAGGABLE
  ### path: $src_path->to_string
  ### result per get_iter(): $self->get_iter($src_path)

  return $self->get_iter ($src_path);
}

# gtk_tree_drag_source_drag_data_get ($self, $src_path, $sel)
sub DRAG_DATA_GET {
  my ($self, $src_path, $sel) = @_;
  ### DragByCopy DRAG_DATA_GET
  ### src_path: $src_path->to_string
  ### sel type: $sel->type->name

  my $ret = $sel->set_row_drag_data ($self, $src_path);
  ### result: $ret
  return $ret;
}

# gtk_tree_drag_source_drag_data_delete ($self, $src_path)
sub DRAG_DATA_DELETE {
  my ($self, $src_path) = @_;
  ### DragByCopy DRAG_DATA_DELETE
  ### path: $src_path->to_string

  my $iter = $self->get_iter ($src_path) || do {
    ### no, get_iter() returns undef
    return 0;
  };
  # supposed to be rugged against dodginess, so protect here with an eval
  eval { $self->remove ($iter); 1 } || do {
    ### no, error from source remove(): $@
    return 0;
  };
  ### yes
  return 1;
}


#------------------------------------------------------------------------------
# drag dest

# gtk_tree_drag_dest_row_drop_possible
#
sub ROW_DROP_POSSIBLE {
  my ($self, $dst_path, $sel) = @_;
  ### DragByCopy ROW_DROP_POSSIBLE
  ### to path: $dst_path->to_string
  ### type: $sel->type->name

  if ($dst_path->get_depth != 1) {
    ### no, dest path depth: $dst_path->get_depth
    return 0;
  }
  my ($src_model, $src_path) = $sel->get_row_drag_data
    or do {
      ### no, source data not a row
      return 0;
    };

  my $n_columns = $self->get_n_columns;
  if ($src_model->get_n_columns != $n_columns) {
    ### no, different number of columns
    return 0;
  }

  ### yes
  return 1;
}

# gtk_tree_drag_dest_drag_data_received
#
sub DRAG_DATA_RECEIVED {
  my ($self, $dst_path, $sel) = @_;
  ### DragByCopy DRAG_DATA_RECEIVED
  ### to path: $dst_path->to_string
  ### type: $sel->type->name
  ### src model: ($sel->get_row_drag_data)[0]
  ### src path : (($sel->type->name eq 'GTK_TREE_MODEL_ROW') && ($sel->get_row_drag_data)[1]->to_string)

  if ($dst_path->get_depth != 1) {
    ### no, dest path depth: $dst_path->get_depth
    return 0;
  }
  my ($dst_index) = $dst_path->get_indices;

  my ($src_model, $src_path) = $sel->get_row_drag_data
    or do {
      ### no, source data not a row
      return 0;
    };
  my $src_iter = $src_model->get_iter ($src_path) || do {
    ### no, source get_iter() undef
    return 0;
  };

  # interleaved list (0, 'value0', 1, 'value1', ...) of columns and values
  my @row = map {; ($_, $src_model->get_value($src_iter,$_)) }
    0 .. $src_model->get_n_columns - 1;

  # drag is supposed to be rugged against dodgy stuff, so protect here with
  # an eval
  eval { $self->insert_with_values ($dst_index, @row); 1 } or do {
    ### no, error from insert_with_values(): $@
    return 0;
  };
  ### yes
  return 1;
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::Ex::ListStore::DragByCopy -- drag and drop copying between ListStores

=head1 SYNOPSIS

 package MyStore;
 use Gtk2;
 use base 'App::Chart::Gtk2::Ex::ListStore::DragByCopy';
 use Glib::Object::Subclass
   'Gtk2::ListStore',
   interfaces => [ 'Gtk2::TreeDragSource',
                   'Gtk2::TreeDragDest' ];

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::ListStore::DragByCopy> is designed as a
multi-inheritance mix-in for Perl sub-classes of C<Gtk2::ListStore>.  It
provides versions of the following methods which allow drag-and-drop between
different models.

    ROW_DRAGGABLE
    DRAG_DATA_GET
    DRAG_DATA_DELETE

    ROW_DROP_POSSIBLE
    DRAG_DATA_RECEIVED

Normally ListStore restricts drag and drop to re-ordering rows within a
single model.  With this mix-in rows can be copied to or from any compatible
model, though still only within the same running program.

=head1 FUNCTIONS

=over 4

=item C<< $bool = ROW_DRAGGABLE ($liststore, $src_path) >>

=item C<< $bool = DRAG_DATA_GET ($liststore, $src_path, $selection) >>

=item C<< $bool = DRAG_DATA_DELETE ($liststore, $src_path) >>

The drag methods offer a row as data and delete it with C<remove> when
dragged.

If you want to impose extra conditions on dragging you can write your own
versions of these functions and chain up.  For example if only the first
three rows of the model are draggable then

    sub ROW_DRAGGABLE {
      my ($self, $path) = @_;
      my ($index) = $path->get_indices;
      if ($index >= 3) { return 0; } # not draggable
      return $self->SUPER::ROW_DRAGGABLE ($path);
    }

=item C<< $bool = ROW_DROP_POSSIBLE ($liststore, $dst_path, $selection) >>

=item C<< $bool = DRAG_DATA_RECEIVED ($self, $dst_path, $selection) >>

The drop methods accept a row from any TreeModel.  They get the row data
with C<< $src->get >> and store it with C<< $dst->insert_with_values >>.

=back

=head1 SEE ALSO

L<Gtk2::ListStore>

=cut
