#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DBI;
use DBIx::Util::Schema qw(
                             table_exists
                             has_table
                             has_all_tables
                             has_any_table

                             column_exists
                             has_column
                             has_all_columns
                             has_any_column

                             list_tables
                             list_columns
                             list_indexes
                     );

# TODO:
#                              primary_key_columns
#                              has_primary_key
#                              has_index_on
#                              has_unique_index_on
#                              has_a_unique_index

use File::chdir;
use File::Temp qw(tempdir);

my $tempdir = tempdir(CLEANUP => 1);
$CWD = $tempdir;
my ($dbh1, $dbh2);

subtest sqlite => sub {
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$tempdir/db.db", undef, undef, {RaiseError=>1});
    $dbh->do("CREATE TABLE t1 (i INT NOT NULL PRIMARY KEY)");
    $dbh->do("CREATE TABLE t2 (a INT, i1 INT, f1 FLOAT NOT NULL, d1 DECIMAL(10,3), s1 VARCHAR(10))");
    $dbh->do("CREATE INDEX ix_t2_a ON t2(a)");

    subtest "has_table, table_exists" => sub {
        ok( table_exists($dbh, "t1"));
        ok( has_table   ($dbh, "t2"));
        ok(!table_exists($dbh, "t3"));
    };

    subtest "has_all_tables" => sub {
        ok( has_all_tables($dbh, "t1"));
        ok( has_all_tables($dbh, "t1", "t2"));
        ok(!has_all_tables($dbh, "t1", "t2", 't3'));
    };

    subtest "has_any_table" => sub {
        ok( has_any_table($dbh, "t1"));
        ok( has_any_table($dbh, "t1", "t2"));
        ok( has_any_table($dbh, "t1", "t3"));
        ok(!has_any_table($dbh, "t3", "t4"));
    };

    subtest "has_column, column_exists" => sub {
        ok( column_exists($dbh, "t1", "i"));
        ok(!column_exists($dbh, "t1", "j"));
        ok( has_column   ($dbh, "t2", "a"));
        ok( has_column   ($dbh, "t2", "d1"));
        ok(!has_column   ($dbh, "t2", "d2"));
    };

    subtest "has_all_columns" => sub {
        ok( has_all_columns($dbh, "t2", "a"));
        ok( has_all_columns($dbh, "t2", "a", "i1", "f1"));
        ok(!has_all_columns($dbh, "t2", "a", "i1", "f1", "z"));
    };

    subtest "has_any_column" => sub {
        ok( has_any_column($dbh, "t2", "a"));
        ok( has_any_column($dbh, "t2", "a", "i1", "f1"));
        ok( has_any_column($dbh, "t2", "a", "i1", "f1", "z"));
        ok(!has_any_column($dbh, "t2", "z"));
    };

    subtest list_tables => sub {
        my @tables = list_tables($dbh);
        is(scalar(@tables), 2);
        # XXX test details
    };

    subtest list_columns => sub {
        my @columns = list_columns($dbh, 't2');
        is(scalar(@columns), 5);
        # XXX test details
    };

    subtest list_indexes => sub {
        my @indexes;

        @indexes = list_indexes($dbh);
        is(scalar(@indexes), 2);
        # XXX test details
    };
};

DONE_TESTING:
done_testing;
