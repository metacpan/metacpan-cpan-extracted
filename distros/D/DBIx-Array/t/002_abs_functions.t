# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 147 * 2 + 1;

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
    skip $reason, 3 if $skip;
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
  
    #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    is($dba->absinsert($table, {F1=>0, F2=>1, F3=>2}), 1, 'absinsert');
    is($dba->absinsert($table, {F1=>1, F2=>2, F3=>3}), 1, 'absinsert');
    is($dba->absinsert($table, {F1=>2, F2=>3, F3=>4}), 1, 'absinsert');
  }

  SKIP: {
    skip $reason, 1 if $skip;
    isa_ok($dba->abscursor($table => "*"), 'DBI::st', 'abscursor');
  }

  SKIP: {
    skip $reason, 5 if $skip;
    my $array=$dba->absarray($table, [qw{F1 F2 F3}], {F1=>0});
    isa_ok($array, "ARRAY", '$dba->absarray scalar context');
    is(scalar(@$array), 3, 'scalar(@$array)');
    is($array->[0], 0, '$dba->absarray->[0]');
    is($array->[1], 1, '$dba->absarray->[1]');
    is($array->[2], 2, '$dba->absarray->[2]');
  }

  SKIP: {
    skip $reason, 4 if $skip;
    my @array=$dba->absarray($table, [qw{F1 F2 F3}], {F1=>0});
    is(scalar(@array), 3, 'scalar(@$array)');
    is($array[0], 0, '$dba->absarray[0]');
    is($array[1], 1, '$dba->absarray[1]');
    is($array[2], 2, '$dba->absarray[2]');
  }

  SKIP: {
    skip $reason, 4 if $skip;
    my $hash=$dba->abshash($table, [qw{F1 F2}]);
    isa_ok($hash, "HASH", 'absarray scalar context');
    is($hash->{'0'}, 1, 'abshash');
    is($hash->{'1'}, 2, 'abshash');
    is($hash->{'2'}, 3, 'abshash');
  }

  SKIP: {
    skip $reason, 10 if $skip;
    my $hash=$dba->abshashhash($table, [qw{F1 F2}]);
    isa_ok($hash, "HASH", 'sqlhashhash scalar context');
    isa_ok($hash->{'0'}, "HASH", 'sqlhashhash');
    isa_ok($hash->{'1'}, "HASH", 'sqlhashhash');
    isa_ok($hash->{'2'}, "HASH", 'sqlhashhash');
    is($hash->{'0'}->{"F1"}, 0, 'sqlhashhash');
    is($hash->{'1'}->{"F1"}, 1, 'sqlhashhash');
    is($hash->{'2'}->{"F1"}, 2, 'sqlhashhash');
    is($hash->{'0'}->{"F2"}, 1, 'sqlhashhash');
    is($hash->{'1'}->{"F2"}, 2, 'sqlhashhash');
    is($hash->{'2'}->{"F2"}, 3, 'sqlhashhash');
  }

  SKIP: {
    skip $reason, 3 if $skip;
    my %hash=$dba->abshash($table, [qw{F1 F2}]);
    is($hash{'0'}, 1, 'abshash');
    is($hash{'1'}, 2, 'abshash');
    is($hash{'2'}, 3, 'abshash');
  }

  SKIP: {
    skip $reason, 13 if $skip;
    my $array=$dba->absarrayarray($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array, "ARRAY", 'absarrayarray scalar context');
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
    skip $reason, 12 if $skip;
    my @array=$dba->absarrayarray($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array[0], "ARRAY", 'absarrayarray row 1');
    isa_ok($array[1], "ARRAY", 'absarrayarray row 2');
    isa_ok($array[2], "ARRAY", 'absarrayarray row 3');
    is($array[0]->[0], 0, 'data');
    is($array[0]->[1], 1, 'data');
    is($array[0]->[2], 2, 'data');
    is($array[1]->[0], 1, 'data');
    is($array[1]->[1], 2, 'data');
    is($array[1]->[2], 3, 'data');
    is($array[2]->[0], 2, 'data');
    is($array[2]->[1], 3, 'data');
    is($array[2]->[2], 4, 'data');
  }
    
  SKIP: {
    skip $reason, 17 if $skip;
    my $array=$dba->absarrayarrayname($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array, "ARRAY", 'absarrayarrayname scalar context');
    isa_ok($array->[0], "ARRAY", 'absarrayarrayname header');
    isa_ok($array->[1], "ARRAY", 'absarrayarrayname row 1');
    isa_ok($array->[2], "ARRAY", 'absarrayarrayname row 2');
    isa_ok($array->[3], "ARRAY", 'absarrayarrayname row 3');
    is($array->[0]->[0], 'F1', 'data');
    is($array->[0]->[1], 'F2', 'data');
    is($array->[0]->[2], 'F3', 'data');
    is($array->[1]->[0], 0, 'data');
    is($array->[1]->[1], 1, 'data');
    is($array->[1]->[2], 2, 'data');
    is($array->[2]->[0], 1, 'data');
    is($array->[2]->[1], 2, 'data');
    is($array->[2]->[2], 3, 'data');
    is($array->[3]->[0], 2, 'data');
    is($array->[3]->[1], 3, 'data');
    is($array->[3]->[2], 4, 'data');
  }
    
  SKIP: {
    skip $reason, 16 if $skip;
    my @array=$dba->absarrayarrayname($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array[0], "ARRAY", 'absarrayarrayname header');
    isa_ok($array[1], "ARRAY", 'absarrayarrayname row 1');
    isa_ok($array[2], "ARRAY", 'absarrayarrayname row 2');
    isa_ok($array[3], "ARRAY", 'absarrayarrayname row 3');
    is($array[0]->[0], 'F1', 'data');
    is($array[0]->[1], 'F2', 'data');
    is($array[0]->[2], 'F3', 'data');
    is($array[1]->[0], 0, 'data');
    is($array[1]->[1], 1, 'data');
    is($array[1]->[2], 2, 'data');
    is($array[2]->[0], 1, 'data');
    is($array[2]->[1], 2, 'data');
    is($array[2]->[2], 3, 'data');
    is($array[3]->[0], 2, 'data');
    is($array[3]->[1], 3, 'data');
    is($array[3]->[2], 4, 'data');
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
    skip $reason, 12 if $skip;
    my @array=$dba->absarrayhash($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array[0], "HASH", 'absarrayhash row 1');
    isa_ok($array[1], "HASH", 'absarrayhash row 2');
    isa_ok($array[2], "HASH", 'absarrayhash row 3');
    is($array[0]->{'F1'}, 0, 'data');
    is($array[0]->{'F2'}, 1, 'data');
    is($array[0]->{'F3'}, 2, 'data');
    is($array[1]->{'F1'}, 1, 'data');
    is($array[1]->{'F2'}, 2, 'data');
    is($array[1]->{'F3'}, 3, 'data');
    is($array[2]->{'F1'}, 2, 'data');
    is($array[2]->{'F2'}, 3, 'data');
    is($array[2]->{'F3'}, 4, 'data');
  }
    
  SKIP: {
    skip $reason, 17 if $skip;
    my $array=$dba->absarrayhashname($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array, "ARRAY", 'absarrayhashname scalar context');
    isa_ok($array->[0], "ARRAY", 'absarrayhashname header');
    isa_ok($array->[1], "HASH", 'absarrayhashname row 1');
    isa_ok($array->[2], "HASH", 'absarrayhashname row 2');
    isa_ok($array->[3], "HASH", 'absarrayhashname row 3');
    is($array->[0]->[0], 'F1', 'data');
    is($array->[0]->[1], 'F2', 'data');
    is($array->[0]->[2], 'F3', 'data');
    is($array->[1]->{'F1'}, 0, 'data');
    is($array->[1]->{'F2'}, 1, 'data');
    is($array->[1]->{'F3'}, 2, 'data');
    is($array->[2]->{'F1'}, 1, 'data');
    is($array->[2]->{'F2'}, 2, 'data');
    is($array->[2]->{'F3'}, 3, 'data');
    is($array->[3]->{'F1'}, 2, 'data');
    is($array->[3]->{'F2'}, 3, 'data');
    is($array->[3]->{'F3'}, 4, 'data');
  }
    
  SKIP: {
    skip $reason, 16 if $skip;
    my @array=$dba->absarrayhashname($table, [qw{F1 F2 F3}], {}, [qw{F1}]);
    isa_ok($array[0], "ARRAY", 'absarrayhashname header');
    isa_ok($array[1], "HASH", 'absarrayhashname row 1');
    isa_ok($array[2], "HASH", 'absarrayhashname row 2');
    isa_ok($array[3], "HASH", 'absarrayhashname row 3');
    is($array[0]->[0], 'F1', 'data');
    is($array[0]->[1], 'F2', 'data');
    is($array[0]->[2], 'F3', 'data');
    is($array[1]->{'F1'}, 0, 'data');
    is($array[1]->{'F2'}, 1, 'data');
    is($array[1]->{'F3'}, 2, 'data');
    is($array[2]->{'F1'}, 1, 'data');
    is($array[2]->{'F2'}, 2, 'data');
    is($array[2]->{'F3'}, 3, 'data');
    is($array[3]->{'F1'}, 2, 'data');
    is($array[3]->{'F2'}, 3, 'data');
    is($array[3]->{'F3'}, 4, 'data');
  }
    
  SKIP: {
    skip $reason, 0 if $skip;
    $dba->dbh->do("DROP TABLE $table");
  }
}
