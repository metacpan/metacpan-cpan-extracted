#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2016, 2017 Kevin Ryde

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
use App::Chart::DBI;
use App::Chart::Download;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # "null" volume
  # SELECT * FROM daily WHERE volume LIKE "%null%";
  # DELETE FROM daily WHERE volume LIKE "%null%";
  exit 0;
}

{
  # find daily data without info record
  # SELECT * FROM daily WHERE NOT EXISTS (SELECT * FROM info WHERE info.symbol=daily.symbol);
  # SELECT DISTINCT symbol FROM daily WHERE NOT EXISTS (SELECT * FROM info WHERE info.symbol=daily.symbol);
  # DELETE FROM daily WHERE symbol LIKE "%.LME";
  # SELECT * FROM daily WHERE symbol LIKE "%.LME";
  exit 0;
}

{
  my $dbh = App::Chart::DBI->instance();
  my $sth = $dbh->prepare_cached
    ('SELECT image, error FROM intraday_image WHERE symbol=? AND mode=?');
  my $ref;
  {
    my $symbol = 'GM';
    my $mode = '1d';
    $ref = \$symbol;
    my ($image, $error) = $dbh->selectrow_array ($sth, undef,
                                                 $symbol,
                                                 $mode);
    $sth->finish();

    ($image, $error) = $dbh->selectrow_array ($sth, undef,
                                              'BHP.AX',
                                              '5d');
    $sth->finish();
  }
  Scalar::Util::weaken($ref);
  ### $ref
  exit 0;
}

{
  my $filename = '/tmp/x.sqdb';
  $ENV{'DBI_TRACE'} = '1';
  require DBI;
  my $dbh = DBI->connect ("dbi:SQLite:dbname=$filename",
                          '', '', {RaiseError=>1});
  $dbh->func(5_000, 'busy_timeout');  # 90 seconds

#  $dbh->do ('CREATE TABLE foo (bar TEXT)');

  $dbh->begin_work;
  $dbh->do ("INSERT INTO foo (bar) VALUES ('hello')");
#  $dbh->commit;
  sleep 100;
  exit 0;
}

{
  App::Chart::Download::vacuum ();
  exit 0;
}
{
  my $dbh = App::Chart::DBI->instance();
  print $dbh->func('busy_timeout'),"\n";
  exit 0;
  my $sth = $dbh->table_info(undef, 'notesdb', '%', undef);
  my $aref = $sth->fetchall_arrayref;
  $sth->finish;
  print Dumper($aref);
  exit 0;
}

# return true if $dbh contains a table called $table
sub dbh_table_exists {
  my ($dbh, $table) = @_;
  my $sth = $dbh->table_info (undef, undef, $table, undef);
  my $exists = $sth->fetchrow_arrayref ? 1 : 0;
  $sth->finish;
  return $exists;
}

{
  my $dbh = App::Chart::DBI->instance();
  my @a = $dbh->tables (undef, undef, undef, undef);
  print Dumper(\@a);

  my $nbh = $dbh;
  @a = $nbh->tables (undef, undef, undef, undef);
  print Dumper(\@a);

  print "", App::Chart::Database::dbh_table_exists ($dbh, undef, 'daily')
    ? "yes\n" : "no\n";
  print "", App::Chart::Database::dbh_table_exists ($nbh, undef, 'preference')
    ? "yes\n" : "no\n";
  print "", App::Chart::Database::dbh_table_exists ($nbh, 'notesdb', 'preference')
    ? "yes\n" : "no\n";

  exit 0;
}






{
  my $dbh = App::Chart::DBI->instance();
  print $dbh->{AutoCommit},"\n";
  App::Chart::Database::call_with_transaction
      ($dbh, sub { print "one-a: ", $dbh->{AutoCommit},"\n";
                   App::Chart::Database::call_with_transaction
                       ($dbh, sub { print "two: ", $dbh->{AutoCommit},"\n";
                                  });
                   print "one-b: ", $dbh->{AutoCommit},"\n";
                 });
  print $dbh->{AutoCommit},"\n";
  exit 0;
}

{
  {
    my $dbh = App::Chart::DBI->instance();
    $dbh->do("DELETE FROM extra WHERE symbol='FOO.TEST'");
  }
  App::Chart::Database->write_extra ('FOO.TEST', 'test-key', 123);
  print App::Chart::Database->read_extra ('FOO.TEST', 'test-key');
  App::Chart::Database->write_extra ('FOO.TEST', 'test-key', 456);
  print App::Chart::Database->read_extra ('FOO.TEST', 'test-key');
  App::Chart::Database->write_extra ('FOO.TEST', 'test-key', 789);
  print App::Chart::Database->read_extra ('FOO.TEST', 'test-key');
  exit 0;
}



{
  foreach ('BHP.AX', 'IPG.AX', 'FPA.NZ', 'TEL.NZ') {
    print App::Chart::Database->symbol_is_historical ($_),"\n";
  }
  exit 0;
}

{
  my $series = App::Chart::Database::read_series ('BHP.AX');
  print Dumper (\$series);
  exit 0;
}

{
  my $dbh = App::Chart::DBI->instance();
  exit 0;
}



{
  App::Chart::Database->add_symbol ('BHP.AX');
  exit 0;
}
