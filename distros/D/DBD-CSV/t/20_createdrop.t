#!/usr/bin/perl

# Test if a table can be created and dropped

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }
do "./t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, 0 ],
    [ "name", "CHAR",    64, 0 ],
    );

ok (my $dbh = Connect (),		"connect");

ok (my $tbl = FindNewTable ($dbh),	"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,	"table definition");
ok ($dbh->do ($def),			"create table");
my $tbl_file = DbFile ($tbl);
ok (-s $tbl_file,			"file exists");
ok ($dbh->do ("drop table $tbl"),	"drop table");
ok ($dbh->disconnect,			"disconnect");
ok (!-f $tbl_file,			"file removed");

done_testing ();
