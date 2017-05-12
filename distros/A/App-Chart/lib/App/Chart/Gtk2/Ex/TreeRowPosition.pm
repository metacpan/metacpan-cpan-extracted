# notify after all crunching




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

package App::Chart::Gtk2::Ex::TreeRowPosition;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Scalar::Util 1.18 'refaddr'; # 1.18 for pure-perl refaddr() fix
use Gtk2;
use POSIX ();

use Glib::Ex::SignalBits;
use Glib::Ex::SignalIds;

# uncomment this to run the ### lines
#use Smart::Comments;

BEGIN {
  Glib::Type->register_enum ('App::Chart::Gtk2::Ex::TreeRowPosition::Type',
                             start  => 0,
                             end    => 1,
                             at     => 2,
                             before => 3,
                             after  => 4,
                            );
}
use Glib::Object::Subclass
  'Glib::Object',
  signals => { 'key-extract' => { param_types   => [ 'Gtk2::TreeModel',
                                                     'Gtk2::TreePath',
                                                     'Gtk2::TreeIter' ],
                                  return_type   => 'Glib::String',
                                  flags         => ['action','run-last'],
                                  accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
                                },
               'key-equal' => { param_types   => [ 'Glib::String',
                                                   'Glib::String' ],
                                return_type   => 'Glib::Boolean',
                                flags         => ['action','run-last'],
                                class_closure => \&_default_key_compare,
                                accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
                              },
             },
  properties => [ Glib::ParamSpec->object
                  ('model',
                   'model',
                   'TreeModel to operate on.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boxed
                  ('path',
                   'path',
                   'Current position as a Gtk2::TreePath.',
                   'Gtk2::TreePath',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('type',
                   'type',
                   'Position type.',
                   'App::Chart::Gtk2::Ex::TreeRowPosition::Type',
                   'start',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('key-column',
                   'key-column',
                   'Column number in the model which is a unique key to identify a row.',
                   -1, POSIX::INT_MAX(),
                   -1,
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'type'} = 'start';    # defaults
  $self->{'path'} = Gtk2::TreePath->new;
  $self->{'key_column'} = -1;
  ### INIT_INSTANCE: $self->{'path'}->to_string, $self->{'type'}
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### FINALIZE_INSTANCE: "$self"
  if (my $model = $self->{'model'}) {
    if (my $h = $model->{__PACKAGE__.'.instances'}) {
      delete $h->{refaddr($self)};
      if (! %$h) {
        ### no more instances, disconnect model
        delete $model->{__PACKAGE__.'.instances'};
        delete $model->{__PACKAGE__.'.ids'};
      }
    }
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### SET_PROPERTY: $pname, $newval

  if ($pname eq 'path') {
    ### pathstr: $newval->to_string
    $newval = $newval->copy;
  } elsif ($pname eq 'model') {
    FINALIZE_INSTANCE($self);
    if ($newval) {
      Scalar::Util::weaken ($newval->{__PACKAGE__.'.instances'}->{refaddr($self)} = $self);
      $newval->{__PACKAGE__.'.ids'} ||= Glib::Ex::SignalIds->new
        ($newval,
         $newval->signal_connect (row_changed => \&_do_row_changed),
         $newval->signal_connect (row_deleted => \&_do_row_deleted),
         $newval->signal_connect (row_inserted => \&_do_row_inserted),
         $newval->signal_connect (rows_reordered => \&_do_rows_reordered));
    }
  }
  $self->{$pname} = $newval;

  if ($pname eq 'type'
      || $pname eq 'path'
      || $pname eq 'key_column') {
    if ($self->{'type'} eq 'at') {
      _at_key ($self, $self->{'path'}); # record key
    }
  }
  ### pathstr now: $self->{'path'}->to_string
}

sub _default_key_compare {
  my ($self, $key1, $key2) = @_;
  ### _default_key_compare: $key1,$key2
  return ($key1 eq $key2);
}


sub _do_row_changed {
  my ($model, $chg_path, $chg_iter) = @_;
  ### TreeRowPosition row_changed, pathstr: $chg_path->to_string

  foreach my $self (values %{$model->{__PACKAGE__.'.instances'}}) {
    $self || next;

    if ($self->{'type'} eq 'at' && $chg_path->compare($self->{'path'}) == 0) {
      # when current row changes remember its possibly changed key
      $self->{'at_key'} = _get_key ($self, $chg_path, $chg_iter);

    } elsif (exists $self->{'want_key'}) {
      # when seeking 'want_key' see if newly changed row matches
      my $this_key = _get_key ($self, $chg_path, $chg_iter);
      if (_match_key ($self, $self->{'want_key'}, $this_key)) {
        _at_key ($self, $chg_path->copy, $this_key);
      }
    }
  }
}

my %_on_row_offsets = (start  => 1,
                       end    => 1,
                       before => 0,
                       at     => 1,
                       after  => 1);

sub _do_row_inserted {
  my ($model, $ins_path, $ins_iter) = @_;
  ### TreeRowPosition row_inserted, pathstr: $ins_path->to_string

 INSTANCE: foreach my $self (values %{$model->{__PACKAGE__.'.instances'}}) {
    $self || next;
    ### instance: "$self",$self->{'type'},$self->{'path'}->to_string,$self->{'want_key'}

    # when seeking 'want_key' see if new row matches
    if (exists $self->{'want_key'}) {
      my $this_key = _get_key ($self, $ins_path, $ins_iter);
      if (_match_key ($self, $self->{'want_key'}, $this_key)) {
        _at_key ($self, $ins_path->copy, $this_key);
        next;
      }
    }

    my $type = $self->{'type'};
    if ($type eq 'start' || $type eq 'end') {
      next;
    }

    my $path = $self->{'path'};
    my $ins_depth = $ins_path->get_depth;
    if ($ins_depth > $path->get_depth) {
      ### something happening below us, so don't care
      next;
    }

    my @indices = $path->get_indices;
    my @ins_indices = $ins_path->get_indices;
    my $offset = $_on_row_offsets{$self->{'type'}};

    my $i = 0;
    for (;;) {
      if ($indices[$i] + $offset <= $ins_indices[$i]) {
        ### we're before the insert, so no change
        next INSTANCE;
      }
      if ($i == $ins_depth-1
          || $indices[$i] > $ins_indices[$i] + $offset) {
        last;
      }
      $i++;
    }

    ### insert at or before our row, increment
    $indices[$i]++;
    $self->{'path'} = Gtk2::TreePath->new_from_indices (@indices);
    $self->notify ('path');
  }
}

sub _do_row_deleted {
  my ($model, $del_path) = @_;
  ### TreeRowPosition row_deleted, pathstr: $del_path->to_string

 INSTANCE: foreach my $self (values %{$model->{__PACKAGE__.'.instances'}}) {
    $self || next;

    my $type = $self->{'type'};
    if ($type eq 'start' || $type eq 'end') {
      next;
    }

    my $path = $self->{'path'};
    my $del_depth = $del_path->get_depth;
    if ($del_depth > $path->get_depth) {
      # something happening below us, don't need to worry
      next;
    }

    my @indices = $path->get_indices;
    my @del_indices = $del_path->get_indices;

    for (my $i = 0; $i < $del_depth; $i++) {
      if ($indices[$i] > $del_indices[$i]) {
        # delete in an ancestor level and before our coords, decrement
        $indices[$i]--;
        $self->{'path'} = Gtk2::TreePath->new_from_indices (@indices);
        $self->notify ('path');
        next INSTANCE;
      }
      if ($indices[$i] < $del_indices[$i]) {
        # delete is somewhere after our coords, so no change
        next INSTANCE;
      }
    }

    ### delete of our exact row: $type
    my $offset = $_on_row_offsets{$type};
    if ($type eq 'at') {
      $self->{'type'} = 'after';
      $self->{'want_key'} = delete $self->{'at_key'};
    }
    if (($indices[-1] -= $offset) < 0) {
      $self->{'type'} = 'before';
    } else {
      $self->{'path'} = Gtk2::TreePath->new_from_indices (@indices);
    }

    if ($type ne $self->{'type'}) {
      $self->notify ('type');
    }
    $self->notify ('path');
  }
}

sub _do_rows_reordered {
  my ($model, $reorder_path, $reorder_iter, $aref) = @_;
  ### TreeRowPosition rows_reordered, pathstr: $reorder_path->to_string, join(',',@$aref)

  my $lookup;
 INSTANCE: foreach my $self (values %{$model->{__PACKAGE__.'.instances'}}) {
    $self || next;

    my $path = $self->{'path'};
    if (! $reorder_path->is_ancestor($path)) {
      return;
    }

    # $aref is what was previously there, ie. $aref->[$new_index]==$old_index,
    # invert to $lookup[$old_index]==$new_index
    #
    $lookup ||= do {
      my @lookup;
      @lookup[@$aref] = 0 .. $#$aref;  # array slice
      \@lookup
    };

    my @ind = $path->get_indices;
    my $depth = $reorder_path->get_depth;
    my $old_index = $ind[$depth];
    my $new_index = $lookup->[$old_index];
    if ($new_index != $old_index) {
      $ind[$depth] = $new_index;
      $self->{'path'} = Gtk2::TreePath->new_from_indices (@ind);
      $self->notify ('path');
    }
  }
}

# optional $iter is the $path row
sub _get_key {
  my ($self, $path, $iter) = @_;
  ### _get_key(), pathstr: $path->to_string, $iter

  if ($path->get_depth == 0) {
    return undef;
  }
  my $model = $self->{'model'};
  $iter ||= $model->get_iter ($path);
  if (! $iter) {
    ### no such row in model
    return undef;
  }

  if (defined (my $key = $self->signal_emit ('key-extract', $model, $path, $iter))) {
    return $key;
  }
  if ((my $key_column = $self->{'key_column'}) >= 0) {
    ### look at key_column: $key_column
    return $model->get_value ($iter, $key_column);
  }
  return undef;
}
sub _match_key {
  my ($self, $want, $got) = @_;
  ### _match_key(): $got, $want
  return (defined $got
          && $self->signal_emit ('key-equal', $got, $want));
}

sub model {
  my ($self) = @_;
  return $self->{'model'};
}
sub path {
  my ($self) = @_;
  return $self->{'path'};
}
sub iter {
  my ($self) = @_;
  if ($self->{'type'} eq 'at') {
    my $model = $self->{'model'};
    return $model->get_iter ($self->{'path'});
  } else {
    return undef;
  }
}

sub goto {
  my ($self, $path, $type) = @_;
  $type ||= 'at';
  ### TreeRowPosition goto: $path->to_string, $type
  $self->{'path'}
    = (Scalar::Util::blessed($path) && $path->isa('Gtk2::TreePath')
       ? $path->copy
       : Gtk2::TreePath->new($path));
  my $old_type = $self->{'type'};
  $self->{'type'} = $type;
  if ($type eq 'at') {
    _at_key ($self, $self->{'path'}); # record key
  }
  if ($self->{'type'} ne $old_type) {
    $self->notify ('type');
  }
  $self->notify ('path');
}

sub goto_top_start {
  my ($self) = @_;
  $self->{'type'} = 'start';
  $self->{'path'} = Gtk2::TreePath->new;
  $self->notify ('type');
  $self->notify ('path');
}
sub goto_top_end {
  my ($self) = @_;
  $self->{'type'} = 'end';
  $self->{'path'} = Gtk2::TreePath->new;
  $self->notify ('type');
  $self->notify ('path');
}

sub next {
  my ($self, %options) = @_;
  ### TreeRowPosition next, from pathstr: $self->{'path'}->to_string, $self->{'type'}, "$self->{'model'}"

  my $path = $self->{'path'}->copy;
  my $type = $self->{'type'};
  if ($type eq 'end') {
    return undef;
  }
  if ($type eq 'start') {
    $path->down;
  } elsif ($self->{'type'} ne 'before') {
    $path->next;
  }
  $type = 'at';
  my $model = $self->{'model'};

  ### consider: $path->to_string, $type
  if (! $model->get_iter($path)) {
    for (;;) {
      $path->up;
      if ($path->get_depth == 0) {
        # got to end of toplevel, nothing more to look at
        $type = 'end';
        goto DONE;
      }
      if ($model->get_iter($path)) {
        last;
      }
    }
  }

  for (;;) {
    if (my $iter = $model->get_iter($path)) {
      unless ($options{'want_leaf'} && $model->has_child($iter)) {
        last;
      }
      $path->next;
    } else {
      $path->up;
      $path->next;
      $path->down;
    }
  }

 DONE:
  if (! $options{'find_only'}) {
    $self->{'path'} = $path;
    _at_key ($self, $path);
    if ($self->{'type'} ne $type) {
      $self->{'type'} = $type;
      $self->notify ('type');
    }
    $self->notify ('path');
  }
  return ($type eq 'at' ? $path : undef);
}

sub prev_path {
  my ($self) = @_;
  ### TreeRowPosition prev: "$self->{'model'}"

  my $type = $self->{'type'};
  if ($type eq 'start') {
    return undef;
  }

  my $model = $self->{'model'};
  my $mlen = $model->iter_n_children(undef);
  if ($mlen == 0) {
    return undef;
  }

  my $path = $self->{'path'};
  if ($type eq 'end') {
    $path = $mlen - 1;
  } elsif ($type eq 'at' || $type eq 'before') {
    $path--;
  }
  $path = min ($path, $mlen-1);

  if ($path < 0) {
    return undef;
  }

  _at_key ($self, $path);
  return $self->{'path'};
}

# optional $key is row key data for $path, if not given then _get_key() runs
sub _at_key {
  my ($self, $path, $key) = @_;
  ### _at_key(), pathstr: $path->to_string

  $self->{'type'} = 'at';
  $self->{'path'} = $path;
  $self->notify ('type');
  $self->notify ('path');

  delete $self->{'want_key'};
  if (@_ < 3) {
    $key = _get_key ($self, $path);
  }
  ### key value: $key
  if (defined $key) {
    $self->{'at_key'} = $key;
  }
}

sub next_iter {
  my $self = shift;
  my $path = $self->next (@_) || return undef;
  return $self->{'model'}->get_iter ($path);
}
sub prev_iter {
  my $self = shift;
  my $path = $self->prev (@_) || return undef;
  return $self->{'model'}->get_iter ($path);
}

1;
__END__

=for stopwords TreeModel TreeView TreeRowReference TreeRowPosition Eg enum Enum coderef undef iter treerowpos

=head1 NAME

App::Chart::Gtk2::Ex::TreeRowPosition -- position within a list type tree model

=for test_synopsis my ($my_model)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::TreeRowPosition;
 my $rowpos = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $my_model);

 my $path = $rowpos->next_path;

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Ex::TreeRowPosition> is a subclass of C<Glib::Object>,

    Glib::Object
      App::Chart::Gtk2::Ex::TreeRowPosition

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Ex::TreeRowPosition> object keeps track of a position in a list type
TreeModel (meaning any C<Glib::Object> implementing the C<Gtk2::TreeModel>
interface).  It's intended to track a user's position in a list of files,
documents, etc.

The position can be "at" a given row, or "before" or "after" one.  The
position adjusts with inserts, deletes and reordering to follow that row.
Special positions "start" and "end" are the ends of the list, not following
any row.

A row data "key" scheme allows a row to be followed across a delete and
re-insert done by TreeView drag-and-drop, or by a user delete and undo, or
re-add.

=head2 TreeRowReference

L<C<Gtk2::TreeRowReference>|Gtk2::TreeRowReference> does a similar thing to
TreeRowPosition, but a TreeRowReference is oriented towards tracking just a
particular row.  If its row is deleted the TreeRowReference points nowhere.
TreeRowPosition instead then keeps a position in between remaining rows.

=head1 FUNCTIONS

=over 4

=item C<< $rowpos = App::Chart::Gtk2::Ex::TreeRowPosition->new (key => value, ...) >>

Create and return a new TreeRowPosition object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.  Eg.

    my $rowpos = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $my_model,
                                               key_column => 2);

=item C<< $model = $rowpos->model >>

=item C<< $type = $rowpos->type >>

=item C<< $path = $rowpos->path >>

Return the C<model>, C<type> and C<index> properties described below.

=item C<< $iter = $rowpos->iter >>

Return a L<C<Gtk2::TreeIter>|Gtk2::TreeIter> which is the current row.  If
C<$rowpos> is not type "at" or the index is out of range then the return is
C<undef>.

=item C<< $path = $rowpos->next_path >>

=item C<< $path = $rowpos->prev_path >>

=item C<< $iter = $rowpos->next_iter >>

=item C<< $iter = $rowpos->prev_iter >>

Move C<$rowpos> to the next or previous row from its current position and
return an integer index or L<C<Gtk2::TreeIter>|Gtk2::TreeIter> for the new
position.  If there's no more rows in the respective direction (including if
the model is empty) then the return is C<undef> instead.

=item C<< $rowpos->goto ($path) >>

=item C<< $rowpos->goto ($path, $type) >>

Move C<$rowpos> to the given C<$path> row.  The C<$type> parameter
defaults to "at", or you can give "before" or "after" instead.

    $rowpos->goto (4, 'before');

C<goto> is the same as setting the respective property values (but changed
in one operation).

=item C<< $rowpos->goto_start >>

=item C<< $rowpos->goto_end >>

Move C<$rowpos> to the start or end of its model, so that C<next> returns
the first row or C<prev> the last row (respectively).  These functions are
the same as setting the C<type> property to "start" or "end", respectively.

=back

=head1 PROPERTIES

=over 4

=item C<model> (C<Glib::Object> implementing C<Gtk2::TreeModel>)

The model to operate on.

=item C<type> (C<App::Chart::Gtk2::Ex::TreeRowPosition::Type> enum, default C<start>)

Enum values "at", "before", "after", "start", "end".

The default type is C<"start">, but you can Initialize to a particular row
explicitly,

    my $rowpos = App::Chart::Gtk2::Ex::TreeRowPosition->new (model => $my_model,
                                               type  => 'at',
                                               index => 3);

=item C<path> (C<Gtk2::TreePath>, default an empty path)

Current path in the model.

=item C<key-column> (integer, default -1)

Column number of row key data.  The default -1 means no key column.

=back

C<notify> signals are emitted for C<path> and/or C<type> when model row
changes alter those values, in the usual way.  A notify handler must not
insert, delete or reorder model rows because doing so may invalidate the
path and/or iter objects passed to further handlers on the model.

=head1 SIGNALS

=over 4

=item C<key-extract>, called (treerowpos, model, path, iter)

Callback to extract a key from a row.  When set it's called

=item C<key-equal>, called (treerowpos, string, string)

Row key equality function.  The default handler compares with C<eq>.

=back

=head1 OTHER NOTES

When a TreeRowPosition is "at" a given row and that row is deleted there's a
choice between becoming "after" the previous row, or "before" the next row.
This can make a difference in a reorder if the two rows move to different
places.  The current code always uses "after the previous", or if the first
row is deleted then "start".

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::TreeRowReference>

=cut
