#!/usr/bin/perl

# Misc tests

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI"); }
do "./t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, &COL_NULLABLE ],
    [ "name", "CHAR",    64, &COL_NULLABLE ],
    );

ok (my $dbh = Connect (),				"connect");

ok (my $tbl = FindNewTable ($dbh),			"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,			"table definition");
ok ($dbh->do ($def),					"create table");

is ($dbh->quote ("tast1"), "'tast1'",			"quote");

ok (my $sth = $dbh->prepare ("select * from $tbl where id = 1"), "prepare");
{   local $dbh->{PrintError} = 0;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    eval { is ($sth->fetch, undef,			"fetch w/o execute"); };
    is (scalar @warn, 1,				"one error");
    like ($warn[0],
	qr/fetch row without a precee?ding execute/,	"error message");
    }
ok ($sth->execute,					"execute");
is ($sth->fetch, undef,					"fetch no rows");
ok ($sth->finish,					"finish");
undef $sth;

ok ($sth = $dbh->prepare ("insert into $tbl values (?, ?)"),	"prepare ins");
ok ($sth->execute ($_, "Code $_"),			"insert $_") for 1 .. 9;
ok ($sth->finish,					"finish");
undef $sth;

ok ($sth = $dbh->prepare ("select * from $tbl order by id"),	"prepare sel");
# Test what happens with two consequetive execute ()'s
ok ($sth->execute,					"execute 1");
ok ($sth->execute,					"execute 2");

# Test all fetch methods
ok (my @row = $sth->fetchrow_array,			"fetchrow_array");
is_deeply (\@row, [ 1, "Code 1" ],			"content");
ok (my $row = $sth->fetchrow_arrayref,			"fetchrow_arrayref");
is_deeply ( $row, [ 2, "Code 2" ],			"content");
ok (   $row = $sth->fetchrow_hashref,			"fetchrow_hashref");
is_deeply ( $row, { id => 3, name => "Code 3" },	"content");
ok (my $all = $sth->fetchall_hashref ("id"),		"fetchall_hashref");
is_deeply ($all,
    { map { ( $_ => { id => $_, name => "Code $_" } ) } 4 .. 9 }, "content");

ok ($sth->execute,					"execute");
ok (   $all = $sth->fetchall_arrayref,			"fetchall_arrayref");
is_deeply ($all, [ map { [ $_, "Code $_" ] } 1 .. 9 ],	"content");

ok ($dbh->do ("drop table $tbl"),			"drop table");
ok ($dbh->disconnect,					"disconnect");

done_testing ();
