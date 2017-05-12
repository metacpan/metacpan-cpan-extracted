# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Gtk2::Ex::ListStore::DBI;
use 5.008;
use strict;
use warnings;
use Carp;
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

  #   # class closure no good as of Perl-Gtk2 1.221, must connect to self
  #   $self->signal_connect (rows_reordered => \&_do_rows_reordered);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### ListStore-DBI SET_PROPERTY(): $pname
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
  ### ListStore-DBI where_clause: $self->{'where_clause'}
  ### where_and: $self->{'where_and'}
  ### where_values: $self->{'where_values'}
}

sub reread {
  my ($self) = @_;
  ### ListStore-DBI reread()

  my $dbh = $self->{'dbh'};
  my $table = $self->{'table'};
  my $columns = $self->{'columns'};
  my $where_values = $self->{'where_values'};

  local $self->{'reading_database'} = 1;

  unless ($dbh && $table && $columns) {
    $self->clear;
    return;
  }

  my $sth = ($self->{'sth'}->{'read'} ||= do {
    $dbh->prepare ('SELECT ' . join(',', @$columns)
                   . " FROM ".$dbh->quote_identifier($table)
                   . " $self->{'where_clause'}"
                   . ($self->{'order_by'}
                      ? "ORDER BY $self->{'order_by'}"
                      : ''));
  });
  $sth->execute (@$where_values);

  local $self->{'reading_database'} = 1;
  my $iter = $self->get_iter_first;

  while (my @row = $sth->fetchrow_array) {
    if ($iter) {
      my @set;
      foreach my $col (0 .. $#row) {
        if (! _equal ($self->get_value ($iter, $col), $row[$col])) {
          push @set, $col, $row[$col];
        }
      }
      if (@set) {
        $self->set ($iter, @set);
      }
      $iter = $self->iter_next ($iter);
    } else {
      ### reread() append row
      $self->insert_with_values (POSIX::INT_MAX(),
                                 map {; ($_, $row[$_]) } (0 .. $#row));
    }
  }
  $sth->finish;

  if ($iter) {
    ### reread() remove excess
    ### from: $self->get_path($iter)->to_string
    ### to: $self->iter_n_children(undef)
    while ($self->remove ($iter)) {
    }
  }
  ### reread() done
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


#------------------------------------------------------------------------------
# local changes propagate to database

# 'row-changed' class closure
sub _do_row_changed {
  my ($self, $path, $iter) = @_;

  unless ($self->{'reading_database'}) {
    ### ListStore-DBI _do_row_changed(): $path->to_string

    my $dbh = $self->{'dbh'} || croak 'No DBI handle to store change';
    my $columns = $self->{'columns'};

    my $sth = ($self->{'sth'}->{'change'} ||= do {
      $dbh->prepare ("UPDATE ".$dbh->quote_identifier($self->{'table'})
                     . "SET " . join (',', map {; "$_=?" } @$columns)
                     . "$self->{'where_clause'}")
    });

    my $affected = $sth->execute ($self->get_value ($iter, 0 .. $#$columns),
                                  @{$self->{'where_values'}});
    $sth->finish;

    if ($affected != 1) {
      # $self->reread;
      croak "ListStore-DBI: oops, expected to change 1, got $affected";
    }
  }
  return shift->signal_chain_from_overridden(@_);
}

# 'row-deleted' class closure
sub _do_row_deleted {
  my ($self, $path) = @_;

  unless ($self->{'reading_database'}) {
    ### ListStore-DBI _do_row_deleted(): $path->to_string

    my $dbh = $self->{'dbh'} || croak 'No DBI handle to apply delete';
    my $where_values = $self->{'where_values'};
    my $affected;

    my $sth = ($self->{'sth'}->{'delete'} ||= do {
      $dbh->prepare ("DELETE FROM ".$dbh->quote_identifier($self->{'table'})
                     . " $self->{'where_clause'}")
    });
    $affected = $sth->execute (@$where_values);
    $sth->finish;

    if ($affected != 1) {
      # $self->reread;
      croak "ListStore-DBI: oops, expected to delete 1, got $affected";
    }
  }
  return shift->signal_chain_from_overridden(@_);
}

# 'row-inserted' class closure
sub _do_row_inserted {
  my ($self, $path, $iter) = @_;
  ### ListStore-DBI _do_row_inserted(): $path->to_string

  unless ($self->{'reading_database'}) {
    my $dbh = $self->{'dbh'} || croak 'No DBI handle to apply insert';
    my $columns = $self->{'columns'};

    my $sth = ($self->{'sth'}->{'insert'} ||= do {
      my @columns = (@{$self->{'where_columns'}}, @$columns);
      $dbh->prepare
        ("INSERT INTO " . $dbh->quote_identifier($self->{'table'})
         . " (" . join(',',@columns)
         . ') VALUES (' . join(',', ('?')x(@columns)) . ')');
    });
    $sth->execute (@{$self->{'where_values'}},
                   $self->get_value($iter,0 .. $#$columns));
    $sth->finish;
  }
  return shift->signal_chain_from_overridden(@_);
}

# # 'rows-reordered' connected on self
# sub _do_rows_reordered {
#   my ($self, $path, $iter, $aref) = @_;
# 
#   unless ($self->{'reading_database'}) {
#     ### ListStore-DBI _do_rows_reordered(): $aref
# 
#     my $dbh = $self->{'dbh'} || croak 'No DBI handle to reorder';
#     my $where_values  = $self->{'where_values'};
# 
#     my $sth_reorder = ($self->{'sth'}->{'reorder'} ||= do {
#       $dbh->prepare ("UPDATE $self->{'table'} SET seq=?"
#                      . " $self->{'where_and'} seq=?")
#     });
# 
#     App::Chart::Database::call_with_transaction
#         ($dbh, sub {
#            foreach my $newpos (0 .. $#$aref) {
#              my $oldpos = $aref->[$newpos];
#              if ($oldpos != $newpos) {
#                ### renumber: "from $oldpos to ".(-1-$newpos)
#                $sth_reorder->execute (-1-$newpos, @$where_values, $oldpos);
#                $sth_reorder->finish;
#              }
#            }
#            _negate ($self);
#          });
#     # local $self->{'reading_database'} = 1;
#     # App::Chart::Glib::Ex::DirBroadcast->send ('dbi-reordered', $key);
#   }
# }


#------------------------------------------------------------------------------
# compatibility

BEGIN {
  unless (Gtk2::ListStore->can('insert_with_values')) {
    eval <<'HERE';
 sub insert_with_values {
   my $self = shift;
   my $position = shift;
   $self->set ($self->insert($position), @_);
 }
HERE
  }
}

1;
__END__

=for stopwords App::Chart::Gtk2::Ex::ListStore::DBI ListStore-DBI DBI TreeView DnD arrayref ListStore TreePath TreeIter hashref undef

=head1 NAME

App::Chart::Gtk2::Ex::ListStore::DBI -- rows from a DBI table

=for test_synopsis my ($dbh)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::ListStore::DBI;
 my $ls = App::Chart::Gtk2::Ex::ListStore::DBI->new (dbh => $dbh,
                                         table => 'mytable',
                                         columns => ['c1','c2']);

 # changing the store updates the database
 $ls->set ($ls->get_iter_first, 0 => 'newval');

 # insert updates sequence numbers
 $ls->insert_with_values (3, 0=>'newrow');

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Ex::ListStore::DBI> is a subclass of C<Gtk2::ListStore>, though
perhaps in the future it'll be just a C<Glib::Object>.

    Glib::Object
      Gtk2::ListStore
        App::Chart::Gtk2::Ex::ListStore::DBI

=head1 DESCRIPTION

A ListStore-DBI holds data values read from a DBI table.  For example

    col1  col2
    aaa   first
    bbb   another
    ccc   yet more
    ddd   blah

This is designed for use with data rows that should be kept in a given
order, like a user shopping list or "to do" list.

Changes made to the ListStore-DBI in the program are immediately applied to
the database.  This means the database contents can be edited by the user
with a C<Gtk2::TreeView> or similar, and any programmatic changes to the
model are reflected in the view too.

The current implementation is a subclass of C<Gtk2::ListStore> because it's
got a fairly reasonable set of editing functions, and it's fast when put in
a TreeView.

=head2 Drag and Drop

A ListStore-DBI inherits drag-and-drop from C<Gtk2::ListStore> but it's worth
noting DnD works by inserting and deleting rows rather than a direct
re-order.  This means a drop will first create an empty row, so even if you
normally don't want empty rows in the database you'll have to relax database
constraints on that so it can be created first then filled a moment later.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::ListStore::DBI->new (key => value, ...) >>

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

    flavour  content
    foo      aaa
    foo      bbb
    foo      ccc
    foo      ddd
    bar      xxx
    bar      yyy

and only the "foo" rows are presented and edited by the ListStore-DBI.

Note that this C<where> cannot select a subset of a sequence and attempting
to do so will probably corrupt the sequential numbering.

When setting a C<where> property must be done before setting C<dbh> etc, or
(in the current implementation) the ListStore-DBI will try to read without the
C<where> clause, which will almost certainly fail (with duplicate seq
numbers).

=back

=head1 SEE ALSO

L<Gtk2::ListStore>

=cut
