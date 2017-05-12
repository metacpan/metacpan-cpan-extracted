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

package App::Chart::DBI;
use 5.006;
use strict;
use warnings;
use File::Spec;

use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

# See Database/Create.pm for revisions
use constant DATABASE_SCHEMA_VERSION => 2;


# return the database filename ~/Chart/database.sqdb or the notes database
# filename ~/Chart/notes.sqdb, as absolute path in filesystem charset bytes
use constant::defer database_filename => sub {
  return File::Spec->catfile (App::Chart::chart_directory(), 'database.sqdb');
};
use constant::defer notes_filename => sub {
  return File::Spec->catfile(App::Chart::chart_directory(), 'notes.sqdb');
};

use Class::Singleton 1.4;
use base 'Class::Singleton';
our $_instance;

# singleton
sub _new_instance {
  ### Chart-DBI _new_instance()
  my $database_filename = database_filename();
  ### $database_filename

  if (! -e $database_filename) {
    require App::Chart::Database::Create;
    App::Chart::Database::Create::initial_database ($database_filename);
  }

  my $notes_filename = notes_filename();
  ### $notes_filename
  if (! -e $notes_filename) {
    require App::Chart::Database::Create;
    App::Chart::Database::Create::initial_notes ($notes_filename);
  }

  require DBI;
  my $dbh = DBI->connect ("dbi:SQLite:dbname=$database_filename",
                          '', '', {RaiseError=>1});
  $dbh->func(90_000, 'busy_timeout');  # 90 seconds
  $dbh->{'sqlite_unicode'} = 1;
  $dbh->do ('ATTACH DATABASE ' . $dbh->quote($notes_filename)
            . ' AS notesdb');

  my ($dbversion) = do {
    local $dbh->{RaiseError} = undef;
    local $dbh->{PrintError} = undef;
    $dbh->selectrow_array
      ("SELECT value FROM extra WHERE key='database-schema-version'")
    };
  $dbversion ||= 0;
  if ($dbversion < DATABASE_SCHEMA_VERSION) {
    require App::Chart::Database::Create;
    $_instance = $dbh;
    App::Chart::Database::Create::upgrade_database ($dbh, $dbversion);
  }

  return $dbh;
}

sub disconnect {
  my ($class) = @_;
  ### Chart-DBI _disconnect()
  if (my $dbh = $class->has_instance) {

    # Empty cache to suppress warnings about statement handles.
    # Is this supposed to be necessary?
    $dbh->{'CachedKids'} = {};

    $dbh->disconnect;
    no strict; # created on-demand by Singleton
    $_instance = undef;
  }
}

sub read_single {
  my ($dbh, $sql, @args) = @_;
  if (! ref $dbh) { $dbh = $dbh->instance; }
  { local $SIG{__DIE__} = sub { die "read_single('$sql')\n$@" };
    my $sth =  $dbh->prepare_cached ($sql);
    my ($ret) = $dbh->selectrow_array ($sth, undef, @args);
    $sth->finish;
    return $ret;
  }
}

# sub transaction {
#   my ($dbh, $subr) = @_;
#   my $hold = App::Chart::chart_dirbroadcast()->hold;
# 
#   if ($dbh->{AutoCommit}) {
#     $dbh->begin_work;
#     local $SIG{__DIE__} = sub {
#       ### Error during DBI transaction: "@_"
#       $dbh->rollback;
#       die @_;
#     };
#     $subr->();
#     $dbh->commit;
#   } else {
#     $subr->();
#   }
# }

1;
__END__

# =for stopwords DBI
# 
# =head1 NAME
# 
# App::Chart::DBI -- database interface
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< $dbh = App::Chart::DBI->instance() >>
# 
# Return a DBI database handle for the Chart database.
# 
# =item C<< App::Chart::DBI->disconnect() >>
# 
# Disconnect the DBI database handle, if connected.
# 
# =back
# 
# =cut
