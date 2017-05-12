# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::Ex::ListModelPos;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Gtk2;
use POSIX ();

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;

use constant DEBUG => 0;

BEGIN {
  Glib::Type->register_enum ('App::Chart::Gtk2::Ex::ListModelPos::Type',
                             at     => 0,
                             before => 1,
                             after  => 2,
                             start  => 3,
                             end    => 4);
}
use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->object
                  ('model',
                   'model',
                   'TreeModel to operate on.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('index',
                   'index',
                   'Current position as an integer.',
                   0, POSIX::INT_MAX(),
                   0,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('type',
                   'type',
                   'Position type.',
                   'App::Chart::Gtk2::Ex::ListModelPos::Type',
                   'start',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('key-column',
                   'key-column',
                   'Column number in the model which is a unique key to identify a row.',
                   -1, POSIX::INT_MAX(),
                   -1,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('key-func',
                   'key-func',
                   'Function returning a key (a string) uniquely identifying a row.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('key-equal',
                   'key-equal',
                   'Function testing equality of key strings.',
                   Glib::G_PARAM_READWRITE),

                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'type'} = 'start';  # defaults
  $self->{'index'} = 0;
  $self->{'key_column'} = -1;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;

  if ($pname eq 'model') {
    my $model = $newval;
    my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);

    $self->{'ids'} = $model && Glib::Ex::SignalIds->new
      ($model,
       $model->signal_connect (row_changed => \&_do_row_changed,
                               $ref_weak_self),
       $model->signal_connect (row_deleted => \&_do_row_deleted,
                               $ref_weak_self),
       $model->signal_connect (row_inserted => \&_do_row_inserted,
                               $ref_weak_self),
       $model->signal_connect (rows_reordered => \&_do_rows_reordered,
                               $ref_weak_self));
  }
  if ($pname eq 'type' || $pname eq 'index'
      || $pname eq 'key_column' || $pname eq 'key_func') {
    if ($self->{'type'} eq 'at') {
      _at_key ($self, $self->{'index'}); # record key
    }
  }
}

# the types which have 'index' referring to a particular row
my %_on_row_offsets = (before => 0,
                       at     => 1,
                       after  => 1);

sub _do_row_changed {
  my ($model, $chg_path, $chg_iter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListModelPos changed '", $chg_path->to_string, "'\n"; }

  $chg_path->get_depth == 1 or return;
  my ($chg_index) = $chg_path->get_indices;

  # when current row changes remember its possibly changed key
  if ($chg_index == $self->{'index'} && $self->{'type'} eq 'at') {
    my $key = _get_key ($self, $chg_index, $chg_iter);
    if (defined $key) { $self->{'at_key'} = $key; }
    return;
  }

  # when seeking 'want_key' see if newly changed row matches
  if (exists $self->{'want_key'}) {
    my $this_key = _get_key ($self, $chg_index, $chg_iter);
    if (_match_key ($self, $self->{'want_key'}, $this_key)) {
      _at_key ($self, $chg_index, $this_key);
    }
  }
}

sub _do_row_inserted {
  my ($model, $ins_path, $ins_iter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListModelPos inserted ", $ins_path->to_string, "\n"; }

  $ins_path->get_depth == 1 or return;
  my ($ins_index) = $ins_path->get_indices;

  # when seeking 'want_key' see if new row matches
  if (exists $self->{'want_key'}) {
    my $this_key = _get_key ($self, $ins_index, $ins_iter);
    if (_match_key ($self, $self->{'want_key'}, $this_key)) {
      _at_key ($self, $ins_index, $this_key);
      return;
    }
  }

  # when "at", "before" or "after", adjust index if we're after the insertion
  my $offset = $_on_row_offsets{$self->{'type'}};
  if (defined $offset) {
    if ($ins_index < $self->{'index'} + $offset) {
      $self->{'index'} ++;
    }
  }
}

sub _do_row_deleted {
  my ($model, $del_path, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListModelPos deleted ", $del_path->to_string, "\n"; }

  $del_path->get_depth == 1 or return;
  my ($del_index) = $del_path->get_indices;

  my $type = $self->{'type'};

  # when current row deleted, become "before" what was the following row
  if ($type eq 'at' && $del_index == $self->{'index'}) {
    $self->{'type'} = 'before';
    $self->notify ('type');
    if (exists $self->{'at_key'}) {
      $self->{'want_key'} = delete $self->{'at_key'};
    }
    return;
  }

  # when "at", "before" or "after", adjust index if we're after the deletion
  my $offset = $_on_row_offsets{$type};
  if (defined $offset) {
    if ($del_index < $self->{'index'} + $offset) {
      if (-- $self->{'index'} < 0) {
        $self->{'type'} = 'before';
        $self->{'index'} = 0;
        $self->notify ('type');
        $self->notify ('index');
      }
    }
  }
}

sub _do_rows_reordered {
  my ($model, $reorder_path, $reorder_iter, $aref, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "ListModelPos reorder ", join(' ',@$aref), "\n"; }

  $reorder_path->get_depth == 0 or return;
  exists $_on_row_offsets{$self->{'type'}} or return;

  # when "at", "before" or "after" move $self->{'index'} old value to new,
  # searching through $old_index == $aref->[$new_index]
  my $index = $self->{'index'};
  foreach my $new_index (0 .. $#$aref) {
    if ($aref->[$new_index] == $index) {
      $self->{'index'} = $new_index;
      $self->notify ('index');
      last;
    }
  }
}

# optional $iter is the $index row
sub _get_key {
  my ($self, $index, $iter) = @_;

  my $key_func = $self->{'key_func'};
  my $key_column = $self->{'key_column'};
  defined $key_func or $key_column>=0 or return;

  my $model = $self->{'model'};
  $iter ||= $model->iter_nth_child (undef, $index);
  if (! $iter) { return; }

  if (defined $key_func) {
    return $key_func->($model, $iter);
  } else {
    return $model->get_value ($iter, $key_column);
  }
}
sub _match_key {
  my ($self, $want, $got) = @_;
  if (DEBUG) {
    print "  _match_key ",
      (defined $want ? $want : 'undef'),
        " ",(defined $got ? $got : 'undef'),"\n";
  }
  if (! defined $got) { return 0; }
  if (my $key_equal = $self->{'key_equal'}) {
    return $key_equal->($want, $got);
  } else {
    return $want eq $got;
  }
}

sub model {
  my ($self) = @_;
  return $self->{'model'};
}
sub index {
  my ($self) = @_;
  return $self->{'index'};
}
sub iter {
  my ($self) = @_;
  if ($self->{'type'} eq 'at') {
    my $model = $self->{'model'};
    return $model->iter_nth_child ($self->{'index'});
  } else {
    return undef;
  }
}

sub goto {
  my ($self, $index, $type) = @_;
  $type ||= 'at';
  if (DEBUG) { print "ListModelPos goto $index, $type\n"; }
  $self->{'index'} = $index;
  $self->{'type'} = $type;
  if ($type eq 'at') {
    _at_key ($self, $index); # record key
  }
  $self->notify ('index');
  $self->notify ('type');
}

sub goto_start {
  my ($self) = @_;
  $self->{'type'} = 'start';
  $self->notify ('type');
}
sub goto_end {
  my ($self) = @_;
  $self->{'type'} = 'end';
  $self->notify ('type');
}

sub next_index {
  my ($self) = @_;
  if (DEBUG) { print "ListModelPos next ",$self->{'model'},"\n"; }

  if ($self->{'type'} eq 'end') {
    return undef;
  }

  my $index = $self->{'index'};
  if ($self->{'type'} eq 'start') {
    $index = 0;
  } elsif ($self->{'type'} ne 'before') {
    $index++;
  }

  my $model = $self->{'model'};
  my $mlen = $model->iter_n_children(undef);
  if ($index >= $mlen) {
    return undef;
  }

  _at_key ($self, $index);
  return $self->{'index'};
}

sub prev_index {
  my ($self) = @_;
  if (DEBUG) { print "ListModelPos prev $self->{'model'}\n"; }

  my $type = $self->{'type'};
  if ($type eq 'start') {
    return undef;
  }

  my $model = $self->{'model'};
  my $mlen = $model->iter_n_children(undef);
  if ($mlen == 0) {
    return undef;
  }

  my $index = $self->{'index'};
  if ($type eq 'end') {
    $index = $mlen - 1;
  } elsif ($type eq 'at' || $type eq 'before') {
    $index--;
  }
  $index = min ($index, $mlen-1);

  if ($index < 0) {
    return undef;
  }

  _at_key ($self, $index);
  return $self->{'index'};
}

# optional $key is row key data for $index, if not given then _get_key() runs
sub _at_key {
  my ($self, $index, $key) = @_;
  if (DEBUG) { print "  at $index\n"; }
  $self->{'type'} = 'at';
  $self->{'index'} = $index;
  $self->notify ('type');
  $self->notify ('index');

  delete $self->{'want_key'};
  if (@_ < 3) {
    $key = _get_key ($self, $index);
  }
  if (defined $key) {
    $self->{'at_key'} = $key;
  }
}

sub next_iter {
  my ($self) = @_;
  my $index = $self->next_index;
  if (! defined $index) { return undef; }
  return $self->{'model'}->iter_nth_child (undef, $index);
}
sub prev_iter {
  my ($self) = @_;
  my $index = $self->prev_index;
  if (! defined $index) { return undef; }
  return $self->{'model'}->iter_nth_child (undef, $index);
}

1;
__END__

=for stopwords submodel submodels ListOfLists TreeDragSource TreeDragDest toplevel Gtk ie ListofLists Eg TreeModel iter iters Ryde ListOfListsModel TreeView TreeRowReference ListModelPos enum Enum coderef

=head1 NAME

App::Chart::Gtk2::Ex::ListModelPos -- position within a list type tree model

=for test_synopsis my ($my_model)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::ListModelPos;
 my $listpos = App::Chart::Gtk2::Ex::ListModelPos->new (model => $my_model);

 my $index = $listpos->next_index;

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Ex::ListModelPos> is a subclass of C<Glib::Object>,

    Glib::Object
      App::Chart::Gtk2::Ex::ListModelPos

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Ex::ListModelPos> object keeps track of a position in
a list type TreeModel (meaning any C<Glib::Object> implementing the
C<Gtk2::TreeModel> interface).  It's intended to track a user's position in
a list of files, documents, etc.

The position can be "at" a given row, or "before" or "after" one.  The
position adjusts with inserts, deletes and reordering to follow that row.
Special positions "start" and "end" are the ends of the list, not following
any row.

A row data "key" scheme allows a row to be followed across a delete and
re-insert done by TreeView drag-and-drop, or by a user delete and undo, or
re-add.

=head2 TreeRowReference

L<C<Gtk2::TreeRowReference>|Gtk2::TreeRowReference> does a similar thing to
ListModelPos, but a TreeRowReference is oriented towards tracking just a
particular row.  If its row is deleted then a TreeRowReference points
nowhere, whereas ListModelPos remembers a position in between remaining rows.

=head1 FUNCTIONS

=over 4

=item C<< $listpos = App::Chart::Gtk2::Ex::ListModelPos->new (key => value, ...) >>

Create and return a new ListModelPos object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new() >>.  Eg.

    my $listpos = App::Chart::Gtk2::Ex::ListModelPos->new (model => $my_model,
                                                           key_column => 2);

=item C<< $index = $listpos->model() >>

=item C<< $index = $listpos->type() >>

=item C<< $index = $listpos->index() >>

Return the C<model>, C<type> and C<index> properties per L</PROPERTIES>
below.

=item C<< $index = $listpos->iter() >>

Return a L<C<Gtk2::TreeIter>|Gtk2::TreeIter> which is the current row.  If
C<$listpos> is not type "at" or its index is out of range then the return is
C<undef>.

=item C<< $index = $listpos->next_index() >>

=item C<< $index = $listpos->prev_index() >>

=item C<< $iter = $listpos->next_iter() >>

=item C<< $iter = $listpos->prev_iter() >>

Move C<$listpos> to the next or previous row from its current position and
return an integer index or L<C<Gtk2::TreeIter>|Gtk2::TreeIter> for the new
position.  If there's no more rows in the respective direction (including if
the model is empty) then the return is C<undef> instead.

=item C<< $listpos->goto ($index) >>

=item C<< $listpos->goto ($index, $type) >>

Move C<$listpos> to the given C<$index> row.  The C<$type> parameter
defaults to "at", or you can give "before" or "after" instead.

    $listpos->goto (4, 'before');

C<goto> is the same as setting the respective property values (but changed
in one operation).

=item C<< $listpos->goto_start() >>

=item C<< $listpos->goto_end() >>

Move C<$listpos> to the start or end of its model, so that C<next> returns
the first row or C<prev> the last row (respectively).  These functions are
the same as setting the C<type> property to "start" or "end", respectively.

=back

=head1 PROPERTIES

=over 4

=item C<model> (C<Glib::Object> implementing C<Gtk2::TreeModel> interface)

The model to operate on.

=item C<type> (C<Gtk2::Ex::ListModelPos::Type> enum, default "start")

Enum values "at", "before", "after", "start", "end".

The default type is C<"start">, but you can Initialize to a particular row
explicitly,

    my $listpos = App::Chart::Gtk2::Ex::ListModelPos->new (model => $my_model,
                                               type  => 'at',
                                               index => 3);

=item C<index> (integer, default 0)

Current row number in the model.  When C<type> is "start" or "end" the index
value is unused.

=item C<key_column> (integer, default -1)

Column number of row key data.  The default -1 means no key column.

=item C<key_func> (coderef, default C<undef>)

Function to extract a key from a row.  When set it's called

    $str = &$key_func ($model, $iter)

=item C<key_equal> (coderef, default C<undef>)

Row key equality function.  The default C<undef> means use C<eq>.  When set
it's called as

    $bool = &$key_equal ($value1, $value2)

with values from the C<key_func> or C<key_column>.

=back

=head1 OTHER NOTES

When a ListModelPos is "at" a given row and that row is deleted there's a
choice between becoming "after" the previous row, or "before" the next row.
This can make a difference in a reorder if the two rows move to different
places.  The current code always uses "after the previous", or if the first
row is deleted then "start".

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::TreeRowReference>

=cut
