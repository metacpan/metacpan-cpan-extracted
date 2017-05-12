#!/usr/bin/perl

# test if update returns expected values / keeps file sizes sane

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI"); }
do "t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, &COL_NULLABLE ],
    [ "name", "CHAR",    64, &COL_NULLABLE ],
    );

ok (my $dbh = Connect (),				"connect");

ok (my $tbl = FindNewTable ($dbh),			"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,			"table definition");
ok ($dbh->do ($def),					"create table");

my $sz = 0;
my $tbl_file = DbFile ($tbl);
ok ($sz = -s $tbl_file,					"file exists");

ok ($dbh->do ("insert into $tbl (id) values ($_)"),	"insert $_") for 1 .. 10;
ok ($sz < -s $tbl_file,					"file grew");
$sz = -s $tbl_file;

{   local $dbh->{PrintWarn}  = 0;
    local $dbh->{PrintError} = 0;
    is ($dbh->do ("update wxyz set name = 'ick' where id = 99"), undef,	"update in non-existing tbl");
    }
my  $zero_ret = $dbh->do ("update $tbl set name = 'ack' where id = 99");
ok ($zero_ret, "true non-existing update RV (via do)");
cmp_ok ($zero_ret, "==", 0, "update non-existing row (via do)");

cmp_ok ($sz, "==", -s $tbl_file, "file size did not change on noop updates");

is ($dbh->do ("update $tbl set name = 'multis' where id >  7"), 3, "update several (count) (via do)");
cmp_ok ($sz, "<", -s $tbl_file, "file size grew on update");

$sz = -s $tbl_file;
is ($dbh->do ("update $tbl set name = 'single' where id =  9"), 1, "update single (count) (via do)");
cmp_ok ($sz, "==", -s $tbl_file, "file size did not change on same-size update");


$zero_ret = $dbh->prepare ("update $tbl set name = 'ack' where id = 88")->execute;
ok ($zero_ret, "true non-existing update RV (via prepare/execute)");
cmp_ok ($zero_ret, "==", 0,    "update non-existing row (via prepare/execute)");
cmp_ok ($sz, "==", -s $tbl_file, "file size did not change on noop update");

$sz = -s $tbl_file;
is ($dbh->prepare ("update $tbl set name = 'multis' where id < 4")->execute, 3, "update several (count) (via prepare/execute)");
cmp_ok ($sz, "<", -s $tbl_file, "file size grew on update");

$sz = -s $tbl_file;
is ($dbh->prepare ("update $tbl set name = 'single' where id = 2")->execute, 1, "update single (count) (via prepare/execute)");
cmp_ok ($sz, "==", -s $tbl_file, "file size did not change on same-size update");

ok ($dbh->do ("drop table $tbl"),			"drop table");
ok ($dbh->disconnect,					"disconnect");
ok (!-f $tbl_file,					"file removed");

done_testing ();
