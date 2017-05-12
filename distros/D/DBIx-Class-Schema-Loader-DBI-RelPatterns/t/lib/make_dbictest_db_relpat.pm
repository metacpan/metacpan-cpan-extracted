package make_dbictest_db_relpat;

# adapted from DBIx::Class::Schema::Loader test suite

use strict;
use warnings;
use DBI;
use dbixcsl_test_dir qw/$tdir/;

eval { require DBD::SQLite };
my $class = $@ ? 'SQLite2' : 'SQLite';

my $fn = "$tdir/dbictest.db";

unlink($fn);
our $dsn = "dbi:$class:dbname=$fn";
my $dbh = DBI->connect($dsn);
$dbh->do('PRAGMA SYNCHRONOUS = OFF');

$dbh->do($_) for (
    q|CREATE TABLE foos (
        fooint  INTEGER NOT NULL,
        fooreal REAL,
        foonum  NUMERIC,
        barid   INTEGER,
        quuxid  INTEGER,
        PRIMARY KEY (fooint,fooreal,foonum)
      )|,
    q|CREATE INDEX foos_fooreal_idx ON foos (fooreal)|,
    q|CREATE INDEX foos_quuxid_idx  ON foos (quuxid)|,
    
    q|CREATE TABLE Bars (
        barid   INTEGER PRIMARY KEY,
        quuxref INTEGER REFERENCES quuxs(quuxid),
        foosint  INTEGER NOT NULL,
        foosreal REAL    NOT NULL,
        foosnum  NUMERIC NOT NULL UNIQUE
      )|,
    q|CREATE INDEX bars_fooint_fooreal_foonum_idx ON Bars (foosint,foosreal,foosnum)|,
    q|CREATE INDEX bars_fooint_idx  ON Bars (foosint)|,
    q|CREATE INDEX bars_fooreal_idx ON Bars (foosreal)|,
    
    q|CREATE TABLE quuxs (
        quuxid  INTEGER NOT NULL UNIQUE,
        id      INTEGER NOT NULL UNIQUE,
        foo_num  NUMERIC NOT NULL UNIQUE,
        foo_real REAL    NOT NULL,
        barID   INTEGER
      )|,
    q|CREATE UNIQUE INDEX quuxs_foonum_fooreal_idx ON quuxs (foo_num,foo_real)|,
    q|CREATE INDEX quuxs_fooreal_idx ON quuxs (foo_real)|,
    q|CREATE INDEX quuxs_barid_idx ON quuxs (barID)|,
);

END { unlink($fn) unless $ENV{SCHEMA_LOADER_TESTS_NOCLEANUP}; }

1;
