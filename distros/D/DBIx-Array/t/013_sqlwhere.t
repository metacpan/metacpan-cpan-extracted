# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 160 + 2;

BEGIN { use_ok( 'DBIx::Array' ); }
my $dba   = DBIx::Array->new;
isa_ok($dba, 'DBIx::Array');

local $@;
eval "require DBD::SQLite";
my $error_dbd    = $@;

local $@;
eval "require SQL::Abstract"; #RT127167
my $error_abs    = $@;

my $table    = "test_table";
my $database = 'test_database';

SKIP: {
  skip "Database driver DBD::SQLite not available", 160 if $error_dbd;
  skip "Package SQL::Abstract not available",      160 if $error_abs;
  $dba->connect("dbi:SQLite:dbname=$database", "", "", {RaiseError=>1, AutoCommit=>1});
  
  $dba->sqlexecute("DROP TABLE IF EXISTS $table");
  $dba->sqlexecute("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
  is($dba->sqlinsert("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 0,1,2), 1, 'sqlinsert');
  is($dba->sqlinsert("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 1,2,3), 1, 'sqlinsert');
  is($dba->sqlinsert("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 2,3,4), 1, 'sqlinsert');

  {
    my ($sql, @bind) = $dba->sqlwhere("SELECT * FROM $table");
    is($sql, "SELECT * FROM $table", 'sqlwhere');
  }

  {
    my ($sql, @bind) = $dba->sqlwhere("SELECT * FROM $table", {}, []);
    is($sql, "SELECT * FROM $table", 'sqlwhere');
  }

  {
    my ($sql, @bind) = $dba->sqlwhere("SELECT * FROM $table", {F1=>0}, []);
    is($sql, "SELECT * FROM $table $/  WHERE ( F1 = ? )", 'sqlwhere');
  }

  {
    my ($sql, @bind) = $dba->sqlwhere("SELECT * FROM $table", {F1=>0}, ['F2']);
    is($sql, "SELECT * FROM $table $/  WHERE ( F1 = ? ) ORDER BY F2", 'sqlwhere');
  }

  {
    my ($sql, @bind) = $dba->sqlwhere("SELECT * FROM $table", {F1=>0, F2=>1}, ['F2', 'F1']);
    is($sql, "SELECT * FROM $table $/  WHERE ( ( F1 = ? AND F2 = ? ) ) ORDER BY F2, F1", 'sqlwhere');
  }

  {
    my $cursor = $dba->sqlwherecursor("SELECT * FROM $table", {}, []);
    isa_ok($cursor, 'DBI::st', 'sqlwherecursor');
    my $array  = $cursor->fetchall_arrayref;
    isa_ok($array, "ARRAY", '$cursor->fetchall_arrayref');
    is(scalar(@$array), 3, 'sizeof sqlwherecursor');
  }

  {
    my $array = $dba->sqlwherearray("SELECT F1,F2,F3 FROM $table", {F1=>0}, ['F1']);
    isa_ok($array, "ARRAY", '$dba->sqlarray scalar context');
    is(scalar(@$array), 3, 'scalar(@$array)');
    is($array->[0], 0, '$dba->sqlarray->[0]');
    is($array->[1], 1, '$dba->sqlarray->[1]');
    is($array->[2], 2, '$dba->sqlarray->[2]');
  }

  {
    my @array = $dba->sqlwherearray("SELECT F1,F2,F3 FROM $table", {F1=>0}, ['F1']);
    is(scalar(@array), 3, 'scalar(@$array)');
    is($array[0], 0, '$dba->sqlarray[0]');
    is($array[1], 1, '$dba->sqlarray[1]');
    is($array[2], 2, '$dba->sqlarray[2]');
  }

  {
    my $hash = $dba->sqlwherehash("SELECT F1,F2 FROM $table");
    isa_ok($hash, "HASH", 'sqlwheresh scalar context');
    is(scalar(keys %$hash), 3, 'sizeof sqlwherehash');
    is($hash->{'0'}, 1, 'sqlwherehash');
    is($hash->{'1'}, 2, 'sqlwherehash');
    is($hash->{'2'}, 3, 'sqlwherehash');
  }

  {
    my $hash = $dba->sqlwherehashhash("SELECT F1,F2 FROM $table");
    isa_ok($hash, "HASH", 'sqlwherearray scalar context');
    is(scalar(keys %$hash), 3, 'sizeof sqlwherehashhash');
    isa_ok($hash->{'0'}, "HASH", 'sqlwherehashhash');
    isa_ok($hash->{'1'}, "HASH", 'sqlwherehashhash');
    isa_ok($hash->{'2'}, "HASH", 'sqlwherehashhash');
    is($hash->{'0'}->{"F1"}, 0, 'sqlwherehashhash');
    is($hash->{'1'}->{"F1"}, 1, 'sqlwherehashhash');
    is($hash->{'2'}->{"F1"}, 2, 'sqlwherehashhash');
    is($hash->{'0'}->{"F2"}, 1, 'sqlwherehashhash');
    is($hash->{'1'}->{"F2"}, 2, 'sqlwherehashhash');
    is($hash->{'2'}->{"F2"}, 3, 'sqlwherehashhash');
  }

  {
    my $array = $dba->sqlwherearrayarray("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    isa_ok($array, "ARRAY", 'sqlwherearrayarray scalar context');
    is(scalar(@$array), 3, 'sizeof sqlwherearrayarray');
    isa_ok($array->[0], "ARRAY", 'sqlwherearrayarray row 1');
    isa_ok($array->[1], "ARRAY", 'sqlwherearrayarray row 2');
    isa_ok($array->[2], "ARRAY", 'sqlwherearrayarray row 3');
    is($array->[0]->[0], 0, 'sqlwherearrayarray data');
    is($array->[0]->[1], 1, 'sqlwherearrayarray data');
    is($array->[0]->[2], 2, 'sqlwherearrayarray data');
    is($array->[1]->[0], 1, 'sqlwherearrayarray data');
    is($array->[1]->[1], 2, 'sqlwherearrayarray data');
    is($array->[1]->[2], 3, 'sqlwherearrayarray data');
    is($array->[2]->[0], 2, 'sqlwherearrayarray data');
    is($array->[2]->[1], 3, 'sqlwherearrayarray data');
    is($array->[2]->[2], 4, 'sqlwherearrayarray data');
  }

  {
    my @array = $dba->sqlwherearrayarray("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    is(scalar(@array), 3, 'sizeof sqlwherearrayarray');
    isa_ok($array[0], "ARRAY", 'sqlwherearrayarray row 1');
    isa_ok($array[1], "ARRAY", 'sqlwherearrayarray row 2');
    isa_ok($array[2], "ARRAY", 'sqlwherearrayarray row 3');
    is($array[0]->[0], 0, 'sqlwherearrayarray data');
    is($array[0]->[1], 1, 'sqlwherearrayarray data');
    is($array[0]->[2], 2, 'sqlwherearrayarray data');
    is($array[1]->[0], 1, 'sqlwherearrayarray data');
    is($array[1]->[1], 2, 'sqlwherearrayarray data');
    is($array[1]->[2], 3, 'sqlwherearrayarray data');
    is($array[2]->[0], 2, 'sqlwherearrayarray data');
    is($array[2]->[1], 3, 'sqlwherearrayarray data');
    is($array[2]->[2], 4, 'sqlwherearrayarray data');
  }

  {
    my $array = $dba->sqlwherearrayarrayname("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    isa_ok($array, "ARRAY", 'sqlwherearrayarrayname scalar context');
    is(scalar(@$array), 4, 'sizeof sqlwherearrayarrayname');
    isa_ok($array->[0], "ARRAY", 'sqlwherearrayarrayname header');
    isa_ok($array->[1], "ARRAY", 'sqlwherearrayarrayname row 1');
    isa_ok($array->[2], "ARRAY", 'sqlwherearrayarrayname row 2');
    isa_ok($array->[3], "ARRAY", 'sqlwherearrayarrayname row 3');
    is($array->[0]->[0], 'F1', 'sqlwherearrayarrayname data');
    is($array->[0]->[1], 'F2', 'sqlwherearrayarrayname data');
    is($array->[0]->[2], 'F3', 'sqlwherearrayarrayname data');
    is($array->[1]->[0], 0, 'sqlwherearrayarrayname data');
    is($array->[1]->[1], 1, 'sqlwherearrayarrayname data');
    is($array->[1]->[2], 2, 'sqlwherearrayarrayname data');
    is($array->[2]->[0], 1, 'sqlwherearrayarrayname data');
    is($array->[2]->[1], 2, 'sqlwherearrayarrayname data');
    is($array->[2]->[2], 3, 'sqlwherearrayarrayname data');
    is($array->[3]->[0], 2, 'sqlwherearrayarrayname data');
    is($array->[3]->[1], 3, 'sqlwherearrayarrayname data');
    is($array->[3]->[2], 4, 'sqlwherearrayarrayname data');
  }

  {
    my @array=$dba->sqlwherearrayarrayname("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    is(scalar(@array), 4, 'sizeof sqlwherearrayarrayname');
    isa_ok($array[0], "ARRAY", 'sqlarrayarrayname header');
    isa_ok($array[1], "ARRAY", 'sqlarrayarrayname row 1');
    isa_ok($array[2], "ARRAY", 'sqlarrayarrayname row 2');
    isa_ok($array[3], "ARRAY", 'sqlarrayarrayname row 3');
    is($array[0]->[0], 'F1', 'sqlwherearrayarrayname data');
    is($array[0]->[1], 'F2', 'sqlwherearrayarrayname data');
    is($array[0]->[2], 'F3', 'sqlwherearrayarrayname data');
    is($array[1]->[0], 0, 'sqlwherearrayarrayname data');
    is($array[1]->[1], 1, 'sqlwherearrayarrayname data');
    is($array[1]->[2], 2, 'sqlwherearrayarrayname data');
    is($array[2]->[0], 1, 'sqlwherearrayarrayname data');
    is($array[2]->[1], 2, 'sqlwherearrayarrayname data');
    is($array[2]->[2], 3, 'sqlwherearrayarrayname data');
    is($array[3]->[0], 2, 'sqlwherearrayarrayname data');
    is($array[3]->[1], 3, 'sqlwherearrayarrayname data');
    is($array[3]->[2], 4, 'sqlwherearrayarrayname data');
  }
    
  {
    my $array = $dba->sqlwherearrayhash("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    is(scalar(@$array), 3, 'sizeof sqlwherearrayhash');
    isa_ok($array, "ARRAY", 'sqlarrayhashname scalar context');
    isa_ok($array->[0], "HASH", 'sqlarrayhash row 1');
    isa_ok($array->[1], "HASH", 'sqlarrayhash row 2');
    isa_ok($array->[2], "HASH", 'sqlarrayhash row 3');
    is($array->[0]->{'F1'}, 0, 'sqlwherearrayhash data');
    is($array->[0]->{'F2'}, 1, 'sqlwherearrayhash data');
    is($array->[0]->{'F3'}, 2, 'sqlwherearrayhash data');
    is($array->[1]->{'F1'}, 1, 'sqlwherearrayhash data');
    is($array->[1]->{'F2'}, 2, 'sqlwherearrayhash data');
    is($array->[1]->{'F3'}, 3, 'sqlwherearrayhash data');
    is($array->[2]->{'F1'}, 2, 'sqlwherearrayhash data');
    is($array->[2]->{'F2'}, 3, 'sqlwherearrayhash data');
    is($array->[2]->{'F3'}, 4, 'sqlwherearrayhash data');
  }

  {
    my @array=$dba->sqlwherearrayhash("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    is(scalar(@array), 3, 'sizeof sqlwherearrayhash');
    isa_ok($array[0], "HASH", 'sqlarrayhash row 1');
    isa_ok($array[1], "HASH", 'sqlarrayhash row 2');
    isa_ok($array[2], "HASH", 'sqlarrayhash row 3');
    is($array[0]->{'F1'}, 0, 'sqlwherearrayhash data');
    is($array[0]->{'F2'}, 1, 'sqlwherearrayhash data');
    is($array[0]->{'F3'}, 2, 'sqlwherearrayhash data');
    is($array[1]->{'F1'}, 1, 'sqlwherearrayhash data');
    is($array[1]->{'F2'}, 2, 'sqlwherearrayhash data');
    is($array[1]->{'F3'}, 3, 'sqlwherearrayhash data');
    is($array[2]->{'F1'}, 2, 'sqlwherearrayhash data');
    is($array[2]->{'F2'}, 3, 'sqlwherearrayhash data');
    is($array[2]->{'F3'}, 4, 'sqlwherearrayhash data');
  }

  {
    my $array=$dba->sqlwherearrayhashname("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    isa_ok($array, "ARRAY", 'sqlarrayhashname scalar context');
    is(scalar(@$array), 4, 'sizeof sqlwherearrayhashname');
    isa_ok($array->[0], "ARRAY", 'sqlarrayhashname header');
    isa_ok($array->[1], "HASH", 'sqlarrayhashname row 1');
    isa_ok($array->[2], "HASH", 'sqlarrayhashname row 2');
    isa_ok($array->[3], "HASH", 'sqlarrayhashname row 3');
    is($array->[0]->[0], 'F1', 'sqlwherearrayhashname data');
    is($array->[0]->[1], 'F2', 'sqlwherearrayhashname data');
    is($array->[0]->[2], 'F3', 'sqlwherearrayhashname data');
    is($array->[1]->{'F1'}, 0, 'sqlwherearrayhashname data');
    is($array->[1]->{'F2'}, 1, 'sqlwherearrayhashname data');
    is($array->[1]->{'F3'}, 2, 'sqlwherearrayhashname data');
    is($array->[2]->{'F1'}, 1, 'sqlwherearrayhashname data');
    is($array->[2]->{'F2'}, 2, 'sqlwherearrayhashname data');
    is($array->[2]->{'F3'}, 3, 'sqlwherearrayhashname data');
    is($array->[3]->{'F1'}, 2, 'sqlwherearrayhashname data');
    is($array->[3]->{'F2'}, 3, 'sqlwherearrayhashname data');
    is($array->[3]->{'F3'}, 4, 'sqlwherearrayhashname data');
  }
    
  {
    my @array=$dba->sqlwherearrayhashname("SELECT F1,F2,F3 FROM $table", {}, ['F1']);
    is(scalar(@array), 4, 'sizeof sqlwherearrayhashname');
    isa_ok($array[0], "ARRAY", 'sqlarrayhashname header');
    isa_ok($array[1], "HASH", 'sqlarrayhashname row 1');
    isa_ok($array[2], "HASH", 'sqlarrayhashname row 2');
    isa_ok($array[3], "HASH", 'sqlarrayhashname row 3');
    is($array[0]->[0], 'F1', 'sqlwherearrayhashname data');
    is($array[0]->[1], 'F2', 'sqlwherearrayhashname data');
    is($array[0]->[2], 'F3', 'sqlwherearrayhashname data');
    is($array[1]->{'F1'}, 0, 'sqlwherearrayhashname data');
    is($array[1]->{'F2'}, 1, 'sqlwherearrayhashname data');
    is($array[1]->{'F3'}, 2, 'sqlwherearrayhashname data');
    is($array[2]->{'F1'}, 1, 'sqlwherearrayhashname data');
    is($array[2]->{'F2'}, 2, 'sqlwherearrayhashname data');
    is($array[2]->{'F3'}, 3, 'sqlwherearrayhashname data');
    is($array[3]->{'F1'}, 2, 'sqlwherearrayhashname data');
    is($array[3]->{'F2'}, 3, 'sqlwherearrayhashname data');
    is($array[3]->{'F3'}, 4, 'sqlwherearrayhashname data');
  }
    
  $dba->sqlexecute("DROP TABLE $table");
  unlink($database) if -f $database;
}
