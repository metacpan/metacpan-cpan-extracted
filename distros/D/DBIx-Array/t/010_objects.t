# -*- perl -*-
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 98 * 2;
use DBIx::Array;

{
  package #hide from CPAN indexer
    My::Package;
  sub id {shift->{"ID"}};
  sub type {shift->{"TYPE"}};
  sub name {shift->{"NAME"}};
}

my $connection={
                 "DBD::SQLite" => "dbi:SQLite:dbname=:memory",
                 "DBD::CSV"    => "dbi:CSV:f_dir=.",
                 "DBD::XBase"  => "dbi:XBase:.",
               };

foreach my $driver ("DBD::CSV", "DBD::XBase") {
  diag("Driver: $driver");
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

  SKIP: {
    skip $reason, 3 if $no_driver;

    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});

    #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (ID INTEGER,TYPE CHAR(1),NAME VARCHAR(10))");

    is($dba->sqlinsert("INSERT INTO $table (ID,TYPE,NAME) VALUES (?,?,?)", qw{0 a foo}), 1, 'sqlinsert');
    is($dba->sqlinsert("INSERT INTO $table (ID,TYPE,NAME) VALUES (?,?,?)", qw{1 b bar}), 1, 'sqlinsert');
    is($dba->sqlinsert("INSERT INTO $table (ID,TYPE,NAME) VALUES (?,?,?)", qw{2 c baz}), 1, 'sqlinsert');
  }

  SKIP: {
    $reason="SQL::Abstract not found." if $no_abs;
    skip $reason, 43 if $no_driver || $no_abs;
    {
      my $array=$dba->absarrayobject("My::Package", $table, [qw{ID TYPE NAME}], {}, [qw{ID}]);
      isa_ok($array, "ARRAY", 'absarrayhashname scalar context');
      isa_ok($array->[0], "My::Package", 'absarrayobject row 0');
      isa_ok($array->[1], "My::Package", 'absarrayobject row 1');
      isa_ok($array->[2], "My::Package", 'absarrayobject row 2');
      diag(Dumper $array);
      is($array->[0]->{'ID'}, 0, 'data');
      is($array->[0]->{'TYPE'}, "a", 'data');
      is($array->[0]->{'NAME'}, "foo", 'data');
      is($array->[1]->{'ID'}, 1, 'data');
      is($array->[1]->{'TYPE'}, "b", 'data');
      is($array->[1]->{'NAME'}, "bar", 'data');
      is($array->[2]->{'ID'}, 2, 'data');
      is($array->[2]->{'TYPE'}, "c", 'data');
      is($array->[2]->{'NAME'}, "baz", 'data');
      is($array->[0]->id, 0, 'data');
      is($array->[0]->type, "a", 'data');
      is($array->[0]->name, "foo", 'data');
      is($array->[1]->id, 1, 'data');
      is($array->[1]->type, "b", 'data');
      is($array->[1]->name, "bar", 'data');
      is($array->[2]->id, 2, 'data');
      is($array->[2]->type, "c", 'data');
      is($array->[2]->name, "baz", 'data');
    }
    {
      my @array=$dba->absarrayobject("My::Package", $table, [qw{ID TYPE NAME}], {}, [qw{ID}]);
      isa_ok($array[0], "My::Package", 'absarrayobject row 0');
      isa_ok($array[1], "My::Package", 'absarrayobject row 1');
      isa_ok($array[2], "My::Package", 'absarrayobject row 2');
      diag(Dumper \@array);
      is($array[0]->{'ID'}, 0, 'data');
      is($array[0]->{'TYPE'}, "a", 'data');
      is($array[0]->{'NAME'}, "foo", 'data');
      is($array[1]->{'ID'}, 1, 'data');
      is($array[1]->{'TYPE'}, "b", 'data');
      is($array[1]->{'NAME'}, "bar", 'data');
      is($array[2]->{'ID'}, 2, 'data');
      is($array[2]->{'TYPE'}, "c", 'data');
      is($array[2]->{'NAME'}, "baz", 'data');
      is($array[0]->id, 0, 'data');
      is($array[0]->type, "a", 'data');
      is($array[0]->name, "foo", 'data');
      is($array[1]->id, 1, 'data');
      is($array[1]->type, "b", 'data');
      is($array[1]->name, "bar", 'data');
      is($array[2]->id, 2, 'data');
      is($array[2]->type, "c", 'data');
      is($array[2]->name, "baz", 'data');
    }
  }

  SKIP: {
    skip $reason, 44 if $no_driver;
    {
      local $@;
      my $array = eval{$dba->sqlarrayobject("", qq{SELECT ID, TYPE, NAME from $table ORDER BY ID})};
      my $error = $@;
      like($error, qr/requires a class parameter/, 'no class');
    }
    {
      my $array = $dba->sqlarrayobject("My::Package", qq{SELECT ID, TYPE, NAME from $table ORDER BY ID});
      isa_ok($array, "ARRAY", 'sqlarrayhashname scalar context');
      isa_ok($array->[0], "My::Package", 'sqlarrayobject row 0');
      isa_ok($array->[1], "My::Package", 'sqlarrayobject row 1');
      isa_ok($array->[2], "My::Package", 'sqlarrayobject row 2');
      diag(Dumper $array);
      is($array->[0]->{'ID'}, 0, 'data');
      is($array->[0]->{'TYPE'}, "a", 'data');
      is($array->[0]->{'NAME'}, "foo", 'data');
      is($array->[1]->{'ID'}, 1, 'data');
      is($array->[1]->{'TYPE'}, "b", 'data');
      is($array->[1]->{'NAME'}, "bar", 'data');
      is($array->[2]->{'ID'}, 2, 'data');
      is($array->[2]->{'TYPE'}, "c", 'data');
      is($array->[2]->{'NAME'}, "baz", 'data');
      is($array->[0]->id, 0, 'data');
      is($array->[0]->type, "a", 'data');
      is($array->[0]->name, "foo", 'data');
      is($array->[1]->id, 1, 'data');
      is($array->[1]->type, "b", 'data');
      is($array->[1]->name, "bar", 'data');
      is($array->[2]->id, 2, 'data');
      is($array->[2]->type, "c", 'data');
      is($array->[2]->name, "baz", 'data');
    }
    {
      my @array = $dba->sqlarrayobject("My::Package", qq{SELECT ID, TYPE, NAME from $table ORDER BY ID});
      isa_ok($array[0], "My::Package", 'sqlarrayobject row 0');
      isa_ok($array[1], "My::Package", 'sqlarrayobject row 1');
      isa_ok($array[2], "My::Package", 'sqlarrayobject row 2');
      diag(Dumper \@array);
      is($array[0]->{'ID'}, 0, 'data');
      is($array[0]->{'TYPE'}, "a", 'data');
      is($array[0]->{'NAME'}, "foo", 'data');
      is($array[1]->{'ID'}, 1, 'data');
      is($array[1]->{'TYPE'}, "b", 'data');
      is($array[1]->{'NAME'}, "bar", 'data');
      is($array[2]->{'ID'}, 2, 'data');
      is($array[2]->{'TYPE'}, "c", 'data');
      is($array[2]->{'NAME'}, "baz", 'data');
      is($array[0]->id, 0, 'data');
      is($array[0]->type, "a", 'data');
      is($array[0]->name, "foo", 'data');
      is($array[1]->id, 1, 'data');
      is($array[1]->type, "b", 'data');
      is($array[1]->name, "bar", 'data');
      is($array[2]->id, 2, 'data');
      is($array[2]->type, "c", 'data');
      is($array[2]->name, "baz", 'data');
    }
  }

  SKIP: {
    $reason="SQL::Abstract not found." if $no_abs;
    skip $reason, 7 if $no_driver || $no_abs;
    my ($object)=$dba->absarrayobject("My::Package", $table, [qw{ID TYPE NAME}], {ID=>0});
    isa_ok($object, "My::Package", 'absarrayobject');
    diag(Dumper $object);
    is($object->{'ID'}, 0, 'data');
    is($object->{'TYPE'}, "a", 'data');
    is($object->{'NAME'}, "foo", 'data');
    is($object->id, 0, 'data');
    is($object->type, "a", 'data');
    is($object->name, "foo", 'data');
  }

  SKIP: {
    skip $reason, 0 if $no_driver;
    $dba->dbh->do("DROP TABLE $table");
  }
}
