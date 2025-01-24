package make_dbictest_db_multi_m2m;

use strict;
use warnings;
use DBI;
use dbixcsl_test_dir qw/$tdir/;

eval { require DBD::SQLite };
my $class = $@ ? 'SQLite2' : 'SQLite';

my $fn = "$tdir/dbictest_multi_m2m.db";

unlink($fn);
our $dsn = "dbi:$class:dbname=$fn";
my $dbh = DBI->connect($dsn);
$dbh->do('PRAGMA SYNCHRONOUS = OFF');

$dbh->do($_) for (
    q|CREATE TABLE foo (
        foo_id INTEGER PRIMARY KEY
      )|,
    q|CREATE TABLE bar (
        bar_id INTEGER PRIMARY KEY
      )|,
    q|CREATE TABLE foo_bar_one (
        foo_id INTEGER NOT NULL REFERENCES foo(foo_id),
        bar_id INTEGER NOT NULL REFERENCES bar(bar_id),
        PRIMARY KEY (foo_id, bar_id)
      )|,
    q|CREATE TABLE foo_bar_two (
        foo_id INTEGER NOT NULL REFERENCES foo(foo_id),
        bar_id INTEGER NOT NULL REFERENCES bar(bar_id),
        PRIMARY KEY (foo_id, bar_id)
     )|,
    q|INSERT INTO foo (foo_id) VALUES (1)|,
    q|INSERT INTO foo (foo_id) VALUES (2)|,
    q|INSERT INTO bar (bar_id) VALUES (1)|,
    q|INSERT INTO bar (bar_id) VALUES (2)|,
    q|INSERT INTO foo_bar_one (foo_id, bar_id) VALUES (1,1)|,
    q|INSERT INTO foo_bar_one (foo_id, bar_id) VALUES (2,2)|,
    q|INSERT INTO foo_bar_two (foo_id, bar_id) VALUES (1,1)|,
    q|INSERT INTO foo_bar_two (foo_id, bar_id) VALUES (1,2)|,
    q|INSERT INTO foo_bar_two (foo_id, bar_id) VALUES (2,1)|,
    q|INSERT INTO foo_bar_two (foo_id, bar_id) VALUES (2,2)|,
);

END { unlink($fn) unless $ENV{SCHEMA_LOADER_TESTS_NOCLEANUP}; }

1;
