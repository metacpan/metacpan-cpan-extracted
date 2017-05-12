# Copyright 2008, 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::TreeOfTreesModel;
use strict;
use warnings;
use Gtk2;
use Carp 'croak';
use List::Util 'min','max';

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;
use Gtk2::Ex::TreeModel::ImplBits;

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ 'Gtk2::TreeModel',
                  'Gtk2::TreeDragSource',
                  'Gtk2::TreeDragDest' ],
  properties => [ Glib::ParamSpec->object
                  ('tree-model',
                   'tree-model',
                   'Model of models to present.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE)
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if (DEBUG) { print "TreeOfTreesModel set '$pname'\n"; }
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'tree_model') {
#    _establish_signals ($self);
  }
}

sub _establish_shift {
  my ($self) = @_;
  my $toplen = 0;
  my $n_columns = 0;
  if (my $models = $self->{'models'}) {
    $self->{'toplen'} = $models->iter_n_children(undef);
    if (my $miter = $models->get_iter_first) {
      my $model = $models->get_value ($miter, 0);
      $n_columns = $model->get_n_columns;
    }
  }
  $self->{'toplen'} = max (1, $toplen);
  $self->{'n_columns'} = $n_columns;
}

sub _establish_signals {
  my ($self) = @_;
  my $models = $self->{'models'};
  my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak ($self);

  my @signals
    = (Glib::Ex::SignalIds->new
       ($models,
        $models->signal_connect (row_changed   =>\&_do_models_row_changed,
                                 $ref_weak_self),
        $models->signal_connect (row_deleted   =>\&_do_models_row_deleted,
                                 $ref_weak_self),
        $models->signal_connect (row_inserted  =>\&_do_models_row_inserted,
                                 $ref_weak_self),
        $models->signal_connect (rows_reordered=>\&_do_models_rows_reordered,
                                 $ref_weak_self)));
  $self->{'signals'} = \@signals;

  my $i = 0;
  for (my $miter = $models->get_iter_first;
       $miter;
       $miter = $models->iter_next ($miter), $i++) {
    my $model = $models->get_value ($miter, 0);
    my $userdata = [ $self, $i ];
    Scalar::Util::weaken ($userdata->[0]);

    push @signals, Glib::Ex::SignalIds->new
      ($model,
       $model->signal_connect (row_changed    => \&_do_sublist_row_changed,
                               $userdata),
       $model->signal_connect (row_deleted    => \&_do_sublist_row_deleted,
                               $userdata),
       $model->signal_connect (row_inserted   => \&_do_sublist_row_inserted,
                               $userdata),
       $model->signal_connect (rows_reordered =>\&_do_sublist_rows_reordered,
                               $userdata)
      );
  }
}

# gtk_tree_model_get_flags
#
sub GET_FLAGS {
  return [];
}

# gtk_tree_model_get_n_columns
#
sub GET_N_COLUMNS {
  my ($self) = @_;
  if (DEBUG >= 2) { print "TreeOfTreesModel get_n_columns\n"; }
  return $self->{'n_columns'};
}

# gtk_tree_model_get_column_type
#
sub GET_COLUMN_TYPE {
  my ($self, $col) = @_;
  if (DEBUG >= 2) { print "TreeOfTreesModel get_column_type\n"; }
  my $models = $self->{'models'}
    || return undef; # when no models
  my $miter = $models->get_iter_first
    || return undef; # when no models
  my $model = $models->get_value ($miter, 0);
  return $model->get_column_type ($col);
}

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;
  if (DEBUG >= 2) { print "TreeOfTreesModel get_iter, path='",
                      $path->to_string,"'\n"; }
  my $depth = $path->get_depth;
  if ($depth < 1 || $depth > 2) { return undef; }
  my $models = $self->{'models'}
    || return undef; # when no models

  my ($mnum, $index) = $path->get_indices;
  if (defined $index) {
    # in sublist
    my $miter = $models->iter_nth_child(undef);
    my $model = $models->get_value ($miter, 0);
    if ($index >= $model->iter_n_children(undef)) { return undef; }

  } else {
    # top-level row
    if ($mnum >= $models->iter_n_children(undef)) { return undef; }
  }
  return _index_to_iter ($self, $mnum, $index);
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  if (DEBUG >= 2) { print "TreeOfTreesModel get_path\n"; }
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  if (defined $index) {
    return Gtk2::TreePath->new_from_indices ($mnum, $index);
  } else {
    return Gtk2::TreePath->new_from_indices ($mnum);
  }
}

# gtk_tree_model_get_value
#
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  if (DEBUG >= 2) { print "TreeOfTreesModel get_value iter=",
                      $iter->[0],",",$iter->[1], " col=$col\n"; }
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  my $models = $self->{'models'};
  my $miter = $models->iter_nth_child (undef, $mnum)
    || die 'TreeOfTreesModel: no such model (bad iter)';
  if (defined $index) {
    my $model = $models->get_value ($miter, 0);
    my $subiter = $model->iter_nth_child (undef, $index)
      || die "TreeOfTreesModel: no such sublist row $index (bad iter)";
    return $model->get_value ($subiter, $col);
  } else {
    return undef;
  }
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;
  if (DEBUG >= 2) { print "TreeOfTreesModel iter_next\n"; }
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  my $models = $self->{'models'};

  if (defined $index) {
    # next within sub-list
    my $miter = $models->iter_nth_child (undef, $mnum)
      || die 'TreeOfTreesModel: no such model (bad iter)';
    my $model = $models->get_value ($miter, 0);
    if ($index <= $model->iter_n_children (undef)) {
      return _index_to_iter ($self, $mnum, $index+1);
    }
  } else {
    # next in top-level
    if ($mnum+1 < $models->iter_n_children(undef)) {
      return _index_to_iter ($self, $mnum+1, undef);
    }
  }
  return undef;
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeOfTreesModel iter_children\n"; }
    return ITER_NTH_CHILD ($iter, 0);
}

# gtk_tree_model_iter_has_child
#
sub ITER_HAS_CHILD {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeOfTreesModel has_child ",$iter->[1],"\n"; }
  # Crib note: prior to Gtk2-Perl 1.200 the return had to be a number.
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  return (defined $index);
}

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeOfTreesModel iter_n_children\n"; }
  my $models = $self->{'models'};
  if (! defined $iter) {
    # asking about top-levels
    return $models->iter_n_children (undef);
  }
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  if (! defined $index) {
    # asking about sublist
    my $miter = $models->iter_nth_child (undef, $mnum)
      || die 'TreeOfTreesModel: no such model (bad iter)';
    my $model = $models->get_value ($miter, 0);
    return $model->iter_n_children (undef);
  }
  # asking about under a sublist row
  return 0;
}

# gtk_tree_model_iter_nth_child
#
sub ITER_NTH_CHILD {
  my ($self, $iter, $n) = @_;
  if (DEBUG) { print "TreeOfTreesModel iter_nth_child $n\n"; }
  my $models = $self->{'models'};
  if (! defined $iter) {
    # nth row of top-level
    if ($n < $models->iter_n_children(undef)) {
      return _index_to_iter ($self, $n, undef);
    }
  }
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  if (! defined $index) {
    # nth row of a sub-list
    my $miter = $models->iter_nth_child (undef, $mnum)
      || die 'TreeOfTreesModel: no such model (bad iter)';
    my $model = $models->get_value ($miter, 0);

    if ($n < $model->iter_n_children (undef)) {
      return _index_to_iter ($self, $mnum, $n);
    }
  }
  # undef a sub-list row, or something out-of-range
  return undef;
}

# gtk_tree_model_iter_parent
#
sub ITER_PARENT {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeOfTreesModel iter_parent\n"; }
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  if (defined $index) {
    return _index_to_iter ($self, $mnum, undef);
  } else {
    return undef;
  }
}

#------------------------------------------------------------------------------
# our iters

sub _index_to_iter {
  my ($self, $mnum, $index) = @_;
  my $toplen = $self->{'toplen'};
  if (DEBUG >= 2) { print "  _index_to_iter $mnum ",
                      defined $index ? $index : 'undef',
                        " is ",
                          $mnum + ((defined $index ? $index : 0) * $toplen),
                            "\n"; }
  if (defined $index) {
    # sub-list row
    return [ $self->{'stamp'}, $mnum + ($index * $toplen), undef, undef ];
  } else {
    # top-level row
    return [ $self->{'stamp'}, $mnum, $self, undef ];
  }
}

# return ($mnum, $index)
sub _iter_to_index {
  my ($self, $iter) = @_;
  if (! defined $iter) { return undef; }
  if ($iter->[0] != $self->{'stamp'}) {
    croak "iter is not for this ", ref($self),
      " (stamp ", $iter->[0], " want ", $self->{'stamp'}, ")\n";
  }
  my $n = $iter->[1];
  if (DEBUG >= 2) { print "  _iter_to_index $n,toplen=",$self->{'toplen'},
                      " is ", $n % $self->{'toplen'},
                        " ", int ($n / $self->{'toplen'}), "\n"; }
  if (defined $iter->[2]) {
    # top-level row
    return ($n, undef);
  } else {
    # sub-list row
    my $toplen = $self->{'toplen'};
    return ($n % $toplen, int ($n / $toplen));
  }
}

# return ($mnum, $index)
sub _iterobj_to_index {
  my ($self, $iterobj) = @_;
  if (! defined $iterobj) { croak 'TreeOfTreesModel: iter cannot be undef'; }
  return _iter_to_index ($self, $iterobj->to_arrayref ($self->{'stamp'}));
}
sub _index_to_iterobj {
  my ($self, $mnum, $index) = @_;
  return Gtk2::TreeIter->new_from_arrayref
    (_index_to_iter ($self, $mnum, $index));
}


#------------------------------------------------------------------------------
# sub-model lookups

# return ($model, $subiter, $mnum)
sub _iter_to_subiter {
  my ($self, $iter) = @_;
  my ($mnum, $index) = _iter_to_index ($self, $iter);
  return _index_to_subiter ($self, $index);
}

# return ($model, $subiter, $mnum)
sub _index_to_subiter {
  my ($self, $index) = @_;
  my ($model, $subindex, $mnum) = _index_to_subindex ($self, $index);
  return ($model, $model->iter_nth_child(undef,$subindex), $mnum);
}

# return ($model, $subindex, $mnum)
sub _index_to_subindex {
  my ($self, $index) = @_;
  if ($index < 0) {
    croak 'TreeOfTreesModel: invalid iter (negative index)';
  }
  my $models = $self->{'models'};
  my $positions = _model_positions ($self);
  if ($index >= $positions->[-1]) {
    croak 'TreeOfTreesModel: invalid iter (index too big)';
  }
  for (my $i = $#$positions - 1; $i >= 0; $i--) {
    if ($positions->[$i] <= $index) {
      return ($models->[$i], $index - $positions->[$i], $i);
    }
  }
  croak 'TreeOfTreesModel: invalid iter (no sub-models at all now)';
}

sub _no_submodels {
  my ($operation) = @_;
  croak "TreeOfTreesModel: no sub-models to $operation";
}


#------------------------------------------------------------------------------
# 'models' list signals

# 'row-changed' on the models list
#
sub _do_models_row_changed {
  my ($model, $path, $subiter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeOfTreesModel models row_changed handler\n";}
  if ($path->get_depth != 1) { return; }  # ignore non-toplevel

  my ($mnum) = $path->get_indices;
  my $iterobj = _index_to_iterobj ($self, $mnum, undef);
  $self->row_changed ($path, $iterobj);
}

# 'row-inserted' on the models list
#
sub _do_models_row_inserted {
  my ($model, $path, $subiter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeOfTreesModel models row_inserted handler\n";}
  if ($path->get_depth != 1) { return; }  # ignore non-toplevel

  _establish_shift ($self);
  _establish_signals ($self);

  my ($mnum) = $path->get_indices;
  my $iterobj = _index_to_iterobj ($self, $mnum, undef);
  $self->row_inserted ($path, $iterobj);
}

# 'row-deleted' on the models list
#
sub _do_models_row_deleted {
  my ($model, $path, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeOfTreesModel row_deleted handler\n";}
  if ($path->get_depth != 1) { return; }  # ignore non-toplevel

  _establish_shift ($self);
  _establish_signals ($self);

  $self->row_deleted ($path);
}

# 'rows-reordered' on the models list
#
sub _do_models_rows_reordered {
  my ($model, $path, $iter, $aref, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeOfTreesModel rows_reordered handler\n";}
  if ($path->get_depth != 0) { return; } # ignore non-toplevel

  _establish_signals ($self);

  $self->rows_reordered ($path, undef, @$aref);
}

#------------------------------------------------------------------------------
# sub-lists signals

# 'row-changed' on sub-list
# called multiple times if a model is present multiple times
#
sub _do_sublist_row_changed {
  my ($model, $subpath, $subiter, $userdata) = @_;
  my ($self, $mnum)= @$userdata;
  if (! $self) { return; }
  if (DEBUG) { print "TreeOfTreesModel row_changed handler\n";}
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my ($index) = $subpath->get_indices;
  my $path = Gtk2::TreePath->new_from_indices ($mnum, $index);
  my $iterobj = _index_to_iterobj ($self, $mnum, $index);
  $self->row_changed ($path, $iterobj);
}

# 'row-inserted' on sub-list
#
sub _do_sublist_row_inserted {
  my ($model, $subpath, $subiter, $userdata) = @_;
  my ($self, $mnum) = @$userdata;
  if (! $self) { return; }
  if (DEBUG) { print "TreeOfTreesModel row_inserted handler\n";}
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my ($index) = $subpath->get_indices;
  my $path = Gtk2::TreePath->new_from_indices ($mnum, $index);
  my $iterobj = _index_to_iterobj ($self, $mnum, $index);
  $self->row_inserted ($path, $iterobj);
}

# 'row-deleted' on sub-list
#
sub _do_sublist_row_deleted {
  my ($model, $subpath, $userdata) = @_;
  my ($self, $mnum) = @$userdata;
  if (! $self) { return; }
  if (DEBUG) { print "TreeOfTreesModel row_deleted handler\n";}
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my $path = $subpath->copy;
  $path->prepend_index ($mnum);
  $self->row_deleted ($path);
}

# 'rows-reordered' on sub-list
#
sub _do_sublist_rows_reordered {
  my ($model, $subpath, $subiter, $aref, $userdata) = @_;
  my ($self, $mnum) = @$userdata;
  if (! $self) { return; }
  if (DEBUG) { print "TreeOfTreesModel rows_reordered handler\n";}
  if ($subpath->get_depth != 0) { return; } # ignore non-toplevel

  my $path = Gtk2::TreePath->new_from_indices ($mnum);
  my $iterobj = _index_to_iterobj ($self, $mnum, undef);
  $self->rows_reordered ($path, $iterobj, @$aref);
}

#------------------------------------------------------------------------------
# Gtk2::TreeStore compatible methods

sub iter_is_valid {
  my ($self, $iter) = @_;
  my $a = eval { $iter->to_arrayref($self->{'stamp'}) };
  return ($a && $a->[1] < _total_length($self));
}


1; __END__

=head1 NAME

Gtk2::Ex::TreeOfTreesModel -- concatenated list models

=head1 SYNOPSIS

 use Gtk2::Ex::TreeOfTreesModel;
 my $model = Gtk2::Ex::TreeOfTreesModel->new (models => [$m1,$m2]);

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::TreeOfTreesModel> is a subclass of C<Glib::Object>.

    Glib::Object
      Gtk2::Ex::TreeOfTreesModel

and implements the interfaces

    Gtk2::TreeModel
    Gtk2::TreeDragSource
    Gtk2::TreeDragDest

=head1 DESCRIPTION

C<Gtk2::Ex::TreeOfTreesModel> presents a set of list-type TreeModels
concatenated together as a single list.  A Concat doesn't hold any data
itself, it just presents the sub-models' content.  C<Gtk2::ListStore>
objects are suitable as the sub-models, but any similar list-type model can
be used too.

Changes in the sub-models are reported up through the Concat with the usual
C<row-changed> etc signals.  Conversely change methods are implemented by
Concat in the style of C<Gtk2::ListStore> and if the sub-models have those
functions too (eg. if they're ListStores) then changes on the Concat are
applied down to the sub-models.

The sub-models should all have the same number of columns and the same
column types (or compatible types), though currently TreeOfTreesModel doesn't
try to enforce that.  It works to put one Concat inside another, except of
course it cannot be inside itself (directly or indirectly).

=head2 Drag and Drop

TreeOfTreesModel implements TreeDragSource and TreeDragDest, allowing rows to
be moved by dragging in a C<Gtk2::TreeView> or similar.

A row can be dragged if its sub-model implements the TreeDragSource
interface.  A position can be a drag destination if its sub-model implements
either the TreeDragDest interface or a C<Gtk2::ListStore> style
C<insert_with_values> method.  TreeDragDest is preferred, letting the
submodel take care of data conversion, but the C<insert_with_values>
fallback is needed for drags between different ListStores, since its
TreeDragDest only accepts its own rows.

=head1 PROPERTIES

=over 4

=item C<models> (array reference, default empty C<[]>)

Arrayref of sub-models to concatenate.  The sub-models can be any object
implementing the C<Gtk2::TreeModel> interface.  They should be C<list-only>
type, though currently TreeOfTreesModel doesn't enforce that.

Currently when the C<models> property is changed there's no C<row-inserted>
/ C<row-deleted> etc signals emitted by the Concat to announce the new or
altered data presented.  Perhaps this will change.  The disadvantage would
be that adding or removing a big model could generate thousands of fairly
pointless signals.  The suggestion is to treat C<models> as if it were
"construct-only" and make a new Concat for a new set of models.

=back

=head1 FUNCTIONS

=over 4

=item C<< $concat = Gtk2::Ex::TreeOfTreesModel->new (key=>value,...) >>

Create and return a new Concat object.  Optional key/value pairs set initial
properties as per C<< Glib::Object->new >>.  Eg.

 my $concat = Gtk2::Ex::TreeOfTreesModel->new (models => [$m1,$m2]);

=back

=head1 LISTSTORE METHODS

The following functions are implemented in the style of C<Gtk2::ListStore>
and they call down to corresponding functions in the sub-models.  Those
sub-models don't have to be C<Gtk2::ListStore> objects, they can be some
other class implementing the same methods.

=over 4

=item C<< $concat->clear >>

=item C<< $concat->set_column_types >>

These are applied to all sub-models, so C<clear> clears all the models or
C<set_column_types> sets the types in all the models.

In the current implementation Concat doesn't keep column types itself, but
asks the sub-models when required (using the first sub-model, curently).

=item C<< $iter = $concat->append >>

=item C<< $iter = $concat->insert ($pos) >>

=item C<< $iter = $concat->insert_with_values ($pos, $col,$val, ...) >>

=item C<< $iter = $concat->insert_after ($iter) >>

=item C<< $iter = $concat->insert_before ($iter) >>

=item C<< bool = $concat->iter_is_valid ($iter) >>

=item C<< $concat->move_after ($iter, $iter_from, $iter_to) >>

=item C<< $concat->move_before ($iter, $iter_from, $iter_to) >>

=item C<< $iter = $concat->prepend >>

=item C<< bool = $concat->remove ($iter) >>

=item C<< $concat->reorder (@neworder) >>

=item C<< $concat->swap ($iter_a, $iter_b) >>

=item C<< $concat->set ($iter, $col,$val, ...) >>

=item C<< $concat->set_value ($iter, $col, $val) >>

These are per the C<Gtk2::ListStore> methods.

Note C<set> overrides the C<set> in C<Glib::Object> which normally sets
object properties.  You can use the C<set_property> alias instead.

    $model->set_property ('propname' => $value);

=back

=head1 SIGNALS

The TreeModel interface (implemented by TreeOfTreesModel) provides the
following usual signals

    row-changed    ($concat, $path, $iter, $userdata)
    row-inserted   ($concat, $path, $iter, $userdata)
    row-deleted    ($concat, $path, $userdata)
    rows-reordered ($concat, $path, $iter, $arrayref, $userdata)

Because TreeOfTreesModel is C<list-only>, the path to C<row-changed>,
C<row-inserted> and C<row-deleted> always has depth 1, and the path to
C<rows-reordered> is always depth 0 and the iter there is always C<undef>.

When a change occurs in a sub-model the corresponding signal is reported up
through Concat too.  Of course the path and iter reported by the Concat are
in its "concatenated" coordinates and iters, not the sub-model's.

=head1 BUGS

C<ref_node> and C<unref_node> are no-ops.  The intention is to apply them
down on the sub-models, but hopefully without needing lots of bookkeeping in
the Concat as to what's currently reffed.

It mostly works to have a sub-model appear more than once in a Concat.  The
only outright bug is in the C<remove> method which doesn't update its iter
correctly when removing a row from a second or subsequent copy of a
submodel.  The C<row-deleted> and C<row-inserted> signals are emitted on the
Concat the right number of times, but the multiple inserts/deletes are all
present in the data as of the first emit, which might confuse handler code.
(The idea could be some sort of temporary index mapping to make the changes
seem one-at-a-time for the handlers.)

What does work fine is to have multiple TreeModelFilters selecting different
parts of a single underlying model.  As long as a given row only appears
once it doesn't matter where its ultimate storage location is.

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::TreeDragSource>, L<Gtk2::TreeDragDest>,
L<Gtk2::ListStore>, L<Glib::Object>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-listmodelconcat/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2015 Kevin Ryde

Chart is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Chart is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Chart.  If not, see L<http://www.gnu.org/licenses/>.

=cut
