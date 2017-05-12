#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }
do "t/lib.pl";

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
ok ($dbh->disconnect,			"disconnect");

ok (-f $tbl_file,			"file still there");
open my $fh, ">>", $tbl_file;
print $fh qq{1, "p0wnd",",""",0\n};	# Very bad content
close $fh;

ok ($dbh = Connect (),			"connect");
{   local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 0;
    ok (my $sth = $dbh->prepare ("select * from $tbl"), "prepare");
    is ($sth->execute, undef,		"execute should fail");
    # It is safe to regex on this text, as it is NOT local dependent
    like ($dbh->errstr, qr{\w+ \@ line [0-9?]+ pos [0-9?]+}, "error message");
    };
ok ($dbh->do ("drop table $tbl"),       "drop");
ok ($dbh->disconnect,                   "disconnect");

done_testing ();
