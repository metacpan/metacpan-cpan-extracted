#!perl -w
use strict;
use Test2::V0 '-no_srand';

use DBIx::RunSQL;

my $can_run = eval {
    require DBD::SQLite;
    1
};

if (not $can_run) {
    plan skip_all => "SQLite not installed";
}

plan tests => 2;

my $sql = do { local (@ARGV,$/) = 't/trigger.sql'; <> };
my @statements;
while( defined( my $frag = DBIx::RunSQL->split_sql( $sql ))) {
    push @statements, $frag;
}
is \@statements, [
  '-- This commented-out statement will not get passed through',
  "-- SECRET PRAGMA #foo will get passed through with the next statement\r\n"
  . "create table test (\r\n"
  . "    id integer unique not null,\r\n"
  . "    descr text default '',\r\n"
  . "    ts text\r\n"
  . ")",
    "CREATE TRIGGER trg_test_1 AFTER INSERT ON test\r\n"
  . "     BEGIN\r\n"
  . "      UPDATE test SET ts = DATETIME('NOW')  WHERE rowid = new.rowid;\n"
  . "END",
    "CREATE TRIGGER trg_test_2 AFTER INSERT ON test BEGIN\r\n"
  . "      UPDATE test SET ts = DATETIME('NOW')  WHERE rowid = new.rowid;\n"
  . "END",
], "We split the statements in the expected fashion";

my $lives = eval {
    my $test_dbh = DBIx::RunSQL->create(
        dsn     => 'dbi:SQLite:dbname=:memory:',
        sql     => 't/trigger.sql',
        #verbose => 1,
    );
    1;
};
my $err = $@;
ok $lives, "We can parse triggers"
    or diag $err;

