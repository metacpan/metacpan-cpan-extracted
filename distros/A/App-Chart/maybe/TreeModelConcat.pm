# Copyright 2008, 2009 Kevin Ryde

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


package Gtk2::Ex::TreeModelConcat;
use strict;
use warnings;
use Gtk2;
use Carp;

use Glib::Object::Subclass
  'Glib::Object',
  interfaces => [ Gtk2::TreeModel:: ],
  properties => [ Glib::ParamSpec->scalar
                  ('models',
                   'models',
                   'Arrayref of Gtk2::TreeModel objects to concatenate.',
                   Glib::G_PARAM_READWRITE)
                ];

use constant DEBUG => 0;

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'models'} = [];

  require Tie::RefHash;
  my %mhash;
  tie %mhash, 'Tie::RefHash';
  $self->{'mhash'} = \%mhash;

  my %offsets;
  tie %offsets, 'Tie::RefHash';
  $self->{'offsets'} = \%offsets;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY
  if (DEBUG) { print "TreeModelConcat set $pname\n"; }

  if ($pname eq 'models') {
    my $models = $newval;
    $self->{'flags'} = undef;
    $self->{'offsets'} = ();
    %{$self->{'mhash'}} = (map {$_ => {}} @$models);
  }
}

# gtk_tree_model_get_flags
#
sub GET_FLAGS {
  my ($self) = @_;
  return ($self->{'flags'} ||= do {
    my $flags = [];
    my $models = $self->{'models'};
    if (@$models) {
      $flags = [ 'list-only' ];
      foreach my $model (@$models) {
        if (! ($model->get_flags & 'list-only')) {
          $flags = [];
          last;
        }
      }
    }
    $flags;
  });
}

# gtk_tree_model_get_n_columns
#
sub GET_N_COLUMNS {
  my ($self) = @_;
  my $model = $self->{'models'}->[0] || return 0;
  return $model->get_n_columns;
}

# gtk_tree_model_get_column_type
#
sub GET_COLUMN_TYPE {
  my ($self, $col) = @_;
  if (DEBUG) { print "TreeModelConcat get_column_type\n"; }
  my $model = $self->{'models'}->[0]
    or croak "No models";
  return $model->get_column_type ($col);
}

# gtk_tree_model_get_iter
#
sub GET_ITER {
  my ($self, $path) = @_;
  if (DEBUG) { print "TreeModelConcat get_iter ",$path->to_string,"\n"; }
  if ($path->get_depth == 0) { return undef; }

  my @indices = $path->get_indices;
  my $offset = 0;
  foreach my $model (@{$self->{'models'}}) {
    my $len = $model->iter_n_children (undef);
    if ($offset + $len > $indices[0]) {
      $indices[0] -= $offset;
      my $subpath = Gtk2::TreePath->new_from_indices (@indices);
      my $subiter = $model->get_iter ($subpath);
      return _subiter_to_iter ($self, $model, $subiter);
    }
  }
  return undef;
}

# gtk_tree_model_get_path
#
sub GET_PATH {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeModelConcat get_path\n"; }
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  my $subpath = $model->get_path;
  return _subpath_to_path ($self, $model, $subpath);
}

# gtk_tree_model_get_value
#
sub GET_VALUE {
  my ($self, $iter, $col) = @_;
  if (DEBUG) { print "TreeModelConcat get_value ",$iter->[1]," col=$col\n"; }
  use Data::Dumper;
  print Dumper($self);
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  return $model->get_value ($subiter, $col);
}

# gtk_tree_model_iter_next
#
sub ITER_NEXT {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeModelConcat iter_next\n"; }
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  if (my $nextsubiter = $model->iter_next ($subiter)) {
    return _subiter_to_iter ($self, $model, $nextsubiter);
  }
  if ($model->iter_parent ($subiter)) {
    return undef; # not a top-level
  }

  # top-level, look for first of next model
  my $models = $self->{'models'};
  my $i = 0;
  for (;;) {
    if ($models->[$i] == $model) { last; }
    $i++;
    if ($i > $#$models) { die "oops, model not found"; }
  }
  for (;;) {
    $i++;
    $model = $models->[$i];
    if (! $model) { return undef; }

    $subiter = $model->get_iter_first;
    if ($subiter) {
      return _subiter_to_iter ($self, $model, $subiter);
    }
  }
}

# gtk_tree_model_iter_children
#
sub ITER_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeModelConcat iter_children\n"; }
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  $subiter = $model->iter_children ($subiter);
  if (! $subiter) { return undef; }
  return _subiter_to_iter ($self, $model, $subiter);
}

# gtk_tree_model_iter_has_child
#
sub ITER_HAS_CHILD {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeModelConcat has_child\n"; }
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  # note Gtk2 prior to 1.183 demands numeric return (zero or non-zero)
  return ($model->has_child ($subiter) ? 1 : 0);
}

# gtk_tree_model_iter_n_children
#
sub ITER_N_CHILDREN {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeModelConcat iter_n_children\n"; }
  if (defined $iter) {
    my ($model, $subiter) = _iter_to_subiter ($self, $iter);
    return $model->iter_n_children ($subiter);
  } else {
    my $total = 0;
    foreach my $model (@{$self->{'models'}}) {
      $total += $model->iter_n_children (undef);
    }
    return $total;
  }
}

# gtk_tree_model_iter_nth_child
#
sub ITER_NTH_CHILD {
  my ($self, $iter, $n) = @_;
  if (DEBUG) { print "TreeModelConcat iter_nth_child $n\n"; }
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  $subiter = $model->iter_nth_child ($subiter);
  if (! $subiter) { return undef; }
  return _subiter_to_iter ($self, $model, $subiter);
}

# gtk_tree_model_iter_parent
#
sub ITER_PARENT {
  my ($self, $iter) = @_;
  if (DEBUG) { print "TreeModelConcat iter_parent\n"; }
  my ($model, $subiter) = _iter_to_subiter ($self, $iter);
  $subiter = $model->iter_nth_child ($subiter);
  if (! $subiter) { return undef; }
  return _subiter_to_iter ($self, $model, $subiter);
}

#------------------------------------------------------------------------------

sub _do_row_changed {
  my ($model, $subpath, $subiter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeModelConcat row_changed\n";}

  # old iters no good after a signal
  unless ($model->get_flags & 'iters-persist') {
    $self->{'mhash'}->{$model} = ();
  }

  my $iter = _subiter_to_iter ($self, $model, $subiter);
  my $path = _subpath_to_path ($self, $model, $subpath);
  $self->row_changed ($path, $iter);
}

sub _do_row_inserted {
  my ($model, $subpath, $subiter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeModelConcat row_inserted\n";}

  $self->{'mhash'}->{$model} = (); # new numbering
  if ($subpath->get_depth == 0) {
    $self->{'offsets'} = ();       # new sizes
  }

  my $iter = _subiter_to_iter ($self, $model, $subiter);
  my $path = _subpath_to_path ($self, $model, $subpath);
  $self->row_inserted ($path, $iter);
}

sub _do_row_deleted {
  my ($model, $subpath, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeModelConcat row_deleted\n";}

  $self->{'mhash'}->{$model} = (); # new numbering
  if ($subpath->get_depth == 0) {
    $self->{'offsets'} = ();       # new sizes
  }

  $self->row_deleted (_subpath_to_path ($self, $model, $subpath));
}

sub _do_rows_reordered {
  my ($model, $subpath, $subiter, $subaref, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "TreeModelConcat rows_reordered\n";}

  $self->{'mhash'}->{$model} = (); # new numbering

  my $aref;
  if ($subpath->get_depth == 0) {
    # top-level, $aref->[$newpos] == $oldpos, must apply offset to both pos
    my $offset = _model_offset ($self, $model);
    $aref = [ 0 .. $offset-1, map {$_+$offset} @$subaref ]
  } else {
    # sub-level
    $aref = $subaref;
  }

  my $iter = _subiter_to_iter ($self, $model, $subiter);
  my $path = _subpath_to_path ($self, $model, $subpath);
  $self->rows_reordered ($path, $iter, $aref);
}

#------------------------------------------------------------------------------

sub _subpath_to_path {
  my ($self, $model, $subpath) = @_;
  my @indices = $subpath->get_indices;
  if (@indices) { $indices[0] += _model_offset ($self, $model); }
  return Gtk2::TreePath->new_from_indices (@indices);
}

sub _model_offset {
  my ($self, $model) = @_;
  my $offset = $self->{'offsets'}->{$model};
  if (defined $offset) { return $offset; }
  return ($self->{'offsets'}->{$model} = do {
    my $offset = 0;
    foreach my $m (@{$self->{'models'}}) {
      if ($m == $model) { last; }
      $offset += $m->iter_n_children(undef);
    }
  });
}

sub _iter_to_subiter {
  my ($self, $iter) = @_;
  use Data::Dumper;
  print Dumper($iter);
  if (! defined $iter) {
    croak;
    return ($self->{'models'}->[0], undef);
  }
  if ($iter->[0] != $self+0) {
    croak "iter is not for this ".ref($self)
      ." (id ",$iter->[0]," want ",$self+0,")\n";
  }
  my $a = $iter->[2];
  if (DEBUG) { print "  extract subiter ",$a->[0]," ",$a->[1],"\n"; }
  return @$a;  # (model, subiter)
}

sub _subiter_to_iter {
  my ($self, $model, $subiter) = @_;
  my $path = $model->get_path ($subiter);
  my $pstr = $path->to_string;
  my $mh = $self->{'mhash'}->{$model};
  my $a = ($mh->{$pstr} ||= [ $model, $subiter ] );
  print Dumper($a);
  print Dumper($mh);
  if (DEBUG) { print "  make iter [$model,$subiter]\n"; }
  use Data::Dumper;
  print Dumper($self);
  return [ $self+0, 0, $a, undef ];
}

#------------------------------------------------------------------------------

1;
__END__
