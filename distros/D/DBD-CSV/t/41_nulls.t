#!/usr/bin/perl

# This is a test for correctly handling NULL values.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }
do "t/lib.pl";

my $nano = $ENV{DBI_SQL_NANO};
my @tbl_def = (
    [ "id",   "INTEGER",  4, &COL_NULLABLE	],
    [ "name", "CHAR",    64, &COL_NULLABLE	],
    [ "str",  "CHAR",    64, &COL_NULLABLE	],
    );

ok (my $dbh = Connect (),			"connect");

ok (my $tbl = FindNewTable ($dbh),		"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,		"table definition");
ok ($dbh->do ($def),				"create table");

ok ($dbh->do ("insert into $tbl values (NULL, 'NULL-id', ' ')"), "insert");

my $row;

ok (my $sth = $dbh->prepare ("select * from $tbl where id is NULL"), "prepare");
ok ($sth->execute,				"execute");
TODO: {
    local $TODO = $nano ? "SQL::Nano does not yet support this syntax" : undef;
    ok ($row = $sth->fetch,			"fetch");
    is_deeply ($row, [ "", "NULL-id", " " ],	"default content");
    }
ok ($sth->finish,				"finish");
undef $sth;

ok ($dbh = Connect ({ csv_null => 1 }),		"connect csv_null");

ok ($sth = $dbh->prepare ("select * from $tbl where id is NULL"), "prepare");
ok ($sth->execute,				"execute");
TODO: {
    local $TODO = $nano ? "SQL::Nano does not yet support this syntax" : undef;
    ok ($row = $sth->fetch,				"fetch");
    is_deeply ($row, [ undef, "NULL-id", " " ],	"NULL content");
    }
ok ($sth->finish,				"finish");
undef $sth;

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok ($dbh->disconnect,				"disconnect");

ok ($dbh = Connect ({ csv_null => 1 }),		"connect csv_null");
ok ($dbh->do ($def),				"create table");

ok ($dbh->do ("insert into $tbl (id, str) values (1, ' ')"), "insert just 2");

ok ($sth = $dbh->prepare ("select * from $tbl"), "prepare");
ok ($sth->execute,				"execute");
ok ($row = $sth->fetch,				"fetch");
is_deeply ($row, [ 1, undef, " " ],		"content");

ok ($sth->finish,				"finish");
undef $sth;

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok ($dbh->disconnect,				"disconnect");

done_testing ();
