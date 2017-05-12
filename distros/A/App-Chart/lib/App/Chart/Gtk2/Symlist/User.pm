# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::Symlist::User;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
# use Locale::TextDomain ('App-Chart');


use App::Chart::Gtk2::Symlist;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Symlist';

sub can_edit    { return 1; }
sub can_delete_symlist { return 1; }

sub delete_symlist {
  my ($self) = @_;
  my $key = $self->{'key'};
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $seq;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         $seq = App::Chart::Database::read_notes_single
           ('SELECT seq FROM symlist WHERE key=?', $key);
         $dbh->do ('DELETE FROM symlist WHERE key=?', undef, $key);
         $dbh->do ('DELETE FROM symlist_content WHERE key=?', undef, $key);
         if (defined $seq) {
           $dbh->do ('UPDATE symlist SET seq=-seq WHERE seq>?', undef, $seq);
           $dbh->do ('UPDATE symlist SET seq=-seq-1 WHERE seq<0');
         }
         { local $self->{'reading_database'} = 1;
           $self->clear;
         }
       });
  App::Chart::chart_dirbroadcast()->send ('symlist-list-deleted', $seq);
}

sub add_symlist {
  my ($class, $pos, $name) = @_;
  require App::Chart::Gtk2::SymlistListModel;
  my $list = App::Chart::Gtk2::SymlistListModel->instance;
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $key;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         $key = new_user_symlist_key($dbh);
         $list->insert_with_values ($pos,
                                    $list->COL_KEY => $key,
                                    $list->COL_NAME => $name);
       });
  return $key;
}

sub new_user_symlist_key {
  for (my $i = 1; $i < 1_000_000; $i++) {
    my $key = "user-$i";
    if (! App::Chart::Database::read_notes_single
        ('SELECT key FROM symlist WHERE key=?', $key)) {
      return $key;
    }
  }
  die "Oops, cannot find new user symlist key";
}

1;
__END__
