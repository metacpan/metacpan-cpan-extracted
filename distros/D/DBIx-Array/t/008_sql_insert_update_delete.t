# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 22 * 2 + 1;

BEGIN { use_ok( 'DBIx::Array' ); }

my $connection={
                 "DBD::SQLite" => "dbi:SQLite:dbname=:memory",
                 "DBD::CSV"    => "dbi:CSV:f_dir=.",
                 "DBD::XBase"  => "dbi:XBase:.",
               };

foreach my $driver ("DBD::CSV", "DBD::XBase") { 
  #I can't get "DBD::SQLite" to pass tests on many platforms.
  my $dba=DBIx::Array->new;
  isa_ok($dba, 'DBIx::Array');
  my $table="dbixarray";
  unlink($table) if -w $table;
  eval "require $driver";
  my $no_driver=$@;
  diag("Found database driver $driver") unless $no_driver;
  my $reason="Database driver $driver not installed";

  SKIP: {
    skip $reason, 21 if $no_driver;
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
  
    #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    is($dba->sqlinsert("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 0,1,2), 1, 'insert');
    is($dba->sqlinsert("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 1,2,3), 1, 'insert');
    is($dba->sqlinsert("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 2,3,4), 1, 'insert');
    {
      my @data=$dba->sqlarray("SELECT F1 FROM $table ORDER BY F1");
      is(scalar(@data), 3, "$driver step 1");
      is($data[0], 0);
      is($data[1], 1);
      is($data[2], 2);
    }
    {
      my $count=$dba->sqldelete("DELETE FROM $table WHERE F1 = ?", 1);
      is($count, 1);
      my @data=$dba->sqlarray("SELECT F1 FROM $table ORDER BY F1");
      is(scalar(@data), 2, "$driver step 2");
      is($data[0], 0);
      is($data[1], 2);
    }
    {
      my $count=$dba->sqlupdate("UPDATE $table SET F1 = ? WHERE F1 = ?", 5, 4);
      {
        local $TODO="$driver does not return 0 as expected" if $driver eq "DBD::XBase";
        is($count, 0);
      }
      my @data=$dba->sqlarray("SELECT F1 FROM $table ORDER BY F1");
      is(scalar(@data), 2, "$driver step 3");
      is($data[0], 0);
      is($data[1], 2);
    }

    {
      my $count=$dba->sqlupdate("UPDATE $table SET F1 = ? WHERE F1 = ?", 5, 2);
      is($count, 1);
      my @data=$dba->sqlarray("SELECT F1 FROM $table ORDER BY F1");
      is(scalar(@data), 2, "$driver step 4");
      is($data[0], 0);
      is($data[1], 5);
    }
    {
      my $count=$dba->sqldelete("DELETE FROM $table");
      is($count, 2);
      my @data=$dba->sqlarray("SELECT F1 FROM $table ORDER BY F1");
      is(scalar(@data), 0, "$driver step 5");
    }
    
    $dba->dbh->do("DROP TABLE $table");
  }
}
