# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 6 * 2 + 1;

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
    skip $reason, 3 if $no_driver;
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
  
    #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    my $sql="INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)";
    is($dba->insert($sql, 0,1,2), 1, 'insert');
    is($dba->insert($sql, 1,2,3), 1, 'insert');
    is($dba->insert($sql, 2,3,4), 1, 'insert');
  }

  SKIP: {
    skip $reason, 2 if $no_driver;

    my $dbh=$dba->dbh;
    {
      my $dba2=DBIx::Array->new(dbh=>$dbh);
      is($dba2->sqlscalar("SELECT F2 FROM $table WHERE F1=0"), "1", "still have a connection");
    }
    is($dba->sqlscalar("SELECT F2 FROM $table WHERE F1=0"), "1", "still have a connection");
  }

  SKIP: {
    skip $reason, 0 if $no_driver;
    $dba->dbh->do("DROP TABLE $table");
  }
}
