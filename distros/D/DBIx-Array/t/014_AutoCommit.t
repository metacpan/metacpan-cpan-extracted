# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 39;
use File::Temp qw/tempfile/;

BEGIN { use_ok( 'DBIx::Array' ); }

local $@;
eval 'use DBD::SQLite';
my $no_driver = $@;

SKIP: {
  skip 'Database driver DBD::SQLite not installed', 38 if $no_driver;

  my $db1             = DBIx::Array->new;
  my $db2             = DBIx::Array->new;
  my ($fh, $filename) = tempfile();
  diag("Filename: $filename");
  $db1->connect("dbi:SQLite:dbname=$filename", '', '', {AutoCommit=>1});
  $db1->dbh->do('CREATE TABLE mytable (COL1 INTEGER, COL2 CHAR(1), COL3 VARCHAR(10))');
  ok($db1->AutoCommit, 'AutoCommit');
  $db1->AutoCommit(0);
  ok(!$db1->AutoCommit, 'AutoCommit');
  $db2->connect("dbi:SQLite:dbname=$filename", '', '', {AutoCommit=>1});

  is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '0', 'count');
  is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '0', 'count');

  my $sql = 'INSERT INTO mytable (COL1, COL2, COL3) VALUES (?, ?, ?)';
  is($db1->insert($sql, 0, 1, 2), 1, 'insert 1');
  is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '1', 'count');
  is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '0', 'count');

  is($db1->insert($sql, 1, 2, 3), 1, 'insert 2');
  is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '2', 'count');
  is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '0', 'count');

  is($db1->insert($sql, 2, 3, 4), 1, 'insert 3');
  is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '3', 'count');
  is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '0', 'count');

  ok($db1->commit, 'commit');
  is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '3', 'count');
  is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '3', 'count');

  ok(!$db1->AutoCommit, 'AutoCommit');
  {
    local $db1->{'dbh'}->{'AutoCommit'} = 1;

    ok($db1->AutoCommit, 'AutoCommit');
    is($db1->insert($sql, 3, 4, 5), 1, 'insert 4');
    is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '4', 'count');
    is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '4', 'count');
  }
  ok(!$db1->AutoCommit, 'AutoCommit');

  ok($db1->AutoCommit(1), 'AutoCommit');
  {
    local $db1->{'dbh'}->{'AutoCommit'} = 0;

    ok(!$db1->AutoCommit, 'AutoCommit');
    is($db1->insert($sql, 4, 5, 6), 1, 'insert 5');
    is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '5', 'count');
    is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '4', 'count');
    ok($db1->commit, 'commit');

    ok(!$db1->AutoCommit, 'AutoCommit');
    is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '5', 'count');
    is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '5', 'count');
  }
  ok($db1->AutoCommit, 'AutoCommit');

  {
    local $db1->{'dbh'}->{'AutoCommit'} = 0;
    is($db1->insert($sql, 4, 5, 7), 1, 'insert 6');
    is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '6', 'count');
    is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '5', 'count');

    ok($db1->rollback, 'rollback');
    is($db1->sqlscalar('SELECT COUNT(*) FROM mytable'), '5', 'count');
    is($db2->sqlscalar('SELECT COUNT(*) FROM mytable'), '5', 'count');
  }

  #cleanup
  unlink  $filename;
}
