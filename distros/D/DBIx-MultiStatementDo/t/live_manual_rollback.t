#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;

use Test::More tests => 4;

my $create = <<'SQL';
CREATE TABLE parent( a, b, c, d, PRIMARY KEY(a, b) );
CREATE TABLE child( x, y, "w;", "z;z", FOREIGN KEY (x, y) REFERENCES parent (a,b) );
CREATE TRIGGER "foreign;key" BEFORE DELETE ON "parent" WHEN
    EXISTS (SELECT 1 FROM "child" WHERE old."a" == "x" AND old."b" == "y")
BEGIN
    SELECT RAISE(ABORT, 'constraint failed;');
END;
SQL

my $insert_bad = <<'SQL';
INSERT INTO parent (a, b, c, d) VALUES ('pippo1', 'pluto1', NULL, NULL);
INSERT INTO parent (a, b, c, d) VALUES ('pippo2', 'pluto2'             ;
SQL

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', {
    PrintError => 0
});

my $batch = DBIx::MultiStatementDo->new(
    dbh      => $dbh,
    rollback => 0
);

my @results;
my $result;

ok ( @results = $batch->do($create), 'multiple create on sqlite' );
cmp_ok ( scalar(@results), '==', 3, 'check success' );

@results = ();
my $rollback_done;

$batch->dbh->{AutoCommit} = 0;
$batch->dbh->{RaiseError} = 1;
eval {
    @results = $batch->do( $insert_bad );
    $batch->dbh->commit;
    1
} or do {
    eval { $batch->dbh->rollback };
    $rollback_done = 1
};

cmp_ok ( scalar(@results), '==', 0, 'check failure' );
ok ( $rollback_done, 'check rollback' );
