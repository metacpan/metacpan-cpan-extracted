#!/usr/local/bin/perl

# Test row insertion and retrieval

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }
do "t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, 0 ],
    [ "name", "CHAR",    64, 0 ],
    [ "val",  "INTEGER",  4, 0 ],
    [ "txt",  "CHAR",    64, 0 ],
    );

ok (my $dbh = Connect (),		"connect");

ok (my $tbl = FindNewTable ($dbh),	"find new test table");
$tbl ||= "tmp99";
eval {
    local $SIG{__WARN__} = sub {};
    $dbh->do ("drop table $tbl");
    };

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,	"table definition");

my $sz = 0;
ok ($dbh->do ($def),			"create table");
my $tbl_file = DbFile ($tbl);
ok ($sz = -s $tbl_file,			"file exists");

ok ($dbh->do ("insert into $tbl values ".
	      "(1, 'Alligator Descartes', 1111, 'Some Text')"), "insert");
ok ($sz < -s $tbl_file,			"file grew");
$sz = -s $tbl_file;

ok ($dbh->do ("insert into $tbl (id, name, val, txt) values ".
	      "(2, 'Crocodile Dundee',    2222, 'Down Under')"), "insert with field names");
ok ($sz < -s $tbl_file,			"file grew");

ok (my $sth = $dbh->prepare ("select * from $tbl where id = 1"), "prepare");
is (ref $sth, "DBI::st",		"handle type");

ok ($sth->execute,			"execute");

ok (my $row = $sth->fetch,		"fetch");
is (ref $row, "ARRAY",			"returned a list");
is ($sth->errstr, undef,		"no error");

is_deeply ($row, [ 1, "Alligator Descartes", 1111, "Some Text" ], "content");

ok ($sth->finish,			"finish");
undef $sth;

# Try some other capitilization
ok ($dbh->do ("DELETE FROM $tbl WHERE id = 1"),	"delete");

# Now, try SELECT'ing the row out. This should fail.
ok ($sth = $dbh->prepare ("select * from $tbl where id = 1"), "prepare");
is (ref $sth, "DBI::st",		"handle type");

ok ($sth->execute,			"execute");
is ($sth->fetch,  undef,		"fetch");
is ($sth->errstr, undef,		"error");	# ???

ok ($sth->finish,			"finish");
undef $sth;

ok ($sth = $dbh->prepare ("insert into $tbl values (?, ?, ?, ?)"), "prepare insert");
ok ($sth->execute (3, "Babar", 3333, "Elephant"), "insert prepared");
ok ($sth->finish,			"finish");
undef $sth;

ok ($sth = $dbh->prepare ("insert into $tbl (id, name, val, txt) values (?, ?, ?, ?)"), "prepare insert with field names");
ok ($sth->execute (4, "Vischje", 33, "in het riet"), "insert prepared");
ok ($sth->finish,			"finish");
undef $sth;

ok ($dbh->do ("delete from $tbl"),	"delete all");
ok ($dbh->do ("insert into $tbl (id) values (0)"), "insert just one field");
{   local (@ARGV) = DbFile ($tbl);
    my @csv = <>;
    s/\r?\n\Z// for @csv;
    is (scalar @csv, 2,			"Just two lines");
    is ($csv[0], "id,name,val,txt",	"header");
    is ($csv[1], "0,,,",		"data");
    }

ok ($dbh->do ("drop table $tbl"),	"drop");
ok ($dbh->disconnect,			"disconnect");

done_testing ();
