#!/usr/bin/perl

# This tests, whether the number of rows can be retrieved.

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }
require "t/lib.pl";

sub TrueRows
{
    my $sth = shift;
    my $count = 0;
    $count++ while $sth->fetch;
    $count;
    } # TrueRows

my @tbl_def = (
    [ "id",   "INTEGER",  4, 0 ],
    [ "name", "CHAR",    64, 0 ],
    );

my ($sth, $rows);

ok (my $dbh = Connect (),		"connect");

ok (my $tbl = FindNewTable ($dbh),	"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,	"table definition");
ok ($dbh->do ($def),			"create table");

ok ($dbh->do ("INSERT INTO $tbl VALUES (1, 'Alligator Descartes')"), "insert");

ok ($sth = $dbh->prepare ("SELECT * FROM $tbl WHERE id = 1"),        "prepare");
ok ($sth->execute,			"execute");

is ($sth->rows, 1,			"numrows");
is (TrueRows ($sth), 1,			"true rows");

ok ($sth->finish,			"finish");
undef $sth;


ok ($dbh->do ("INSERT INTO $tbl VALUES (2, 'Jochen Wiedman')"), "insert");

ok ($sth = $dbh->prepare ("SELECT * FROM $tbl WHERE id >= 1"),  "prepare");
ok ($sth->execute,			"execute");

$rows = $sth->rows;
ok ($rows == 2 || $rows == -1,		"rows");
is (TrueRows ($sth), 2,			"true rows");

ok ($sth->finish,			"finish");
undef $sth;

ok ($dbh->do ("INSERT INTO $tbl VALUES (3, 'Tim Bunce')"),     "insert");

ok ($sth = $dbh->prepare ("SELECT * FROM $tbl WHERE id >= 2"), "prepare");
ok ($sth->execute,			"execute");

$rows = $sth->rows;
ok ($rows == 2 || $rows == -1,		"rows");
is (TrueRows ($sth), 2,			"true rows");

ok ($sth->finish,			"finish");
undef $sth;

ok ($dbh->do ("DROP TABLE $tbl"),	"drop");
ok ($dbh->disconnect,			"disconnect");

done_testing ();
