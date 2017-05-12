# Copyright 2008, 2009, 2010, 2011, 2014 Kevin Ryde

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


package App::Chart::Gtk2::SymlistListModel;
use 5.010;
use strict;
use warnings;
use Glib;
use Gtk2;
use Carp;

use App::Chart::Database;
use App::Chart::Gtk2::Symlist;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant DEBUG => 0;

use App::Chart::Gtk2::Ex::ListStoreDBISeq;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Ex::ListStoreDBISeq',
  signals => { row_changed    => \&_do_row_changed,
               row_inserted   => \&_do_row_inserted,
               row_deleted    => \&_do_row_deleted };

use constant { COL_KEY       => 0,
               COL_NAME      => 1,
               COL_CONDITION => 2,
               NUM_COLUMNS   => 3
             };

use Exporter;
our @ISA;
unshift @ISA, 'Exporter';
our @EXPORT_OK = qw(COL_KEY COL_NAME COL_CONDITION);
               
use base 'Class::WeakSingleton';
*_new_instance = \&Glib::Object::new;

sub INIT_INSTANCE {
  my ($self) = @_;

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  $self->set_property (columns => [ 'key', 'name', 'condition' ],
                       table => 'symlist',
                       dbh => $dbh);

  $self->signal_connect (rows_reordered => \&_do_rows_reordered);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-list-inserted', \&_do_symlist_inserted, $self);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-list-deleted', \&_do_symlist_deleted, $self);
}

#------------------------------------------------------------------------------
# remote changes

# 'symlist-list-inserted' broadcast handler
sub _do_symlist_inserted {
  my ($self, $seq, $key) = @_;
  if ($self->{'reading_database'}) {
    # this is a broadcast resulting from an insert on the ListStore, it's
    # only for everyone else (locally and remotely), not a ListStore/DB sync
    ### Symlist-List symlist-list-inserted handler while reading_database ...
    return;
  }
  # someone external has changed the database
  # insert a row to make the liststore hopefully like the database except
  # for this wone new row, and check with reread
  { local $self->{'reading_database'} = 1;
    $self->insert_with_values ($seq, COL_KEY, $key);
  }
  $self->reread;
}

# 'symlist-list-deleted' broadcast handler
sub _do_symlist_deleted {
  my ($self, $seq) = @_;
  if ($self->{'reading_database'}) {
    # this is a broadcast resulting from a delete on the ListStore, so it's
    # only for everyone else (locally and remotely), not a ListStore/DB sync
    ### Symlist-List symlist-list-deleted handler while reading_database ...
    return;
  }

  # someone external has changed the database
  # try to make the liststore look like the database, then reread to be sure
  { local $self->{'reading_database'} = 1;
    if (my $iter = $self->iter_nth_child (undef, $seq)) {
      $self->remove ($iter);
    }
  }
  $self->reread;
}

#------------------------------------------------------------------------------
# local changes applied to database

sub remove {
  my ($self, $iter) = @_;
  my $key = $self->get($iter,COL_KEY);
  delete $App::Chart::Gtk2::Symlist::instances{$key};
  return $self->SUPER::remove ($iter);
}

# 'row-changed' class closure
sub _do_row_changed {
  my ($self, $path, $iter) = @_;
  $self->signal_chain_from_overridden ($path, $iter);

  if ($self->{'reading_database'}) { return; }

  my ($seq) = $path->get_indices;
  my $key = $self->get_value($iter,COL_KEY);
  if (DEBUG) {
    my $name = $self->get_value($iter,COL_NAME);
    my $condition = $self->get_value($iter,COL_CONDITION);
    print "Symlist List database change seq=$seq",
      " to key=",defined $key ? "'$key'" : 'undef',
        " name=",defined $name ? "'$name'" : 'undef',
          " cond=",defined $condition ? "'$condition'" : 'undef',"\n";
  }
  local $self->{'reading_database'} = 1;
  App::Chart::chart_dirbroadcast()->send ('symlist-list-changed', $seq,$key);
}

# 'row-deleted' class closure
sub _do_row_deleted {
  my ($self, $path) = @_;
  $self->signal_chain_from_overridden ($path);
  if ($self->{'reading_database'}) { return; }

  my ($seq) = $path->get_indices;
  ### Symlist-List database delete seq: $seq
  #    database_delete ($self, $seq);
  local $self->{'reading_database'} = 1;
  App::Chart::chart_dirbroadcast()->send ('symlist-list-deleted', $seq);
}

# 'row-inserted' class closure
sub _do_row_inserted {
  my ($self, $path, $iter) = @_;
  $self->signal_chain_from_overridden ($path, $iter);
  if ($self->{'reading_database'}) {
    ### Symlist-List row-inserted while reading_database
    return;
  }

  my ($seq) = $path->get_indices;
  my $key = $self->get_value($iter,0) // '';
  if (DEBUG) {
    my $name = $self->get_value($iter,1) // 'undef';
    print "Symlist List database insert at seq=$seq",
      " key=$key name=$name\n";
  }
  local $self->{'reading_database'} = 1;
  App::Chart::chart_dirbroadcast()->send ('symlist-list-inserted',$seq,$key);
}

# 'rows-reordered' connected on self
sub _do_rows_reordered {
  my ($self, $path, $iter, $aref) = @_;
  if ($self->{'reading_database'}) { return; }

  ### Symlist-List database reorder: "@$aref"
  local $self->{'reading_database'} = 1;
  App::Chart::chart_dirbroadcast()->send ('symlist-list-reordered');
}


#------------------------------------------------------------------------------
# contents

sub length {
  my ($self) = @_;
  return $self->iter_n_children(undef);
}


#------------------------------------------------------------------------------

sub key_to_pos {
  my ($self, $key) = @_;
  my $iter = $self->key_to_iter ($key);
  my ($ret) = $self->get_path($iter)->get_indices;
  return $ret;

  #   return App::Chart::Database::read_notes_single
  #     ('SELECT seq FROM symlist WHERE key=?', $key);
}

sub key_to_iter {
  my ($self, $key) = @_;
  my $ret;
  $self->foreach
    (sub {
       my ($self, $path, $iter) = @_;
       my $this_key = $self->get_value($iter, COL_KEY);
       if (defined $this_key && $this_key eq $key) {
         $ret = $iter->copy;
         return 1; # stop iterating
       }
       return 0; # continue;
     });
  return $ret;
}

1;
__END__
