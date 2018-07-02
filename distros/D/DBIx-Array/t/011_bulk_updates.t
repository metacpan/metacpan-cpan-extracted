# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 60 * 1 + 1;

BEGIN { use_ok( 'DBIx::Array' ); }

my $connection={
                 "DBD::SQLite" => "dbi:SQLite:dbname=:memory",
                 "DBD::CSV"    => "dbi:CSV:f_dir=.",
                 "DBD::XBase"  => "dbi:XBase:.",
               };
local $@;
eval "require SQL::Abstract";
my $no_SQL_Abstract = $@;

diag($no_SQL_Abstract) if $no_SQL_Abstract;

SKIP: {
  skip 'SQL::Abstract not installed', 60 if $no_SQL_Abstract;

  foreach my $driver ("DBD::XBase") {
    #I can't get "DBD::SQLite" to pass tests on many platforms.
    my $dba=DBIx::Array->new;
    isa_ok($dba, 'DBIx::Array');
    my $table="dbixarray";
    unlink($table) if -w $table;
    local $@;
    eval "require $driver";
    my $no_driver=$@;
    diag("Found database driver $driver") unless $no_driver;
    my $reason="Database driver $driver not installed";

    SKIP: {
      skip $reason, 1 if $no_driver;

      die("connection not defined for $driver") unless $connection->{$driver};
      $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});

      #$dba->dbh->do("DROP TABLE $table");
      $dba->dbh->do("CREATE TABLE $table (F1 INTEGER, F2 CHAR(1), F3 VARCHAR(10))");
      is($dba->bulkabsinsertarrayarray($table, [qw{F1}], [[0],[1],[2]]), 3, 'bulkabsinsertarrayarrayname');
    }

    SKIP: {
      skip $reason, 15 if $no_driver;
      my @data=(
                ["A","Row1", 0], #updates 2 rows
                ["B","Row2", 1],
                ["C","Row3", 2],
                ["D","Row4", 3], #no update....
               );
      my $count=$dba->bulkabsupdatearrayarray($table, [qw{F2 F3}], [qw{F1}], \@data);
      is($count, 3, 'bulkabsupdatearrayarray');
      my $array=$dba->absarrayhash($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
      isa_ok($array, "ARRAY", 'absarrayhash scalar context');
      is(scalar(@$array), 3, 'sizeof absarrayhash scalar context');
      isa_ok($array->[0], "HASH", 'absarrayhash row 1');
      isa_ok($array->[1], "HASH", 'absarrayhash row 2');
      isa_ok($array->[2], "HASH", 'absarrayhash row 3');
      is($array->[0]->{'F1'}, 0, 'data');
      is($array->[0]->{'F2'}, "A", 'data');
      is($array->[0]->{'F3'}, "Row1", 'data');
      is($array->[1]->{'F1'}, 1, 'data');
      is($array->[1]->{'F2'}, "B", 'data');
      is($array->[1]->{'F3'}, "Row2", 'data');
      is($array->[2]->{'F1'}, 2, 'data');
      is($array->[2]->{'F2'}, "C", 'data');
      is($array->[2]->{'F3'}, "Row3", 'data');
    }

    SKIP: {
      skip $reason, 15 if $no_driver;
      my @data=(
                ["D","Row4", 3], #no update....
               );
      my $count=$dba->bulkabsupdatearrayarray($table, [qw{F2 F3}], [qw{F1}], \@data);
      is($count, 0, 'bulkabsupdatearrayarray');
      my $array=$dba->absarrayhash($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
      isa_ok($array, "ARRAY", 'absarrayhash scalar context');
      is(scalar(@$array), 3, 'sizeof absarrayhash scalar context');
      isa_ok($array->[0], "HASH", 'absarrayhash row 1');
      isa_ok($array->[1], "HASH", 'absarrayhash row 2');
      isa_ok($array->[2], "HASH", 'absarrayhash row 3');
      is($array->[0]->{'F1'}, 0, 'data');
      is($array->[0]->{'F2'}, "A", 'data');
      is($array->[0]->{'F3'}, "Row1", 'data');
      is($array->[1]->{'F1'}, 1, 'data');
      is($array->[1]->{'F2'}, "B", 'data');
      is($array->[1]->{'F3'}, "Row2", 'data');
      is($array->[2]->{'F1'}, 2, 'data');
      is($array->[2]->{'F2'}, "C", 'data');
      is($array->[2]->{'F3'}, "Row3", 'data');
    }

    SKIP: {
      skip $reason, 28 if $no_driver;
      is($dba->bulkabsinsertarrayarray($table, [qw{F1}], [[0],[1],[2]]), 3, 'bulkabsinsertarrayarrayname');
      my @data=(
                ["A","Row1", 0], #updates 2 rows
                ["B","Row2", 1], #updates 2 rows
                ["C","Row3", 2], #updates 2 rows
                ["D","Row4", 3], #no update....
               );
      my $count=$dba->bulkabsupdatearrayarray($table, [qw{F2 F3}], [qw{F1}], \@data);
      is($count, 6, 'bulkabsupdatearrayarray');
      my $array=$dba->absarrayhash($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
      isa_ok($array, "ARRAY", 'absarrayhash scalar context');
      is(scalar(@$array), 6, 'sizeof absarrayhash scalar context');
      isa_ok($array->[0], "HASH", 'absarrayhash row 1');
      isa_ok($array->[1], "HASH", 'absarrayhash row 2');
      isa_ok($array->[2], "HASH", 'absarrayhash row 3');
      isa_ok($array->[3], "HASH", 'absarrayhash row 1');
      isa_ok($array->[4], "HASH", 'absarrayhash row 2');
      isa_ok($array->[5], "HASH", 'absarrayhash row 3');
      is($array->[0]->{'F1'}, 0, 'data');
      is($array->[0]->{'F2'}, "A", 'data');
      is($array->[0]->{'F3'}, "Row1", 'data');
      is($array->[1]->{'F1'}, 0, 'data');
      is($array->[1]->{'F2'}, "A", 'data');
      is($array->[1]->{'F3'}, "Row1", 'data');
      is($array->[2]->{'F1'}, 1, 'data');
      is($array->[2]->{'F2'}, "B", 'data');
      is($array->[2]->{'F3'}, "Row2", 'data');
      is($array->[3]->{'F1'}, 1, 'data');
      is($array->[3]->{'F2'}, "B", 'data');
      is($array->[3]->{'F3'}, "Row2", 'data');
      is($array->[4]->{'F1'}, 2, 'data');
      is($array->[4]->{'F2'}, "C", 'data');
      is($array->[4]->{'F3'}, "Row3", 'data');
      is($array->[5]->{'F1'}, 2, 'data');
      is($array->[5]->{'F2'}, "C", 'data');
      is($array->[5]->{'F3'}, "Row3", 'data');
    }

    SKIP: {
      skip $reason, 0 if $no_driver;
      $dba->dbh->do("DROP TABLE $table");
    }
  }
}
