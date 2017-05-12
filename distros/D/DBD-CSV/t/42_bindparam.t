#!/usr/bin/perl

# Test if bindparam () works

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }

if ($ENV{DBI_SQL_NANO}) {
    diag ("These tests are not yet supported for SQL::Nano");
    done_testing (1);
    exit 0;
    }

do "t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, 0			],
    [ "name", "CHAR",    64, &COL_NULLABLE	],
    );

ok (my $dbh = Connect (),			"connect");
ok ($dbh->{csv_null} = 1,			"Allow NULL");

ok (my $tbl = FindNewTable ($dbh),		"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,		"table definition");
ok ($dbh->do ($def),				"create table");

ok (my $sth = $dbh->prepare ("insert into $tbl values (?, ?)"), "prepare");

# Automatic type detection
my ($int, $chr) = (1, "Alligator Descartes");
ok ($sth->execute ($int, $chr),			"execute insert 1");

# Does the driver remember the automatically detected type?
ok ($sth->execute ("3", "Jochen Wiedman"),	"execute insert 2");

($int, $chr) = (2, "Tim Bunce");
ok ($sth->execute ($int, $chr),			"execute insert 3");

# Now try the explicit type settings
ok ($sth->bind_param (1, " 4", &SQL_INTEGER),	"bind 4 int");
ok ($sth->bind_param (2, "Andreas König"),	"bind str");
ok($sth->execute,				"execute");

# Works undef -> NULL?
ok ($sth->bind_param (1, 5, &SQL_INTEGER),	"bind 5 int");
ok ($sth->bind_param (2, undef),		"bind NULL");
ok($sth->execute,				"execute");

ok ($sth->finish,				"finish");
undef $sth;
ok ($dbh->disconnect,				"disconnect");
undef $dbh;


# And now retrieve the rows using bind_columns
ok ($dbh = Connect ({ csv_null => 1 }),		"connect");

ok ($sth = $dbh->prepare ("select * from $tbl order by id"),	"prepare");
ok ($sth->execute,				"execute");

my ($id, $name);
ok ($sth->bind_columns (undef, \$id, \$name),	"bind_columns");
ok ($sth->execute,				"execute");
ok ($sth->fetch,				"fetch");
is ($id,	1,				"id   1");
is ($name,	"Alligator Descartes",		"name 1");
ok ($sth->fetch,				"fetch");
is ($id,	2,				"id   2");
is ($name,	"Tim Bunce",			"name 2");
ok ($sth->fetch,				"fetch");
is ($id,	3,				"id   3");
is ($name,	"Jochen Wiedman",		"name 3");
ok ($sth->fetch,				"fetch");
is ($id,	4,				"id   4");
is ($name,	"Andreas König",		"name 4");
ok ($sth->fetch,				"fetch");
is ($id,	5,				"id   5");
is ($name,	undef,				"name 5");

ok ($sth->finish,				"finish");
undef $sth;

ok ($sth = $dbh->prepare ("update $tbl set name = ? where id = ?"), "prepare update");
is ($sth->execute ("Tux", 5), 1,		"update");
ok ($sth->finish,				"finish");
undef $sth;
ok ($sth = $dbh->prepare ("update $tbl set id = ? where name = ?"), "prepare update");
is ($sth->execute (5, "Tux"), 1,		"update");
is ($sth->execute (6, ""),    "0E0",		"update");
ok ($sth->finish,				"finish");
undef $sth;

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok ($dbh->disconnect,				"disconnect");

done_testing ();
