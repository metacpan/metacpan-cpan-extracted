#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2014 Kevin Ryde

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

use strict;
use warnings;
use Data::Dumper;
use App::Chart::Database;
use App::Chart::Gtk2::Ex::ListStoreDBISeq;

sub show {
  my ($model) = @_;
  $model->foreach (sub {
                     my ($model, $path, $iter) = @_;
                     my $value = $model->get_value($iter, 0);
                     print $path->to_string," ",
                       defined $value ? $value : 'undef', "\n";
                     return 0; # keep walking
                   });
}

{
  # my $dbh = App::Chart::DBI->instance();
  require DBI;
  unlink ('/tmp/foo.sqdb');
  my $dbh = DBI->connect ("dbi:SQLite:dbname=/tmp/foo.sqdb",
                          '', '', {RaiseError=>1});
  $dbh->{sqlite_unicode} = 1;

  $dbh->do ('CREATE TABLE symlist (
    seq        INT      NOT NULL,
    x          INT,
    key        TEXT,
    name       TEXT,
    condition  TEXT     DEFAULT NULL,
    PRIMARY KEY (x,seq))
');
  $dbh->do ('INSERT INTO symlist (seq,key,x) VALUES (0,\'aaa\',44)');
  $dbh->do ('INSERT INTO symlist (seq,key,x) VALUES (1,\'ccc\',44)');
  $dbh->do ('INSERT INTO symlist (seq,key,x) VALUES (0,\'bbb\',55)');
  $dbh->do ('INSERT INTO symlist (seq,key,x) VALUES (1,\'ddd\',55)');

  my $symlist = App::Chart::Gtk2::Ex::ListStoreDBISeq->new (where => { x => 55},
                                                dbh => $dbh,
                                                table => 'symlist',
                                                columns => ['key']);
  show ($symlist);

  $symlist->remove ($symlist->iter_nth_child(undef,0));
  show ($symlist);

  $symlist->insert (1);
  show ($symlist);

  $symlist->append;
  show ($symlist);

  #   $dbh->do('DELETE FROM symlist WHERE seq=1');
  #   $symlist->append;

  # $dbh->do('DELETE FROM symlist WHERE seq=1');
  # $dbh->do ('INSERT INTO symlist (seq,key,x) VALUES (-1,\'ddd\',55)');
  # $symlist->reread;
  $dbh->do ('UPDATE symlist SET seq=-4-seq');

  $symlist->fixup (verbose => 1);
  show ($symlist);

  exit 0;
}
