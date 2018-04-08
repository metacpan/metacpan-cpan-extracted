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

my $dbh;
my @ext = ("", ".csv", ".foo", ".txt");

sub DbFile;

my $usr = eval { getpwuid $< } || $ENV{USERNAME} || "";
sub Tables {
    my @tbl = $dbh->tables ();
    if ($usr) {
	s/^['"]*$usr["']*\.//i for @tbl;
	}
    sort @tbl;
    } # Tables

my $dir = DbDir ();

ok ($dbh = Connect (),				"connect");

ok (my $tbl = FindNewTable ($dbh),		"find new test table");
ok (!-f DbFile ($tbl),				"does not exist");

foreach my $ext (@ext) {
    my $qt = '"'.$tbl.$ext.'"';
    like (my $def = TableDefinition ($qt, @tbl_def),
	qr{^create table $qt}i,			"table definition");
    ok ($dbh->do ($def),			"create table $ext");
    ok (-f DbFile ($tbl.$ext),			"does exists");
    }

ok (my @tbl = Tables (),			"tables");
is_deeply (\@tbl, [ map { "$tbl$_" } @ext ],	"for all ext");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok ($dbh = DBI->connect ("dbi:CSV:", "", "", {
    f_dir	=> $dir,
    f_ext	=> ".csv",
    }),						"connect (f_ext => .csv)");
ok (@tbl = Tables (),				"tables");
is_deeply (\@tbl,
    [ map { "$tbl$_" } grep { !m/\.csv$/i } @ext ],	"for all ext");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok ($dbh = DBI->connect ("dbi:CSV:", "", "", {
    f_dir	=> $dir,
    f_ext	=> ".csv/r",
    }),						"connect (f_ext => .csv/r)");
ok (@tbl = Tables (),				"tables");
is_deeply (\@tbl, [ $tbl ],			"just one");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok ($dbh = Connect (),				"connect");

ok (@tbl = Tables (),				"tables");
ok ($dbh->do ("drop table $_"),			"drop table $_") for @tbl;

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok (rmdir $dir,					"no files left");

done_testing ();
