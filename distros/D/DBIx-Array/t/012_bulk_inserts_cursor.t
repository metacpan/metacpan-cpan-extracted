# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 31 * 2 + 1;

BEGIN { use_ok( 'DBIx::Array' ); }

my $connection={
                 "DBD::SQLite" => "dbi:SQLite:dbname=:memory",
                 "DBD::CSV"    => "dbi:CSV:f_dir=.",
                 "DBD::XBase"  => "dbi:XBase:.",
               };

foreach my $driver ("DBD::CSV", "DBD::XBase") { 
  diag("Driver: $driver");
  #I can't get "DBD::SQLite" to pass tests on many platforms.
  my $dba=DBIx::Array->new;
  isa_ok($dba, 'DBIx::Array');
  my $table1="dbixarray1";
  my $table2="dbixarray2";
  unlink($table1) if -w $table1;
  unlink($table2) if -w $table2;

  eval "require $driver";
  my $no_driver=$@;
  diag("Found database driver $driver") unless $no_driver;
  my $reason="Database driver $driver not installed";

  eval "use SQL::Abstract";
  my $no_abs=$@;
  $reason="SQL::Abstract not found." if $no_abs;

  my $skip=$no_driver || $no_abs;

  SKIP: {
    skip $reason, 1 if $skip;
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
  
    #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table1 (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    is($dba->bulkabsinsertarrayarray($table1, [qw{F1 F2 F3}], [[0,1,2], [1,2,3], [2,3,4]]), 3, 'bulkabsinsertarrayarrayname');
  }

  SKIP: {
    skip $reason, 13 if $skip;
    my $array=$dba->absarrayarray($table1, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array, "ARRAY", 'absarrayhash scalar context');
    isa_ok($array->[0], "ARRAY", 'absarrayarray row 1');
    isa_ok($array->[1], "ARRAY", 'absarrayarray row 2');
    isa_ok($array->[2], "ARRAY", 'absarrayarray row 3');
    is($array->[0]->[0], 0, 'data');
    is($array->[0]->[1], 1, 'data');
    is($array->[0]->[2], 2, 'data');
    is($array->[1]->[0], 1, 'data');
    is($array->[1]->[1], 2, 'data');
    is($array->[1]->[2], 3, 'data');
    is($array->[2]->[0], 2, 'data');
    is($array->[2]->[1], 3, 'data');
    is($array->[2]->[2], 4, 'data');
  }

  SKIP: {
    skip $reason, 1 if $skip;
    $dba->dbh->do("CREATE TABLE $table2 (A INTEGER,B CHAR(1),C VARCHAR(10))");
    my $sth1=$dba->sqlcursor(qq{SELECT F1 AS A, F2 AS B, F3 AS C FROM $table1});
    is($dba->bulkabsinsertcursor($table2, $sth1), 3, 'bulkabsinsertcursor');
  }

  SKIP: {
    skip $reason, 13 if $skip;
    my $array=$dba->absarrayarray($table2, [qw{A B C}], {}, [qw{A}]);
    isa_ok($array, "ARRAY", 'absarrayhash scalar context');
    isa_ok($array->[0], "ARRAY", 'absarrayarray row 1');
    isa_ok($array->[1], "ARRAY", 'absarrayarray row 2');
    isa_ok($array->[2], "ARRAY", 'absarrayarray row 3');
    is($array->[0]->[0], 0, 'data');
    is($array->[0]->[1], 1, 'data');
    is($array->[0]->[2], 2, 'data');
    is($array->[1]->[0], 1, 'data');
    is($array->[1]->[1], 2, 'data');
    is($array->[1]->[2], 3, 'data');
    is($array->[2]->[0], 2, 'data');
    is($array->[2]->[1], 3, 'data');
    is($array->[2]->[2], 4, 'data');
  }

  SKIP: {
    skip $reason, 2 if $skip;

    is($dba->absdelete($table1), 3, 'absdelete');
    is($dba->absdelete($table2), 3, 'absdelete');
  }

  SKIP: {
    skip $reason, 0 if $skip;
    $dba->dbh->do("DROP TABLE $table1");
    $dba->dbh->do("DROP TABLE $table2");
  }
}
