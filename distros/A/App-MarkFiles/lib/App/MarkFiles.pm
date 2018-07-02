=pod

=head1 NAME

App::MarkFiles - some utility functions for marking and operating on files

=head1 SYNOPSIS

    # This module:
    use App::MarkFiles qw(get_dbh each_path add remove);

    my $dbh = get_dbh(); # db handle for marks.db

    add('/foo/bar', '/foo/baz');

    remove('/foo/baz');

    each_path(sub {
      my ($path) = @_;
      print "$path\n";
    });

    # mark commands:
    $ mark add foo.txt
    $ cd ~/somedir
    $ mark mv

=head1 INSTALLING

    $ perl Build.PL
    $ ./Build
    $ ./Build install

=head1 DESCRIPTION

The mark utilities store a list of marked file paths in marks.db in the user's
home directory.  Once marked, files can be copied, moved, listed, or passed as
parameters to arbitrary shell commands.

This originated as a simple tool for collecting files from one or more
directories and moving or copying them to another.  A basic usage pattern
looks something like this:

    $ cd ~/screenshots
    $ mark add foo.png
    $ cd ~/blog/files/screenshots
    $ mark mv
    Moved: /home/brennen/screenshots/foo.png

This is more steps than a simple invocation of mv(1), but its utility becomes
more apparent when it's combined with aliases for quickly navigating
directories or invoked from other programs like editors and file managers.

See C<bin/mark> in this distribution (or, when installed, the mark(1) man page)
for details on the commands.

=cut

package App::MarkFiles;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(get_dbh each_path add remove);

our ($VERSION) = '0.0.1';

use DBI;
use File::HomeDir;
use File::Spec;

=head1 SUBROUTINES

=over

=item get_dbh()

Get database handle for default marks database, stored in F<~/marks.db>.

Creates a new marks.db with the correct schema if one doesn't already exist.

=cut

sub get_dbh {
  my $dbfile = File::Spec->catfile(File::HomeDir->my_home, 'marks.db');

  my $init_new = 0;
  $init_new = 1 unless -f $dbfile;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

  create_mark_db($dbh) if $init_new;

  return $dbh;
}

=item create_mark_db($dbh)

Create a new marks table.

=cut

sub create_mark_db {
  my ($dbh) = @_;

  $dbh->do(<<'SQL'
    CREATE TABLE marks (
      id integer primary key,
      path text,
      datetime text
    );
SQL
  );
}

=item add(@paths)

Add a mark to one or more paths.

=cut

sub add {
  my (@paths) = @_;

  # Filter out any paths that have already been marked:
  my %pathmap = map { $_ => 1 } @paths;
  each_path(sub {
    my ($existing_path) = @_;
    if ($pathmap{ $existing_path }) {
      delete $pathmap{ $existing_path };
    }
  });

  my $sth = get_dbh()->prepare(q{
    INSERT INTO marks (path, datetime) VALUES (?, datetime('now'))
  });

  foreach my $path (keys %pathmap) {
    $sth->execute($path);
  }
}

=item remove(@paths)

Remove all given paths from the mark list.

=cut

sub remove {
  my (@paths) = @_;

  my $sth = get_dbh()->prepare(q{
    DELETE FROM marks WHERE PATH = ?;
  });

  foreach my $path (@paths) {
    $sth->execute($path);
  }
}

=item each_path($func)

Run an anonymous function against each item in the mark list.

Expects a sub which takes a path string.

=cut

sub each_path {
  my ($func) = @_;

  my $sth = get_dbh()->prepare(q{
    SELECT DISTINCT(path) as path FROM marks ORDER BY datetime;
  });

  $sth->execute();

  while (my $data = $sth->fetchrow_hashref()) {
    $func->($data->{path});
  }
}

=back

=head1 AUTHOR

Copyright 2018 Brennen Bearnes

    mark is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

=cut

1;
