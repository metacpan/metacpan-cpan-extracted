#!perl

use strict;
use warnings;

use DBI;
use DBIx::DoMore;

use Test::More tests => 10;

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

my $do_more = DBIx::DoMore->new( dbh => $dbh );

my @results;
my $result;

ok ( @results = $do_more->do($create), 'multiple create on sqlite' );
ok ( @results == 3                   , 'check success'             );

ok ( @results = $do_more->do($insert_correct), 'multiple correct INSERTs on sqlite' );
ok ( @results == 4                           , 'check success'                      );

@results = $do_more->do($insert_bad);
ok ( @results == 0, 'check failure' );

$result = $do_more->do($insert_bad2);
ok ( ! $result, 'multiple mixed INSERTs, check failure in scalar context' );

ok ( @results = $do_more->do($drop), 'multiple drop on sqlite' );
ok ( @results == 3                 , 'check success'           );

ok ( $do_more->dbh->{AutoCommit}  , '$dbh->{AutoCommit} restored' );
ok ( ! $do_more->dbh->{RaiseError}, '$dbh->{RaiseError} restored' );
