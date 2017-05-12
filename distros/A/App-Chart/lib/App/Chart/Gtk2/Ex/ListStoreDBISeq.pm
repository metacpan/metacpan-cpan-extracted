# Copyright 2007, 2008, 2009, 2010, 2015 Kevin Ryde

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

package App::Chart::Gtk2::Ex::ListStoreDBISeq;
use 5.008;
use strict;
use warnings;
use Carp 'carp','croak';
use Gtk2;
use List::Util qw(min max);
use POSIX ();

use App::Chart;
use App::Chart::Database;

# uncomment this to run the ### lines
#use Smart::Comments;


use Glib::Object::Subclass
  'Gtk2::ListStore',
  signals => { row_changed    => \&_do_row_changed,
               row_inserted   => \&_do_row_inserted,
               row_deleted    => \&_do_row_deleted },
  properties => [
                 # a perl DBI handle
                 Glib::ParamSpec->scalar
                 ('dbh',
                  'dbh',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('table',
                  'table',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('where',
                  'where',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('columns',
                  'columns',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  _establish_where ($self);  # initial empty

  # class closure no good as of Perl-Gtk2 1.221, must connect to self
  $self->signal_connect (rows_reordered => \&_do_rows_reordered);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### ListSeq SET_PROPERTY(): $pname
  $self->{$pname} = $newval;

  if ($pname eq 'columns') {
    my $columns = $newval;
    $self->set_column_types (('Glib::String') x @$columns);

  } elsif ($pname eq 'where') {
    _establish_where ($self);
  }
  delete $self->{'sth'};
  $self->reread;
}

sub _establish_where {
  my ($self) = @_;

  my @columns;
  my @values;
  $self->{'where_clause'} = '';
  $self->{'where_and'} = ' WHERE ';
  $self->{'where_columns'} = \@columns;
  $self->{'where_values'} = \@values;

  if (my $where = $self->{'where'}) {
    my @conds;
    while (my ($column, $value) = each %$where) {
      push @columns, $column;
      push @conds, "$column=?";
      push @values, $value;
    }
    if (@conds) {
      my $cond = $self->{'where_clause'} = ' WHERE ' . join(' AND ', @conds);
      $self->{'where_and'} = $cond . ' AND ';
    }
  }
  ### ListSeq where_clause: $self->{'where_clause'}
  ### where_and: $self->{'where_and'}
  ### where_values: $self->{'where_values'}
}

sub reread {
  my ($self) = @_;
  ### ListSeq reread()

  my $dbh = $self->{'dbh'};
  my $table = $self->{'table'};
  my $columns = $self->{'columns'};
  my $where_values = $self->{'where_values'};

  if (! ($dbh && $table && $columns)) {
    local $self->{'reading_database'} = 1;
    $self->clear;
    return;
  }

  my $sth_read = ($self->{'sth'}->{'read'} ||= do {
    $dbh->prepare ('SELECT ' . join(',', 'seq', @$columns)
                   . " FROM $table $self->{'where_clause'} ORDER BY seq ASC")
  });
  $sth_read->execute (@$where_values);

  local $self->{'reading_database'} = 1;
  my $iter = $self->get_iter_first;

  my $want_seq = 0;
  while (my @row = $sth_read->fetchrow_array) {
    my $got_seq = shift @row;
    if ($got_seq != $want_seq) {
      carp "ListSeq: bad seq in database, got $got_seq want $want_seq, fixing";
      $dbh->do ("UPDATE $table SET seq=? $self->{'where_and'} seq=?",
                undef,
                $want_seq, @$where_values, $got_seq)
    }
    $want_seq++;

    if ($iter) {
      my @set;
      foreach my $col (0 .. $#row) {
        if (! _equal ($self->get_value ($iter, $col), $row[$col])) {
          push @set, $col, $row[$col];
        }
      }
      if (@set) {
        ### reread set row: $want_seq-1
        $self->set ($iter, @set);
      } else {
        ### reread unchanged row: $want_seq-1
      }
      $iter = $self->iter_next ($iter);
    } else {
      ### reread append row: $want_seq-1
      @row = map {; ($_ => $row[$_]) } (0 .. $#row);
      $self->insert_with_values (POSIX::INT_MAX(), @row);
    }
  }
  $sth_read->finish;

  if ($iter) {
    ### reread remove excess
    ### from: $self->get_path($iter)->to_string
    ### to: $self->iter_n_children(undef)
    while ($self->remove ($iter)) {
    }
  }
  ### reread done
}

sub _equal {
  my ($x, $y) = @_;
  if (defined $x) {
    if (defined $y) {
      return $x eq $y;
    }
    return 0;
  } else {
    return ! defined $y;
  }
}

# .... untested ....
sub fixup {
  my ($self, %options) = @_;
  ### ListSeq fixup()

  my $dbh = $self->{'dbh'};
  my $where_values = $self->{'where_values'};

  my $message = $options{'message'};
  if (! ref $message) {
    $message = sub { print $_[0],"\n"; };
  }
  my $verbose = $options{'verbose'};

  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         my $table = $self->{'table'};
         my $where_clause = $self->{'where_clause'};
         my $aref = $dbh->selectcol_arrayref
           ("SELECT seq FROM $table $where_clause ORDER BY seq ASC",
            undef, @$where_values);
         ### $aref

         if (_is_0_to_N ($aref)) {
           if ($verbose) {
             $message->('Sequence numbers ok');
           }
         } else {
           $message->('Bad sequence numbers, fixing');

           # seq numbers moved up to $tempseq then back down to 0.  Must
           # force $tempseq not to be negative so the move down works.
           # Since seq+$where_clause should be unique it's the fixup here is
           # to collapse gaps and move up negatives.

           my $sth = $dbh->prepare
             ("UPDATE $table SET seq=? $self->{'where_and'} seq=?");
           my $tempseq = max (0, $aref->[-1] + 1);

           my $newseq = $tempseq;
           foreach my $oldseq (@$aref) {
             $sth->execute ($newseq, @$where_values, $oldseq);
             print "$newseq <- $oldseq\n";
             $sth->finish;
             $newseq++;
           }

           $dbh->do ("UPDATE $table SET seq=seq-$tempseq $where_clause",
                     undef, @$where_values);
           $self->reread;
         }
       });
}

sub _is_0_to_N {
  my ($aref) = @_;
  for (my $i = 0; $i < @$aref; $i++) {
    if ($aref->[$i] != $i) {
      return 0;
    }
  }
  return 1;
}




#------------------------------------------------------------------------------
# local changes propagated to database

# 'row-changed' class closure
sub _do_row_changed {
  my ($self, $path, $iter) = @_;

  if (! $self->{'reading_database'}) {
    ### ListSeq _do_row_changed(): $path->to_string

    my $dbh = $self->{'dbh'} || croak 'No DBI handle to store change';
    my $columns = $self->{'columns'};

    my $sth_change = ($self->{'sth'}->{'change'} ||= do {
      $dbh->prepare ("UPDATE $self->{'table'} SET "
                     . join (',', map {; "$_=?" } @$columns)
                     . "$self->{'where_and'} seq=?")
    });

    my @values = map { $self->get_value($iter,$_) } (0 .. $#$columns);
    my ($seq) = $path->get_indices;

    my $affected = $sth_change->execute (@values,
                                         @{$self->{'where_values'}},
                                         $seq);
    $sth_change->finish;

    if ($affected != 1) {
      # $self->reread;
      croak "ListSeq: oops, expected to change 1, got $affected";
    }

    # local $self->{'reading_database'} = 1;
    # App::Chart::Glib::Ex::DirBroadcast->send ('dbi-changed', $where, $seq);
  }
  return shift->signal_chain_from_overridden(@_);
}

# 'row-deleted' class closure
sub _do_row_deleted {
  my ($self, $path) = @_;
  delete $self->{'hash'};
  if (! $self->{'reading_database'}) {
    ### ListSeq _do_row_deleted(): $path->to_string

    my $dbh = $self->{'dbh'} || croak 'No DBI handle to apply delete';
    my $where_values = $self->{'where_values'};
    my ($seq) = $path->get_indices;
    my $affected;

    my $sth_delete = ($self->{'sth'}->{'delete'} ||= do {
      $dbh->prepare ("DELETE FROM $self->{'table'} $self->{'where_and'} seq=?")
    });

    my $sth_shift_down = ($self->{'sth'}->{'shift_down'} ||= do {
      # -1-(seq-1) == -seq
      $dbh->prepare ("UPDATE $self->{'table'} SET seq=-seq"
                     . " $self->{'where_and'} seq>?")
    });

    App::Chart::Database::call_with_transaction
        ($dbh, sub {
           $affected = $sth_delete->execute (@$where_values, $seq);
           $sth_delete->finish;

           if ($affected != 1) {
             # $self->reread;
             croak "ListSeq: oops, expected to delete 1, got $affected";
           }

           $sth_shift_down->execute (@$where_values, $seq);
           $sth_shift_down->finish;
           _negate ($self);
         });
    # local $self->{'reading_database'} = 1;
    # App::Chart::Glib::Ex::DirBroadcast->send ('dbi-delete', $where, $seq);
  }
  return shift->signal_chain_from_overridden(@_);
}

# 'row-inserted' class closure
sub _do_row_inserted {
  my ($self, $path, $iter) = @_;
  ### ListSeq _do_row_inserted(): $path->to_string
  ### reading_database: $self->{'reading_database'}

  if (! $self->{'reading_database'}) {

    my ($seq) = $path->get_indices;
    my $dbh = $self->{'dbh'} || croak 'No DBI handle to apply insert';
    my $columns = $self->{'columns'};
    my $where_values  = $self->{'where_values'};

    my $sth_lastseq = ($self->{'sth'}->{'lastseq'} ||= do {
      $dbh->prepare ("SELECT seq FROM $self->{'table'}"
                     . " $self->{'where_clause'} ORDER BY seq DESC LIMIT 1")
    });
    my $sth_shift_up = ($self->{'sth'}->{'shift_up'} ||= do {
      # -1-(seq+1) == -2-seq
      $dbh->prepare ("UPDATE $self->{'table'} SET seq=-2-seq"
                     . " $self->{'where_and'} seq>=?")
    });
    my $sth_insert = ($self->{'sth'}->{'insert'} ||= do {
      my $where_columns = $self->{'where_columns'};
      my @columns = ('seq', @$where_columns, @$columns);
      $dbh->prepare
        ("INSERT INTO $self->{'table'} (" . join(',',@columns)
         . ') VALUES (' . join(',', ('?')x(@columns)) . ')');
    });

    my @values = map { $self->get_value($iter,$_) } (0 .. $#$columns);

    App::Chart::Database::call_with_transaction
        ($dbh, sub {
           $sth_lastseq->execute (@$where_values);
           my ($lastseq) = $sth_lastseq->fetchrow_array;
           $sth_lastseq->finish;
           if (! defined $lastseq) { $lastseq = -1; }
           ### lastseq: $lastseq

           if ($seq > $lastseq+1) {
             croak "ListSeq: oops, insert seq $seq but last is $lastseq";
           }

           $sth_shift_up->execute (@$where_values, $seq);
           $sth_shift_up->finish;

           _negate ($self);

           $sth_insert->execute ($seq, @$where_values, @values);
           $sth_insert->finish;
         });
    # local $self->{'reading_database'} = 1;
    # App::Chart::Glib::Ex::DirBroadcast->send ('dbi-inserted', $where,$seq);
  }
  return shift->signal_chain_from_overridden(@_);
}

# 'rows-reordered' connected on self
sub _do_rows_reordered {
  my ($self, $path, $iter, $aref) = @_;

  delete $self->{'hash'};
  if (! $self->{'reading_database'}) {
    ### ListSeq _do_rows_reordered(): $aref

    my $dbh = $self->{'dbh'} || croak 'No DBI handle to reorder';
    my $where_values  = $self->{'where_values'};

    my $sth_reorder = ($self->{'sth'}->{'reorder'} ||= do {
      $dbh->prepare ("UPDATE $self->{'table'} SET seq=?"
                     . " $self->{'where_and'} seq=?")
    });

    App::Chart::Database::call_with_transaction
        ($dbh, sub {
           foreach my $newpos (0 .. $#$aref) {
             my $oldpos = $aref->[$newpos];
             if ($oldpos != $newpos) {
               ### renumber: "from $oldpos to ".(-1-$newpos)
               $sth_reorder->execute (-1-$newpos, @$where_values, $oldpos);
               $sth_reorder->finish;
             }
           }
           _negate ($self);
         });
    # local $self->{'reading_database'} = 1;
    # App::Chart::Glib::Ex::DirBroadcast->send ('dbi-reordered', $key);
  }
}

sub _negate {
  my ($self) = @_;
  my $dbh = $self->{'dbh'};
  my $sth_negate = ($self->{'sth'}->{'negate'} ||= do {
    my $table = $self->{'table'};
    my $where_and = $self->{'where_and'};
    $dbh->prepare ("UPDATE $table SET seq=-1-seq $where_and seq<0")
  });
  my $where_values = $self->{'where_values'};
  $sth_negate->execute (@$where_values);
  $sth_negate->finish;
}


1;
__END__

=for stopwords DBI ListStoreDBISeq ListSeq TreeView DnD arrayref ListStore TreePath TreeIter hashref undef

=head1 NAME

App::Chart::Gtk2::Ex::ListStoreDBISeq -- list read from DBI table with "seq"

=for test_synopsis my ($dbh)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::ListStoreDBISeq;
 my $ls = App::Chart::Gtk2::Ex::ListStoreDBISeq->new (dbh => $dbh,
                                          table => 'mytable',
                                          columns => ['c1','c2']);

 # changing the store updates the database
 $ls->set ($ls->get_iter_first, 0 => 'newval');

 # insert updates sequence numbers
 $ls->insert_with_values (3, 0=>'newrow');

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Ex::ListStoreDBISeq> is a subclass of C<Gtk2::ListStore>, though
perhaps in the future it'll be just a C<Glib::Object>.

    Glib::Object
      Gtk2::ListStore
        App::Chart::Gtk2::Ex::ListStoreDBISeq

=head1 DESCRIPTION

A ListStoreDBISeq holds data values read from a DBI table with a sequence
number in it.  The sequence number column must be called "seq".  For example

    seq   col1  col2
    0     aaa   first
    1     bbb   another
    2     ccc   yet more
    3     ddd   blah

This is designed for use with data rows that should be kept in a given
order, like a user shopping list or "to do" list.

Changes made to the ListSeq in the program are immediately applied to the
database.  This means the database contents can be edited by the user with a
C<Gtk2::TreeView> or similar, and any programmatic changes are then
reflected in the view too.

The current implementation is a subclass of C<Gtk2::ListStore> because it's
got a fairly reasonable set of editing functions, and it's fast when put in
a TreeView.

=head2 Drag and Drop

A ListSeq inherits drag-and-drop from C<Gtk2::ListStore> but it's worth
noting DnD works by inserting and deleting rows rather than a direct
re-order.  This means a drop will first create an empty row, so even if you
normally don't want empty rows in the database you'll have to relax database
constraints on that so it can be created first then filled a moment later.


=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::ListStoreDBISeq->new (key => value, ...) >>

=back

=head1 PROPERTIES

=over 4

=item C<dbh> (DBI database handle)

=item C<table> (string)

=item C<columns> (arrayref of strings)

The DBI handle, table name, and column names to present in the ListStore.

The "seq" column can be included in the presented data if desired, though
it's value will always be the same as the row position in the ListStore,
which you can get from the TreePath or TreeIter anyway.

=item C<where> (hashref, default undef)

A set of column values to match in "where" clauses for the data.  This
allows multiple sequences to be stored in a single table, with a column
value keeping them separate.  The property here is a hashref of column names
and values.  For example,

    $ls->set (where => { flavour => 'foo' });

The table could have

    flavour  seq   content
    foo      0     aaa
    foo      1     bbb
    foo      2     ccc
    foo      3     ddd
    bar      0     xxx
    bar      1     yyy

and only the "foo" rows are presented and edited by the ListSeq.

Note that this C<where> cannot select a subset of a sequence and attempting
to do so will probably corrupt the sequential numbering.

When setting a C<where> property must be done before setting C<dbh> etc, or
(in the current implementation) the ListSeq will try to read without the
C<where> clause, which will almost certainly fail (with duplicate seq
numbers).

=back

=head1 SEE ALSO

L<Gtk2::ListStore>

=cut
