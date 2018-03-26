#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI"); }
do "./t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, 0 ],
    [ "name", "CHAR",    64, 0 ],
    );

my $dir = DbDir ();

ok (my $dbh = DBI->connect ("dbi:CSV:", "", "", {
	f_dir	=> $dir,
	}),					"connect");

ok (my $tbl = FindNewTable ($dbh),		"find new test table");
like (my $def = TableDefinition ($tbl, @tbl_def),
    qr{^create table $tbl}i,			"table definition");
ok ($dbh->do ($def),				"create table");

my @tbl = $dbh->tables ();
if (my $usr = eval { getpwuid $< }) {
    s/^(['"`])(.+)\1\./$2./ for @tbl;
    is_deeply (\@tbl, [ qq{$usr.$tbl} ],	"tables");
    }
else {
    is_deeply (\@tbl, [ qq{$tbl}      ],	"tables");
    }

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok ($dbh = DBI->connect ("dbi:CSV:", "", "", {
    f_schema	=> undef,
    f_dir	=> $dir,
    }),						"connect (f_schema => undef)");
is_deeply ([ $dbh->tables () ], [ $tbl ],	"tables");

ok ($dbh->do ("drop table $tbl"),		"drop table");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok (rmdir $dir,					"no files left");

done_testing ();
