# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 6;
use Path::Class qw{file};

BEGIN { use_ok( 'DBIx::Array::Connect' ); }


my $ini=file(file($0)->dir => "db-config.ini");
my $dac=DBIx::Array::Connect->new(file=>$ini);
isa_ok($dac, 'DBIx::Array::Connect');

SKIP: {
  my $driver="DBD::CSV";
  eval "require $driver";
  skip "Database driver $driver not installed", 4 if $@;

  my $dbx=$dac->connect("db1");
  isnt(ref($dbx), "DBIx::Array::Export");
  #isa_ok($dbx, "DBIx::Array::Export");
  isa_ok($dbx, "DBIx::Array");

  my $table="dbixarrayconnect.csv";
  unlink($table) if -e $table;
  $dbx->execute("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
  is($dbx->update("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 4,"A","Array"), 1, 'insert');
  is($dbx->sqlscalar("SELECT F3 FROM $table WHERE F2 = ?", "A"), "Array");
  $dbx->execute("DROP TABLE $table");
}
