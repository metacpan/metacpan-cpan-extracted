# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 30 * 2 + 1;

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

  eval "use SQL::Abstract";
  my $no_abs=$@;
  $reason="SQL::Abstract not found." if $no_abs;

  my $skip=$no_driver || $no_abs;

  SKIP: {
    skip $reason, 1 if $skip;
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
  
    #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    is($dba->bulkabsinsertarrayarray($table, [qw{F1 F2 F3}], [[0,1,2], [1,2,3], [2,3,4]]), 3, 'bulkabsinsertarrayarray');
  }

  SKIP: {
    skip $reason, 13 if $skip;
    my $array=$dba->absarrayhash($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array, "ARRAY", 'absarrayhash scalar context');
    isa_ok($array->[0], "HASH", 'absarrayhash row 1');
    isa_ok($array->[1], "HASH", 'absarrayhash row 2');
    isa_ok($array->[2], "HASH", 'absarrayhash row 3');
    is($array->[0]->{'F1'}, 0, 'data');
    is($array->[0]->{'F2'}, 1, 'data');
    is($array->[0]->{'F3'}, 2, 'data');
    is($array->[1]->{'F1'}, 1, 'data');
    is($array->[1]->{'F2'}, 2, 'data');
    is($array->[1]->{'F3'}, 3, 'data');
    is($array->[2]->{'F1'}, 2, 'data');
    is($array->[2]->{'F2'}, 3, 'data');
    is($array->[2]->{'F3'}, 4, 'data');
  }

  SKIP: {
    skip $reason, 1 if $skip;

    is($dba->absdelete($table), 3, 'absdelete');
  }

  SKIP: {
    skip $reason, 1 if $skip;

    is($dba->bulkabsinsertarrayhash($table, [qw{F1 F2 F3}], [{F1=>0,F2=>1,F3=>2}, {F1=>1,F2=>2,F3=>3}, {F1=>2,F2=>3,F3=>4}]), 3, 'bulkabsinsertarrayarray');
  }

  SKIP: {
    skip $reason, 13 if $skip;
    my $array=$dba->absarrayhash($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array, "ARRAY", 'absarrayhash scalar context');
    isa_ok($array->[0], "HASH", 'absarrayhash row 1');
    isa_ok($array->[1], "HASH", 'absarrayhash row 2');
    isa_ok($array->[2], "HASH", 'absarrayhash row 3');
    is($array->[0]->{'F1'}, 0, 'data');
    is($array->[0]->{'F2'}, 1, 'data');
    is($array->[0]->{'F3'}, 2, 'data');
    is($array->[1]->{'F1'}, 1, 'data');
    is($array->[1]->{'F2'}, 2, 'data');
    is($array->[1]->{'F3'}, 3, 'data');
    is($array->[2]->{'F1'}, 2, 'data');
    is($array->[2]->{'F2'}, 3, 'data');
    is($array->[2]->{'F3'}, 4, 'data');
  }

  SKIP: {
    skip $reason, 0 if $skip;
    $dba->dbh->do("DROP TABLE $table");
  }
}
