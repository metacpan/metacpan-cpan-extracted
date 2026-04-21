package Test::DBIW;

use strict;
use warnings;
use DBI;
use DBIx::Wizard;
use DBIx::Wizard::DB;
use Exporter 'import';

our @EXPORT = qw(setup_test_db cleanup_test_db $DBFILE);

our $DBFILE = "/tmp/dbiw_test_$$.db";

sub setup_test_db {
  DBIx::Wizard::DB->declare('testdb', "dbi:SQLite:dbname=$DBFILE", '', '', { RaiseError => 1 });

  my $dbh = DBIx::Wizard::DB->dbh('testdb');
  $dbh->do('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, status TEXT)');
  $dbh->do('CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, amount REAL)');

  return $dbh;
}

sub cleanup_test_db {
  unlink $DBFILE if -e $DBFILE;
}

1;
