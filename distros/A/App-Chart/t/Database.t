#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
use Test::More tests => 15;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Database;

App::Chart::Database->add_symbol ('FOO.TEST');
ok (App::Chart::Database->symbol_exists ('FOO.TEST'));

App::Chart::Database->delete_symbol ('FOO.TEST');
ok (! App::Chart::Database->symbol_exists ('FOO.TEST'));

App::Chart::Database->add_symbol ('FOO.TEST');
ok (App::Chart::Database->symbol_exists ('FOO.TEST'));

App::Chart::Database->add_symbol ('FOO.TEST');
ok (App::Chart::Database->symbol_exists ('FOO.TEST'));

{
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  $dbh->do("DELETE FROM extra WHERE symbol='FOO.TEST'");
}
App::Chart::Database->write_extra ('FOO.TEST', 'test-key', 123);
is (App::Chart::Database->read_extra ('FOO.TEST', 'test-key'), 123);
App::Chart::Database->write_extra ('FOO.TEST', 'test-key', 456);
is (App::Chart::Database->read_extra ('FOO.TEST', 'test-key'), 456);
App::Chart::Database->write_extra ('FOO.TEST', 'test-key', 789);
is (App::Chart::Database->read_extra ('FOO.TEST', 'test-key'), 789);


App::Chart::Database->delete_symbol ('FOO.TEST');


#------------------------------------------------------------------------------
# call_with_transaction

{
  require File::Temp;
  my $fh = File::Temp->new (TEMPLATE => 'chart-test-database-transaction-XXXXXX',
                            SUFFIX => '.sqdb',
                            TMPDIR => 1);
  my $filename = $fh->filename;
  diag "temp database file $filename";
  my $dbh = DBI->connect ("dbi:SQLite:dbname=$filename",
                          '', '', {RaiseError=>1});
  my $ac;
  my $ret = App::Chart::Database::call_with_transaction
    ($dbh, sub {
       $ac = $dbh->{AutoCommit};
       return 'my return value';
     });
  is ($ret, 'my return value');
  ok (! $ac,              'call_with_transaction AutoCommit off');
  ok ($dbh->{AutoCommit}, 'call_with_transaction AutoCommit back on');


  my ($ac_inner, $ac_outer_again);
  $ret = App::Chart::Database::call_with_transaction
    ($dbh, sub {
       $ac = $dbh->{AutoCommit};

       my $r = App::Chart::Database::call_with_transaction
         ($dbh, sub {
            $ac_inner = $dbh->{AutoCommit};
            return 'my return value';
          });

       $ac_outer_again = $dbh->{AutoCommit};
       return $r;
     });
  is ($ret, 'my return value');

  ok (! $ac,
      'call_with_transaction AutoCommit off');
  ok (! $ac_inner,
      'call_with_transaction AutoCommit inner still off');
  ok (! $ac_outer_again,
      'call_with_transaction AutoCommit outer again still off');
  ok ($dbh->{AutoCommit},
      'call_with_transaction AutoCommit back on');

  $dbh->disconnect;
}


exit 0;
