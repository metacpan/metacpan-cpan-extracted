#!perl

use strict;
use warnings;

use DBI;
use DBIx::DoMore;

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

my $do_more = DBIx::DoMore->new(
    dbh      => $dbh,
    rollback => 0
);

my @results;
my $result;

ok ( @results = $do_more->do($create), 'multiple create on sqlite' );
ok ( @results == 3                   , 'check success'             );

@results = ();
my $rollback_done;

$do_more->dbh->{AutoCommit} = 0;
$do_more->dbh->{RaiseError} = 1;
eval {
    @results = $do_more->do( $insert_bad );
    $do_more->dbh->commit;
    1
} or do {
    eval { $do_more->dbh->rollback };
    $rollback_done = 1
};

ok ( @results == 0, 'check failure' );
ok ( $rollback_done, 'check rollback' );
