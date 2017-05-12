use strict;
use warnings;

use DBI;
use DBIx::MultiStatementDo;

use Test::More tests => 1;

my $create = <<'SQL';
CREATE TABLE parent(a, b, c   , d    );
CREATE TABLE child (x, y, "w;", "z;z");
CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
    EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
BEGIN
    SELECT RAISE(ABORT, 'constraint failed;');
END;
INSERT INTO parent (a, b, c, d) VALUES ('pippo;', 'pluto;', NULL, NULL)
SQL

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '' );

my $batch = DBIx::MultiStatementDo->new( dbh => $dbh );

# Multiple SQL statements in a single call
my @results = $batch->do($create);

#diag scalar(@results) . ' statements successfully executed';
ok ( @results == 4, 'check success' );
