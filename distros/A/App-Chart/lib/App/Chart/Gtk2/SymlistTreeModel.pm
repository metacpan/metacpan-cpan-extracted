# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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


package App::Chart::Gtk2::SymlistTreeModel;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use Carp;
use Gtk2::Ex::TreeModel::ImplBits;

use App::Chart::Database;

use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ Gtk2::TreeModel:: ];

use constant DEBUG => 0;

use constant { COL_ITEM_SYMBOL       => 0,
               COL_ITEM_COMMENT      => 1,
               COL_SYMLIST_KEY       => 0,
               COL_SYMLIST_NAME      => 1,
               COL_SYMLIST_CONDITION => 2,
               NUM_COLUMNS           => 3
             };

# created on first use, then kept while still in use
use base 'Class::WeakSingleton';
*_new_instance = \&Glib::Object::new;


#------------------------------------------------------------------------------
sub symlist_pos_to_key {
  my ($listnum) = @_;
  return App::Chart::Database::read_notes_single
    ('SELECT key FROM symlist WHERE seq=?', $listnum);
}
sub symlist_key_to_pos {
  my ($key) = @_;
  return App::Chart::Database::read_notes_single
    ('SELECT seq FROM symlist WHERE key=?', $key);
}

sub symlist_content_pos_exists {
  my ($key, $pos) = @_;
  return App::Chart::Database::read_notes_single
    ('SELECT symbol FROM symlist_content WHERE key=? AND seq=?',
     $key, $pos);
}

#------------------------------------------------------------------------------

# 'symlist-list-inserted' broadcast handler
sub _do_symlist_inserted {
  my ($self, $pos, $key) = @_;
  if (DEBUG) { print "SymlistTreeModel list row added\n"; }
  my $path = Gtk2::TreePath->new_from_indices ($pos);
  $self->row_inserted ($path, $self->get_iter($path));
}
# 'symlist-list-deleted' broadcast handler
sub _do_symlist_deleted {
  my ($self, $key, $pos) = @_;
  if (DEBUG) { print "SymlistTreeModel list row deleted\n"; }
  my $path = Gtk2::TreePath->new_from_indices ($pos);
  $self->row_deleted ($path);
}

# 'symlist-content-inserted' broadcast handler
sub _do_symlist_content_inserted {
  my ($self, $key, $pos) = @_;
  if (DEBUG) { print "SymlistTreeModel symbol row added\n"; }
  my $listnum = symlist_key_to_pos ($key);
  my $path = Gtk2::TreePath->new_from_indices ($listnum, $pos);
  my $iter = $self->get_iter ($path);
  $self->row_inserted ($path, $iter);

  # if this symlist now has 1 entry then has_child toggled
  if (! symlist_content_pos_exists ($key, 1)) {
    my $parent_path = Gtk2::TreePath->new_from_indices ($listnum);
    my $parent_iter = $self->get_iter ($path);
    $self->row_has_child_toggled ($parent_path, $parent_iter);
  }
}

# 'symlist-content-deleted' broadcast handler
sub _do_symlist_content_deleted {
  my ($self, $key, $pos) = @_;
  if (DEBUG) { print "SymlistTreeModel symbol row deleted\n"; }
  my $path = Gtk2::TreePath->new_from_indices (symlist_key_to_pos($key), $pos);
  $self->row_deleted ($path);

  # if this symlist now has 0 entries then has_child toggled
  if (! symlist_content_pos_exists ($key, 0)) {
    my $listnum = symlist_key_to_pos ($key);
    my $parent_path = Gtk2::TreePath->new_from_indices ($listnum);
    my $parent_iter = $self->get_iter ($path);
    $self->row_has_child_toggled ($parent_path, $parent_iter);
  }
}

#------------------------------------------------------------------------------

use constant ITEM_SHIFT => 10;
use constant LIST_MASK => (1 << ITEM_SHIFT) - 1;
sub _iter_to_coords {
  my ($self, $iter) = @_;
  if (! defined $iter) { return (undef, undef); }
  if ($iter->[0] != $self->{'stamp'}) {
    croak "iter is not for this ".ref($self)." (id ",
      $iter->[0]," want ",$self->{'stamp'},")\n";
  }
  use integer;
  my $listnum = $iter->[1] & LIST_MASK;
  my $itemnum = $iter->[1] >> ITEM_SHIFT;
  if (DEBUG) { printf "  _iter_to_coords %x -> %d,%d\n",
                 $iter->[1], $listnum, $itemnum; }
  if ($itemnum == -1) { $itemnum = undef; }
  return ($listnum, $itemnum);
}
sub _coords_to_iter {
  my ($self, $listnum, $itemnum) = @_;
  if (! defined $itemnum) { $itemnum = -1; }
  if (DEBUG) { printf "  _coords_to iter %d,%d -> %x\n",
                 $listnum, $itemnum, ($itemnum << ITEM_SHIFT) + $listnum; }
  return [ $self->{'stamp'}, ($itemnum << ITEM_SHIFT) + $listnum, undef, undef ];
}

sub INIT_INSTANCE {
  my ($self) = @_;
  Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-list-inserted', \&_do_symlist_inserted, $self);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-list-deleted', \&_do_symlist_deleted, $self);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-content-inserted', \&_do_symlist_content_inserted, $self);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-content-deleted', \&_do_symlist_content_deleted, $self);
}

# gtk_tree_model_get_flags
#
sub GET_FLAGS {
  return [ ];
}

# gtk_tree_model_get_n_columns
#
sub GET_N_COLUMNS {
  return NUM_COLUMNS;
}

# gtk_tree_model_get_column_type
#
sub GET_COLUMN_TYPE {
  return 'Glib::String';
}

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;
  if (DEBUG) { print "get_iter\n"; }
  if ($path->get_depth > 2) { return undef; }
  my ($listnum, $itemnum) = $path->get_indices;
  return _coords_to_iter ($self, $listnum, $itemnum);
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  if (DEBUG) { print "get_path\n"; }
  my ($listnum, $itemnum) = _iter_to_coords ($self, $iter);
  if (defined $itemnum) {
    return Gtk2::TreePath->new_from_indices ($listnum, $itemnum);
  } else {
    return Gtk2::TreePath->new_from_indices ($listnum);
  }
}

# gtk_tree_model_get_value
#
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  if (DEBUG) { print "get_value\n"; }
  my ($listnum, $itemnum) = _iter_to_coords ($self, $iter);

  if (! defined $itemnum) {
    if ($col == COL_SYMLIST_NAME) {
      return App::Chart::Database::read_notes_single
        ('SELECT name FROM symlist WHERE seq=?', $listnum);
    } elsif ($col == COL_SYMLIST_KEY) {
      return App::Chart::Database::read_notes_single
        ('SELECT key FROM symlist WHERE seq=?', $listnum);
    } elsif ($col == COL_SYMLIST_CONDITION) {
      return App::Chart::Database::read_notes_single
        ('SELECT condition FROM symlist WHERE seq=?', $listnum);
    }
  } else {
    my $listkey = symlist_pos_to_key ($listnum);
    if ($col == COL_ITEM_SYMBOL) {
      return App::Chart::Database::read_notes_single
        ('SELECT symbol FROM symlist_content WHERE key=? AND seq=?',
         $listkey, $itemnum);
    } elsif ($col == COL_ITEM_COMMENT) {
      return App::Chart::Database::read_notes_single
        ('SELECT comment FROM symlist_content WHERE key=? AND seq=?',
         $listkey, $itemnum);
    }
  }
  return undef;
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;
  if (DEBUG) { print "iter_next\n"; }
  my ($listnum, $itemnum) = _iter_to_coords ($self, $iter);

  if (defined $itemnum) {
    return $self->ITER_NTH_CHILD ($self->ITER_PARENT($iter), $itemnum+1);
  } else {
    return $self->ITER_NTH_CHILD (undef, $listnum+1);
  }
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  my ($self, $iter) = @_;
  return $self->ITER_NTH_CHILD ($iter, 0);
}

# gtk_tree_model_iter_has_child
# Note Gtk2 prior to 1.183 demands numeric return (zero or non-zero).
#
sub ITER_HAS_CHILD {
  my ($self, $iter) = @_;
  return $self->ITER_NTH_CHILD ($iter,0) ? 1 : 0;
}

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "iter_n_children\n"; }
  my ($listnum, $itemnum) = _iter_to_coords ($self, $iter);

  if (! defined $listnum) {
    # toplevel, how many symlists
    return App::Chart::Gtk2::Symlist::symlist_num();
  }
  if (! defined $itemnum) {
    # symlist, how many elements
    return App::Chart::Gtk2::Symlist::symlist_length (symlist_pos_to_key ($listnum));
  }
  # items have no children
  return 0;
}

# gtk_tree_model_iter_nth_child
#
sub ITER_NTH_CHILD {
  my ($self, $iter, $n) = @_;
  if (DEBUG) { print "iter_nth_child $n\n"; }
  my ($listnum, $itemnum) = _iter_to_coords ($self, $iter);

  if (! defined $listnum) {
    if (DEBUG) { print "  toplevel\n"; }
    if (App::Chart::Database::read_notes_single
        ('SELECT key FROM symlist WHERE seq=?', $n)) {
      return _coords_to_iter ($self, $n, undef);
    } else {
      return undef;
    }
  }

  if (! defined $itemnum) {
    my $listkey = symlist_pos_to_key ($listnum);
    if (DEBUG) { print "  of list $listkey\n"; }
    if (symlist_content_pos_exists ($listkey, $n)) {
      return _coords_to_iter ($self, $listnum, $n);
    } else {
      if (DEBUG) { print "  not available\n"; }
      return undef;
    }
  }
  # items have no children
  if (DEBUG) { print "  no children of items\n"; }
  return undef;
}

# gtk_tree_model_iter_parent
#
sub ITER_PARENT {
  my ($self, $iter) = @_;
  my ($listnum, $itemnum) = _iter_to_coords ($self, $iter);
  if (! defined $itemnum) {
    return undef;
  } else {
    return _coords_to_iter ($self, $listnum, undef);
  }
}

#------------------------------------------------------------------------------

sub path_for_key {
  my ($model, $key) = @_;
  my $seq = App::Chart::Database::read_notes_single
    ('SELECT seq FROM symlist WHERE key=?', $key);
  if (! defined $seq) { return undef; }
  return Gtk2::TreePath->new_from_indices ($seq);
}

sub path_for_symbol_and_symlist {
  my ($self, $symbol, $symlist) = @_;
  my $listnum = App::Chart::Database::read_notes_single
    ('SELECT seq FROM symlist WHERE key=?', $symlist->key);
  if (! defined $listnum) { return undef; }

  my $itemnum = App::Chart::Database::read_notes_single
    ('SELECT seq FROM symlist_content WHERE key=? AND symbol=?',
     $symlist->key, $symbol);
  if (! defined $itemnum) { return undef; }

  return Gtk2::TreePath->new_from_indices ($listnum, $itemnum);
}

1;
__END__
