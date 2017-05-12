#!perl

use strict;
use warnings;

use DBI;
use DBIx::DoMore;

use Test::More tests => 4;

my $sql = <<'SQL';
CREATE TABLE child( x, y, "w;", "z;z", FOREIGN KEY (x, y) REFERENCES parent (a,b) );
CREATE TABLE parent( a, b, c, d, PRIMARY KEY(a, b) );
CREATE TRIGGER genfkey1_delete_referenced BEFORE DELETE ON "parent" WHEN
    EXISTS (SELECT 1 FROM "child" WHERE old."a" == "x" AND old."b" == "y")
BEGIN
  SELECT RAISE(ABORT, 'constraint failed');
END;
SQL

chomp( my $clean_sql = $sql );

my @statements = DBIx::DoMore->split($sql);

ok (
    @statements == 3,
    'correct number of statements - class method'
);

ok (
    join('', @statements) eq $clean_sql,
    'code successfully rebuilt - class method'
);

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '');
my $splitter = DBIx::DoMore->new(dbh => $dbh);

@statements = $splitter->split($sql);

ok (
    @statements == 3,
    'correct number of statements - instance method'
);

$sql =~ s/\s+$//; # Remove trailing spaces;

ok (
    join('', @statements) eq $clean_sql,
    'code successfully rebuilt - instance method'
);
