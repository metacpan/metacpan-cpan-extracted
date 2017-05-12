# iter when submodel undef ...


# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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


package App::Chart::Gtk2::Ex::ListOfListsModel;
use 5.008;
use strict;
use warnings;
use Gtk2 1.201;  # 1.201 for drag_data_get() stack fix
use Carp;
use List::Util qw(min max);
use Scalar::Util;

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;
use Gtk2::Ex::TreeModel::ImplBits;

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ 'Gtk2::TreeModel',
                  'Gtk2::TreeDragSource',
                  'Gtk2::TreeDragDest',
                ],
  properties => [ Glib::ParamSpec->object
                  ('list-model',
                   'list-model',
                   'Model of list models to present.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE)
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'n_columns'} = 0;
  $self->{'column_types'} = [];
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if (DEBUG) { print "ListOfListsModel set '$pname'\n"; }

  if ($pname eq 'list_model') {
    if (! $newval->isa('Gtk2::TreeModel')) {
      croak 'ListOfListsModel.list-model object must implement GtkTreeModel interface';
    }
  }
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'list_model') {
    _update_models ($self);
  }
}

sub _update_models {
  my ($self) = @_;
  if (DEBUG) { print "ListOfListsModel _update_models\n"; }

  my $list_model = $self->{'list_model'};
  my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);

  $self->{'list_model_ids'} = $list_model &&
    Glib::Ex::SignalIds->new
        ($list_model,
         $list_model->signal_connect
         (row_changed   =>\&_do_toplevel_row_changed, $ref_weak_self),
         $list_model->signal_connect
         (row_deleted   =>\&_do_toplevel_row_deleted, $ref_weak_self),
         $list_model->signal_connect
         (row_inserted  =>\&_do_toplevel_row_inserted, $ref_weak_self),
         $list_model->signal_connect
         (rows_reordered=>\&_do_toplevel_rows_reordered, $ref_weak_self));

  my @mlist;
  my $n_columns = 0;
  my @column_types;

  if ($list_model) {
    if (DEBUG) { print "  list_model $list_model\n"; }
    $n_columns = $self->{'list_model_n_columns'} = $list_model->get_n_columns;
    @column_types = map {$list_model->get_column_type($_)} (0..$n_columns-1);
    my $submodel;

    #     for (my $iter = $list_model->get_iter_first, my $mnum = 0;
    #          $iter;
    #          $iter = $list_model->iter_next ($iter), $mnum++) {

    for (my $mnum = 0; ; $mnum++) {
      if (DEBUG) { print "  mnum $mnum\n"; }
      my $iter = $list_model->iter_nth_child (undef, $mnum) || last;
      my $model = $list_model->get_value ($iter, 0);
      $submodel ||= $model;

      my $has_child = ($model && $model->iter_n_children(undef) != 0 ? 1 : 0);
      my $minfo = { model     => $model,
                    mnum      => $mnum,
                    self      => $self,
                    has_child => $has_child };
      Scalar::Util::weaken ($minfo->{'self'});
      push @mlist, $minfo;

      if ($model) {
        $minfo->{'ids'} = Glib::Ex::SignalIds->new
          ($model,
           $model->signal_connect
           (row_changed    => \&_do_sublist_row_changed, $minfo),
           $model->signal_connect
           (row_deleted    => \&_do_sublist_row_deleted, $minfo),
           $model->signal_connect
           (row_inserted   => \&_do_sublist_row_inserted, $minfo),
           $model->signal_connect
           (rows_reordered => \&_do_sublist_rows_reordered, $minfo));
      }
    }

    if ($submodel) {
      my $sub_columns = $submodel->get_n_columns;
      $n_columns += $sub_columns;
      push @column_types,
        map {$submodel->get_column_type($_)} (0 .. $sub_columns-1);
    }
  }

  $self->{'mlist'} = \@mlist;
  $self->{'n_columns'} = $n_columns;
  $self->{'column_types'} = \@column_types;

  if (DEBUG) {
    local $, = ' ';
    print "  column_types",@column_types,"\n";
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
  if (DEBUG >= 2) { print "ListOfListsModel get_n_columns\n"; }
  return $self->{'n_columns'};
}

# gtk_tree_model_get_column_type
#
sub GET_COLUMN_TYPE {
  return $_[0]->{'column_types'}->[$_[1]];
}

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;
  if (DEBUG >= 2) { print "ListOfListsModel get_iter, path='",
                      $path->to_string,"'\n"; }
  my $depth = $path->get_depth;
  $self->{'list_model'} || return undef; # when no models
  my ($top_index, $sub_index) = $path->get_indices;

  if ($depth == 1) {
    # top-level
    return [ $self->{'stamp'}, $top_index, undef, undef ];
  }
  if ($depth == 2) {
    # sub-list
    my $minfo = $self->{'mlist'}->[$top_index] || return undef;
    return [ $self->{'stamp'}, $sub_index, $minfo, undef ];
  }
  return undef;
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  if (DEBUG >= 2) { print "ListOfListsModel get_path\n"; }
  my ($index, $minfo) = _iter_validate ($self, $iter);
  if (defined $minfo) {
    my $mnum = $minfo->{'mnum'};
    return Gtk2::TreePath->new_from_indices ($mnum, $index);
  } else {
    return Gtk2::TreePath->new_from_indices ($index);
  }
}

# gtk_tree_model_get_value
#
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  if (DEBUG >= 2) { print "ListOfListsModel get_value\n";
                    print "  iter=",$iter->[0],",",$iter->[1],",",
                      defined $iter->[2] ? $iter->[2] : 'undef',
                        " col=$col\n"; }

  my ($index, $minfo) = _iter_validate ($self, $iter);
  my $list_model_n_columns = $self->{'list_model_n_columns'};
  my $model;

  if ($col < $list_model_n_columns) {
    # columns of list_model
    $model = $self->{'list_model'} || return undef;
    if ($minfo) {
      # $iter is a submodel row
      $index = $minfo->{'mnum'};
    }

  } else {
    # columns of submodels
    if (! $minfo) {
      if (DEBUG >= 2) { print "  submodel col empty in toplevel row\n"; }
      return;
    }
    $col -= $list_model_n_columns;
    $model = $minfo->{'model'} || return undef;
    if (DEBUG >= 2) { print "  submodel adj col=$col\n"; }
  }

  my $subiter = $model->iter_nth_child(undef,$index) || do {
    if (DEBUG >= 2) { print "  cannot get subiter $model index=$index\n"; }
    return undef;
  };
  return $model->get_value ($subiter, $col);
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;
  if (DEBUG >= 2) { print "ListOfListsModel iter_next\n"; }
  my ($index, $minfo) = _iter_validate ($self, $iter);

  $index++;
  if ($minfo) {
    # next in submodel
    my $model = $minfo->{'model'} || return undef;
    if ($index < $model->iter_n_children(undef)) {
      return [ $self->{'stamp'}, $index, $minfo, undef ];
    }

  } else {
    # next in toplevel
    if ($index < scalar @{$self->{'mlist'}}) {
      return [ $self->{'stamp'}, $index, undef, undef ];
    }
  }
  return undef;
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "ListOfListsModel iter_children\n"; }
  return ITER_NTH_CHILD ($self, $iter, 0);
}

# gtk_tree_model_iter_has_child
#
sub ITER_HAS_CHILD {
  my ($self, $iter) = @_;
  if (DEBUG) { print "ListOfListsModel has_child ",$iter->[1],"\n"; }

  # Note: prior to Gtk2-Perl 1.190 the return had to be a number, not any
  # old boolean
  return ITER_N_CHILDREN($self,$iter) != 0;
}

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "ListOfListsModel iter_n_children\n"; }

  if (! defined $iter) {
    # asking about top-levels
    if (DEBUG) { print "  toplevel has ",scalar @{$self->{'mlist'}},"\n"; }
    return scalar @{$self->{'mlist'}};
  }
  my ($index, $minfo) = _iter_validate ($self, $iter);

  if ($minfo) {
    # asking about under submodel
    if (DEBUG) { print "  nothing under submodel rows\n"; }
    return 0;
  } else {
    # asking about under toplevel row
    $minfo = $self->{'mlist'}->[$index] || return 0;
    my $model = $minfo->{'model'} || return 0;
    if (DEBUG) { print "  model row has",$model->iter_n_children(undef),"\n"; }
    return $model->iter_n_children(undef);
  }
}

# gtk_tree_model_iter_nth_child
#
sub ITER_NTH_CHILD {
  my ($self, $iter, $n) = @_;
  if (DEBUG) { print "ListOfListsModel iter_nth_child",
                 " index=",$iter?$iter->[1]:'<iter undef>',
                   " minfo=",($iter&&$iter->[2])||'undef',
                     " child n=$n\n"; }

  my $mlist = $self->{'mlist'};
  if (defined $iter) {
    my ($index, $minfo) = _iter_validate ($self, $iter);
    if (! $minfo) {
      # $n'th row of model under toplevel $index
      if ($minfo = $mlist->[$index]) {
        if (my $model = $minfo->{'model'}) {
          if ($n < $model->iter_n_children(undef)) {
            if (DEBUG) { print "  yes, submodel $model row $n\n"; }
            return [ $self->{'stamp'}, $n, $minfo, undef ];
          }
        }
      }
    }
  } else {
    # $n'th row of top-level
    if ($n < @$mlist) {
      if (DEBUG) { print "  yes, toplevel row $n\n"; }
      return [ $self->{'stamp'}, $n, undef, undef ];
    }
  }
  if (DEBUG) { print "  no\n"; }
  return undef;
}

# gtk_tree_model_iter_parent
#
sub ITER_PARENT {
  my ($self, $iter) = @_;
  if (DEBUG) { print "ListOfListsModel iter_parent\n"; }

  my ($index, $minfo) = _iter_validate ($self, $iter);
  if (defined $minfo) {
    if (DEBUG) { print "  yes, up to toplevel ",$minfo->{'mnum'},"\n"; }
    return [ $self->{'stamp'}, $minfo->{'mnum'}, undef, undef ];
  }
  if (DEBUG) { print "  no\n"; }
  return undef;
}

# gtk_tree_model_ref_node
# gtk_tree_model_unref_node


#------------------------------------------------------------------------------
# our iters

# return ($mnum, $minfo), with $minfo undef on toplevel rows
sub _iter_validate {
  my ($self, $iter) = @_;
  if ($iter->[0] != $self->{'stamp'}) {
    croak "iter is not for this ", ref($self),
      " (stamp ", $iter->[0], " want ", $self->{'stamp'}, ")\n";
  }
  return ($iter->[1], $iter->[2]);
}

sub _top_index_to_iterobj {
  my ($self, $mnum) = @_;
  return Gtk2::TreeIter->new_from_arrayref ([ $self->{'stamp'}, $mnum, undef, undef ]);
}

sub _sub_index_to_iterobj {
  my ($self, $minfo, $index) = @_;
  return Gtk2::TreeIter->new_from_arrayref ([ $self->{'stamp'}, $index, $minfo, undef]);
}

sub _iterobj_validate {
  my ($self, $iterobj) = @_;
  if (! defined $iterobj) {
    croak 'iter is undef';
  }
  my $iter = Gtk2::TreeIter->to_arrayref ($self->{'stamp'});
  return ($iter->[1], $iter->[2]);
}


#------------------------------------------------------------------------------
# 'list_model' toplevel signals

# 'row-changed' on the toplevel list-model
#
sub _do_toplevel_row_changed {
  my ($model, $path, $subiter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListOfListsModel toplevel row_changed handler\n";}
  if ($path->get_depth != 1) { return; }  # ignore non-toplevel

  my ($mnum) = $path->get_indices;
  my $old_minfo = $self->{'mlist'}->[$mnum];
  my $old_model = $old_minfo && $old_minfo->{'model'};
  my $old_has_child = $old_minfo && $old_minfo->{'has_child'};
  $old_minfo = undef;

  _update_models ($self);

  my $new_minfo = $self->{'mlist'}->[$mnum];
  my $new_model = $new_minfo->{'model'};

  my $iterobj = _top_index_to_iterobj ($self, $mnum);
  $self->row_changed ($path, $iterobj);

  if (! defined $old_has_child ||
      $old_has_child != $new_minfo->{'has_child'}) {
    $self->row_has_child_toggled ($path, $iterobj);
  }

  if (($old_model||0) != ($new_model||0)) {
    if (DEBUG) { print "  different model at $mnum: old ",
                   $old_model||'undef', " new ",$new_model||'undef',"\n";}

    my $old_len = $old_model ? $old_model->iter_n_children(undef) : 0;
    my $new_len = $new_model ? $new_model->iter_n_children(undef) : 0;

    my $changed_len = min ($old_len, $new_len);
    if (DEBUG) { print "  changed_len $changed_len\n"; }
    foreach my $i (0 .. $changed_len - 1) {
      $path = Gtk2::TreePath->new_from_indices ($mnum, $i);
      $iterobj = _sub_index_to_iterobj ($self, $new_minfo, $i);
      $self->row_changed ($path, $iterobj);
    }

    if ($old_len > $changed_len) {
      if (DEBUG) { print "  deleted to $old_len\n"; }
      $path = Gtk2::TreePath->new_from_indices ($mnum, $changed_len);
      foreach ($changed_len .. $old_len - 1) {
        $self->row_deleted ($path);
      }
    }

    if ($new_len > $changed_len) {
      if (DEBUG) { print "  inserted to $old_len\n"; }
      foreach my $i ($changed_len .. $old_len - 1) {
        $path = Gtk2::TreePath->new_from_indices ($mnum, $i);
        $iterobj = _sub_index_to_iterobj ($self, $new_minfo, $i);
        $self->row_inserted ($path, $iterobj);
      }
    }
  }
}

# 'row-inserted' on the toplevel list-model
#
sub _do_toplevel_row_inserted {
  my ($model, $path, $subiter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListOfListsModel toplevel row_inserted handler\n";}
  if ($path->get_depth != 1) { return; }  # ignore non-toplevel

  _update_models ($self);
  my ($mnum) = $path->get_indices;
  my $iterobj = _top_index_to_iterobj ($self, $mnum);
  $self->row_inserted ($path, $iterobj);
}

# 'row-deleted' on the toplevel list-model
#
sub _do_toplevel_row_deleted {
  my ($model, $path, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListOfListsModel toplevel row_deleted handler\n";}
  if ($path->get_depth != 1) { return; }  # ignore non-toplevel

  _update_models ($self);
  $self->row_deleted ($path);
}

# 'rows-reordered' on the toplevel list-model
#
sub _do_toplevel_rows_reordered {
  my ($model, $path, $iter, $aref, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListOfListsModel toplevel rows_reordered handler\n";}
  if ($path->get_depth != 0) { return; } # ignore non-toplevel

  _update_models ($self);
  $self->rows_reordered ($path, undef, @$aref);
}

#------------------------------------------------------------------------------
# sub-model signals

# 'row-changed' on sub-list
#
sub _do_sublist_row_changed {
  my ($model, $subpath, $subiter, $minfo) = @_;
  my $self = $minfo->{'self'} || return;

  if (DEBUG) { print "ListOfListsModel submodel row_changed handler\n";}
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my $mnum = $minfo->{'mnum'};
  my ($index) = $subpath->get_indices;
  my $path = Gtk2::TreePath->new_from_indices ($mnum, $index);
  my $iterobj = _sub_index_to_iterobj ($self, $minfo, $index);
  $self->row_changed ($path, $iterobj);
}

# 'row-inserted' on sub-list
#
sub _do_sublist_row_inserted {
  my ($model, $subpath, $subiter, $minfo) = @_;
  my $self = $minfo->{'self'} || return;

  if (DEBUG) { print "ListOfListsModel submodel row_inserted handler\n";}
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my $mnum = $minfo->{'mnum'};
  my ($index) = $subpath->get_indices;
  my $path = Gtk2::TreePath->new_from_indices ($mnum, $index);
  my $iterobj = _sub_index_to_iterobj ($self, $minfo, $index);
  $self->row_inserted ($path, $iterobj);

  if (! $minfo->{'has_child'} && $model->iter_n_children(undef) != 0) {
    # newly become with-children
    $minfo->{'has_child'} = 1;
    $path->up;
    my $iterobj = _top_index_to_iterobj ($self, $mnum);
    $self->row_has_child_toggled ($path, $iterobj);
  }
}

# 'row-deleted' on sub-list
#
sub _do_sublist_row_deleted {
  my ($model, $subpath, $minfo) = @_;
  my $self = $minfo->{'self'} || return;

  if (DEBUG) { print "ListOfListsModel submodel row_deleted handler\n";}
  if ($subpath->get_depth != 1) { return; }  # ignore non-toplevel

  my $mnum = $minfo->{'mnum'};
  my $path = $subpath->copy;
  $path->prepend_index ($mnum);
  $self->row_deleted ($path);

  if ($minfo->{'has_child'} && $model->iter_n_children(undef) == 0) {
    # newly become no-children
    $minfo->{'has_child'} = 0;
    $path->up;
    my $iterobj = _top_index_to_iterobj ($self, $mnum);
    $self->row_has_child_toggled ($path, $iterobj);
  }
}

# 'rows-reordered' on sub-list
#
sub _do_sublist_rows_reordered {
  my ($model, $subpath, $subiter, $aref, $minfo) = @_;
  my $self = $minfo->{'self'} || return;

  if (DEBUG) { print "ListOfListsModel submodel rows_reordered handler\n";}
  if ($subpath->get_depth != 0) { return; } # ignore non-toplevel

  my $mnum = $minfo->{'mnum'};
  my $path = Gtk2::TreePath->new_from_indices ($mnum);
  my $iterobj = _top_index_to_iterobj ($self, $mnum);
  $self->rows_reordered ($path, $iterobj, @$aref);
}


#------------------------------------------------------------------------------
# Gtk2::TreeStore compatible methods

# gtk_tree_store_append
# gtk_tree_store_prepend
sub append {
  push @_, 'append';
  goto _Xpend;
}
sub prepend {
  push @_, 'prepend';
  goto _Xpend;
}
sub _Xpend {
  my ($self, $parent_iterobj, $method) = @_;
  my ($model, $minfo, $subiter);
  if (! defined $parent_iterobj) {
    # append to toplevel
    $model = $self->{'list_model'};
    $subiter = $model->$method;
  } else {
    my $index;
    ($index, $minfo) = _iterobj_validate ($parent_iterobj);
    if ($minfo) { croak 'cannot append under sub-row'; }
    # append to submodel, ie. under a toplevel row
    $minfo = $self->{'mlist'}->[$index] || croak 'no such row (bad iter)';
    $model = $minfo->{'model'};
    $subiter = $model->$method;
  }
  if (! $subiter) { return undef; }
  my ($index) = $model->get_path($subiter)->get_indices;
  return Gtk2::TreeIter->new_from_arrayref ([ $self->{'stamp'}, $index, $minfo, undef]);
}

# gtk_tree_store_is_ancestor
sub is_ancestor {
  my ($self, $parent_iterobj, $child_iterobj) = @_;
  my ($parent_index, $parent_minfo) = _iterobj_validate ($parent_iterobj);
  if ($parent_minfo) { return 0; }  # a submodel row
  my ($child_index, $child_minfo) = _iterobj_validate ($child_iterobj);
  return defined $child_minfo;  # only if a submodel row
}

# gtk_tree_store_iter_depth
sub iter_depth {
  my ($self, $iterobj) = @_;
  my ($index, $minfo) = _iterobj_validate ($iterobj);
  return $minfo ? 2 : 1;
}

# gtk_tree_store_clear
sub clear {
  my ($self) = @_;
  my $list_model = $self->{'list_model'} || return;
  $list_model->clear;
}

# gtk_tree_store_iter_is_valid
# this is not quite right
# if $iter->[2] is bogus it probably causes a segv when treated as an RV
sub iter_is_valid {
  my ($self, $iterobj) = @_;
  my $iter = eval { $iterobj->to_arrayref($self->{'stamp'}) };
  my $index = $iter->[1];
  my $minfo = $iter->[2];
  if (defined $minfo) {
    return List::Util::first {$_ == $minfo} @{$self->{'mlist'}}
      && $index < $minfo->{'model'}->iter_n_children(undef);
  } else {
    return $index < scalar @{$self->{'mlist'}};
  }
}

sub remove {
  my ($self, $iterobj) = @_;
  my ($index, $minfo) = _iterobj_validate ($iterobj);
  my $model = $minfo ? $minfo->{'model'} : $self->{'list_model'};
  my $subiter = $model->iter_nth_child (undef, $index)
    || croak 'no such row (bad iter)';
  if ($model->remove ($subiter)) {
    # more rows
    $iterobj->set([$self->{'stamp'}, $index+1, $minfo, undef]);
    return 1;
  } else {
    $iterobj->set([0,0,undef,undef]); # zap
    return 0;
  }
}

# gtk_tree_store_reorder
# Gtk2::TreeStore reorder() taking multiple args
sub reorder {
  my ($self, $iterobj, @order) = @_;
  if ($iterobj) {
    my ($index, $minfo) = _iterobj_validate ($iterobj);
    if ($minfo) {
      croak 'nothing under sub-row';
    }
    $minfo = $self->{'mlist'}->[$index] || croak 'iter out of range';
    my $model = $minfo->{'model'} || croak 'no submodel';
    $model->reorder (@order);

  } else {
    # toplevel
    $self->{'list_model'}->reorder (@order);
  }
}


#------------------------------------------------------------------------------
# other methods

sub path_for_model {
  my ($self, $model) = @_;
  my $mlist = $self->{'mlist'};
  foreach my $minfo (@$mlist) {
    my $this_model = $minfo->{'model'} || next;
    if ($model == $this_model) {
      return Gtk2::TreePath->new_from_indices ($minfo->{'mnum'});
    }
  }
  return undef;
}


#------------------------------------------------------------------------------
# drag source

# gtk_tree_drag_source_row_draggable ($self, $path)
#
sub ROW_DRAGGABLE {
  unshift @_, 'row_draggable';
  goto &_drag_source;
}

# gtk_tree_drag_source_drag_data_delete ($self, $path)
#
sub DRAG_DATA_DELETE {
  unshift @_, 'drag_data_delete';
  goto &_drag_source;
}

# gtk_tree_drag_source_drag_data_get
#
sub DRAG_DATA_GET {
  my ($self, $path, $sel) = @_;
  unshift @_, 'drag_data_get';  # needing Gtk2 1.200
  goto &_drag_source;
}

sub _drag_source {
  my ($method, $self, $path, @sel) = @_;
  if (DEBUG) { print "ListOfLists \U$method\E path=",$path->to_string,"\n"; }

  my ($model, $subpath) = _drag_path ($self, $path)
    or return 0;  # path no good

  if (! $model->isa('Gtk2::TreeDragSource')) {
    if (DEBUG) { print "  no, model not a TreeDragSource\n"; }
    return 0;
  }
  if (DEBUG) { print "  submodel $model ->$method subpath=",
                 $subpath->to_string,"\n"; }
  my $ret = $model->$method ($subpath, @sel);
  if (DEBUG) { print "  ",$ret?"yes":"no","\n"; }
  return $ret;
}

sub _drag_path {
  my ($self, $path) = @_;

  my $depth = $path->get_depth;
  if ($depth == 1) {
    # toplevel row
    return ($self->{'list_model'}, $path);
  }
  if ($depth == 2) {
    my ($top_index, $sub_index) = $path->get_indices;
    my $minfo = $self->{'mlist'}->[$top_index] || do {
      if (DEBUG) { print "  no, toplevel index out of range\n"; }
      return;
    };
    my $model = $minfo->{'model'} || do {
      if (DEBUG) { print "  no, no submodel (undef) at this row\n"; }
      return;
    };
    $path = Gtk2::TreePath->new_from_indices ($sub_index);
    return ($model, $path);
  }
  if (DEBUG) { print "  no, not depth 1 or 2\n"; }
  return;
}

#------------------------------------------------------------------------------
# drag destination

# gtk_tree_drag_dest_row_drop_possible
#
sub ROW_DROP_POSSIBLE {
  my ($self, $dst_path, $sel) = @_;
  if (DEBUG) { print "ListOfLists ROW_DROP_POSSIBLE, to path=",
                 $dst_path->to_string," type=",$sel->type->name,"\n";
               if ($sel->type->name eq 'GTK_TREE_MODEL_ROW') {
                 my ($src_model, $src_path) = $sel->get_row_drag_data;
                 print "  src_model=$src_model src_path=",
                   $src_path->to_string,"\n";
               }}

  my ($model, $subpath) = _drag_path ($self, $dst_path)
    or return 0;  # path no good

  # if the submodel implements DragDest and it's prepared to accept $sel
  # directly
  if ($model->isa('Gtk2::TreeDragDest')) {
    if ($model->row_drop_possible ($subpath, $sel)) {
      if (DEBUG) { print "  yes, submodel row_drop_possible()\n"; }
      return 1;
    }
  }

  if (DEBUG) { print "  no, submodel refuses\n"; }
  return 0;
}

# gtk_tree_drag_dest_drag_data_received
#
sub DRAG_DATA_RECEIVED {
  my ($self, $dst_path, $sel) = @_;
  if (DEBUG) { print "ListOfLists DRAG_DATA_RECEIVED, to path=",
                 $dst_path->to_string," type=",$sel->type->name,"\n";
               if ($sel->type->name eq 'GTK_TREE_MODEL_ROW') {
                 my ($src_model, $src_path) = $sel->get_row_drag_data;
                 print "  src_model=$src_model src_path=",
                   $src_path->to_string,"\n";
               }}

  my $dst_model;
  ($dst_model, $dst_path) = _drag_path ($self, $dst_path)
    or return 0;  # path no good

  if ($dst_model->isa('Gtk2::TreeDragDest')) {
    if ($dst_model->drag_data_received ($dst_path, $sel)) {
      if (DEBUG) { print "  accepted by submodel\n";}
      return 1;
    }
  }

  if (DEBUG) { print "  no, dest won't accept\n";}
  return 0;
}

1;
__END__

=for stopwords submodel submodels ListOfLists TreeDragSource TreeDragDest toplevel Gtk ie ListofLists Eg TreeModel iter iters Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::ListOfListsModel -- two-level tree model presenting lists

=for test_synopsis my ($mmod)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::ListOfListsModel;
 my $ll = App::Chart::Gtk2::Ex::ListOfListsModel->new (list_model => $mmod);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Ex::ListOfListsModel> is a subclass of C<Glib::Object>.

    Glib::Object
      App::Chart::Gtk2::Ex::ListOfListsModel

and implements the interfaces

    Gtk2::TreeModel
    Gtk2::TreeDragSource
    Gtk2::TreeDragDest

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::ListOfListsModel> presents a set of list models as a
two level tree,

    Toplevel row 0
        Submodel 0 row 0
        Submodel 0 row 1
        Submodel 0 row 2
    Toplevel row 1
        Submodel 1 row 0
        Submodel 1 row 1

The C<list-model> property is a model containing submodel objects.  Column 0
in C<list-model> should be the submodel objects.  Changes in that
C<list-model> and changes in the submodels are all reported up through the
ListOfLists.

The columns in the ListOfLists are those of C<list-model> followed by those
of the submodels.  The submodels are expected to all have the same number of
columns and column types.  So

    +-----------+-----------+-----------+-----------+-----------+
    | LL col 0  | LL col 1  | LL col 2  | LL col 3  | LL col 4  |
    +-----------+-----------+-----------+-----------+-----------+

with 2 columns in C<list-store> and 3 in the submodels would be

    +-----------+-----------+-----------+-----------+-----------+
    | top col 0 | top col 1 | sub col 0 | sub col 1 | sub col 2 |
    +-----------+-----------+-----------+-----------+-----------+

=head2 Drag and Drop

ListOfLists implements TreeDragSource and TreeDragDest, allowing rows to be
moved by dragging in a C<Gtk2::TreeView> or similar.  Dragging is delegated
to the C<list-model> and the submodels.  So a row can be dragged if its
model implements TreeDragSource, and a position can be a drop if its model
implements TreeDragDest.  The effect is that you can drag to re-order the
toplevel rows, and drag within the submodels and perhaps between them.

Dragging between models depends on the destination model being prepared to
accept the source row offered.  For example as of Gtk 2.12 a
C<Gtk2::ListStore> only accepts its own rows (ie. a re-ordering of itself),
not rows from other models, even if the column types seem compatible.  If
that's not enough for you the suggestion is to wrap or subclass the
offending models to make them accept more.

=head1 PROPERTIES

=over 4

=item C<list-model> (C<Glib::Object> implementing C<Gtk2::TreeModel>)

A model containing the submodels to present.  It's expected to be a list
type model (ie. just one level), but currently that's not checked or
enforced.

Currently when the C<list-model> property is changed there's no
C<row-inserted> / C<row-deleted> etc signals emitted by the ListofLists to
announce the new or altered data presented.  Perhaps this will change.  The
disadvantage is that changing to or from a big model could generate
thousands of fairly pointless signals.  The suggestion is to treat
C<list-model> as if it were "construct-only" and make a new ListOfLists for
a new set of models.

=back

=head1 FUNCTIONS

=over 4

=item C<< $ll = App::Chart::Gtk2::Ex::ListOfListsModel->new (key=>value,...) >>

Create and return a new ListOfLists object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.  Eg.

    my $ll = App::Chart::Gtk2::Ex::ListOfListsModel->new (list_model => $mmod);

=back

=head1 SIGNALS

The TreeModel interface as implemented by ListOfLists provides the following
usual signals

    row-changed    ($ll, $path, $iter, $userdata)
    row-inserted   ($ll, $path, $iter, $userdata)
    row-deleted    ($ll, $path, $userdata)
    rows-reordered ($ll, $path, $iter, $arrayref, $userdata)

When a change occurs in a sub-model the corresponding signal is reported up
through the ListOfLists too.  Of course the path and iter reported are in
the list-of-lists tree coordinates and iters, not the sub-models'.

=head1 LIMITATIONS

The C<ref_node> and C<unref_node> methods are no-ops.  The intention is to
apply them down on the sub-models, but hopefully without needing lots of
bookkeeping in the ListOfLists as to what's currently reffed.

It mostly works to have the same submodel appear in multiple toplevel rows,
it's simply presented at each of those points.  The C<row-deleted> and
C<row-inserted> signals are emitted on the ListOfLists the right number of
times, but the multiple changes are all present in the data as of the first
emit, which could potentially confuse handler code.  (The idea could be some
sort of temporary index mapping to make the changes seem one-at-a-time for
the handlers.)

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::ListStore>, L<Glib::Object>

L<Gtk2::Ex::ListModelConcat>, a similar thing as one level.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-listoflistsmodel/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
