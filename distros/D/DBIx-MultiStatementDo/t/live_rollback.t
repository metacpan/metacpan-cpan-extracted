#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;

use Test::More tests => 11;

my $create = <<'SQL';
CREATE TABLE parent( a, b, c, d, PRIMARY KEY(a, b) );
CREATE TABLE child( x, y, "w;", "z;z", FOREIGN KEY (x, y) REFERENCES parent (a,b) );
CREATE TRIGGER "foreign;key" BEFORE DELETE ON "parent" WHEN
    EXISTS (SELECT 1 FROM "child" WHERE old."a" == "x" AND old."b" == "y")
BEGIN
    SELECT RAISE(ABORT, 'constraint failed;');
END;
SQL

my $drop = <<'SQL';
DROP TRIGGER "foreign;key";
DROP TABLE child;
DROP TABLE parent;
SQL

my $insert_correct = <<'SQL';
INSERT INTO parent (a, b, c, d) VALUES ('pippo1;', ';pluto1', NULL, NULL);
INSERT INTO parent (a, b, c, d) VALUES ('pippo2;', ';pluto2', NULL, NULL);
INSERT INTO parent (a, b, c, d) VALUES ('pippo3;', ';pluto3', NULL, NULL);
INSERT INTO parent (a, b, c, d) VALUES ('pippo4;', ';pluto4', NULL, NULL);
SQL

my $insert_bad = <<'SQL';
INSERT INTO parent (a, b, c, d) VALUES ('pippo5', 'pluto5', NULL, NULL);
INSERT INTO parent (a, b, c, d) VALUES ('pippo6', 'pluto6'             ;
SQL

my $insert_bad2 = <<'SQL';
INSERT INTO parent (a, b, c, d) VALUES ('pippo7', 'pluto7', NULL, NULL);
INSERT INTO parent (a, b, c, d) VALUES ('pippo8', 'pluto8'             ;
SQL

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', {
    PrintError => 0
});

my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );

my @results;
my $result;

ok ( @results = $batch->do($create), 'multiple create on sqlite' );
cmp_ok ( scalar(@results), '==', 3, 'check success' );

ok (
    @results = $batch->do($insert_correct),
    'multiple correct INSERTs on sqlite'
);
cmp_ok ( scalar(@results), '==', 4, 'check success' );

@results = $batch->do($insert_bad);
cmp_ok ( scalar(@results), '==', 0, 'check failure' );

$result = $batch->do($insert_bad2);
ok ( ! $result, 'multiple mixed INSERTs, check failure in scalar context' );

@results = $batch->do($insert_bad2);
ok ( ! @results, 'multiple mixed INSERTs, check failure in list context' );

ok ( @results = $batch->do($drop), 'multiple drop on sqlite' );
cmp_ok ( scalar(@results), '==', 3, 'check success' );

ok ( $batch->dbh->{AutoCommit}  , '$dbh->{AutoCommit} automatically restored' );
ok ( ! $batch->dbh->{RaiseError}, '$dbh->{RaiseError} automatically restored' );
