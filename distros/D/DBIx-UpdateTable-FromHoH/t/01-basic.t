#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use DBI;
use DBIx::UpdateTable::FromHoH qw(update_table_from_hoh);
use File::Temp qw(tempdir);

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
note "tempdir=$tempdir";
my $dbh = DBI->connect("dbi:SQLite:dbname=$tempdir/db.db", undef, undef, {RaiseError=>1});

$dbh->do("CREATE TABLE t1 (i INT NOT NULL PRIMARY KEY, col1 TEXT, col2 TEXT, col3 TEXT)");
$dbh->do("INSERT INTO t1 (i,col1,col2,col3) VALUES (1,'a','b','foo')");
$dbh->do("INSERT INTO t1 (i,col1,col2,col3) VALUES (2,'c','c','bar')");
$dbh->do("INSERT INTO t1 (i,col1,col2,col3) VALUES (3,'g','h','qux')");

my $hoh = {
    1 => {col1=>'a', col2=>'b'},
    2 => {col1=>'c', col2=>'d'},
    4 => {col1=>'e', col2=>'f'},
};

my $res = update_table_from_hoh(
    dbh => $dbh,
    hoh => $hoh,
    table => 't1',
    key_column => 'i',
    extra_insert_columns => {col3=>'corge'},
    extra_update_columns => {col3=>'baz'},
);
is_deeply($res, [200, "OK", {num_rows_inserted=>1, num_rows_deleted=>1, num_rows_updated=>1, num_rows_unchanged=>1}]);

my $hoh_table = $dbh->selectall_hashref("SELECT * FROM t1", "i");
is_deeply(
    $hoh_table,
    {
        1 => {i=>1, col1=>'a', col2=>'b', col3=>'foo'},
        2 => {i=>2, col1=>'c', col2=>'d', col3=>'baz'},
        4 => {i=>4, col1=>'e', col2=>'f', col3=>'corge'},
    });

$res = update_table_from_hoh(
    dbh => $dbh,
    hoh => $hoh,
    table => 't1',
    key_column => 'i',
);
is_deeply($res, [304, "OK", {num_rows_inserted=>0, num_rows_deleted=>0, num_rows_updated=>0, num_rows_unchanged=>3}]);

DONE_TESTING:
done_testing;
