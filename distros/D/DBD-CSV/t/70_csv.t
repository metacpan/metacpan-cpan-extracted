#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI"); }
do "t/lib.pl";

my @tbl_def = (
    [ "id",   "INTEGER",  4, &COL_KEY		],
    [ "str",  "CHAR",    64, &COL_NULLABLE	],
    [ "name", "CHAR",    64, &COL_NULLABLE	],
    );

sub DbFile;

my $dir = "output$$";
my $fqd = File::Spec->rel2abs ($dir);
my $abs = Cwd::abs_path ($dir);

ok (my $dbh = Connect (),			"connect");

ok ($dbh->{f_dir} eq $dir || $dbh->{f_dir} eq $abs ||
    $dbh->{f_dir} eq $fqd,			"default dir");
ok ($dbh->{f_dir} = $dir,			"set f_dir");

ok (my $tbl  = FindNewTable ($dbh),		"find new test table");
ok (!-f DbFile ($tbl),				"does not exist");

ok (my $tbl2 = FindNewTable ($dbh),		"find new test table");
ok (!-f DbFile ($tbl2),				"does not exist");

ok (my $tbl3 = FindNewTable ($dbh),		"find new test table");
ok (!-f DbFile ($tbl3),				"does not exist");

ok (my $tbl4 = FindNewTable ($dbh),		"find new test table");
ok (!-f DbFile ($tbl4),				"does not exist");

isnt ($tbl,  $tbl2,				"different 1 2");
isnt ($tbl,  $tbl3,				"different 1 3");
isnt ($tbl,  $tbl4,				"different 1 4");
isnt ($tbl2, $tbl3,				"different 2 3");
isnt ($tbl2, $tbl4,				"different 2 4");
isnt ($tbl3, $tbl4,				"different 3 4");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,		"table definition");
ok ($dbh->do ($def),				"create table 1");
ok (-f DbFile ($tbl),				"does exists");

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok (!-f DbFile ($tbl),				"does not exist");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

my $dsn = "DBI:CSV:f_dir=$dir;csv_eol=\015\012;csv_sep_char=\\;;";
ok ($dbh = Connect ($dsn),			"connect");

ok ($dbh->do ($def),				"create table");
ok (-f DbFile ($tbl),				"does exists");

ok ($dbh->do ("insert into $tbl values (1, 1, ?)", undef, "joe"),     "insert 1");
ok ($dbh->do ("insert into $tbl values (2, 2, ?)", undef, "Jochen;"), "insert 2");

ok (my $sth = $dbh->prepare ("select * from $tbl"),	"prepare");
ok ($sth->execute,				"execute");
ok (my $row = $sth->fetch,			"fetch 1");
is_deeply ($row, [ 1, "1", "joe" ],		"content");
ok (   $row = $sth->fetch,			"fetch 2");
is_deeply ($row, [ 2, "2", "Jochen;" ],		"content");
ok ($sth->finish,				"finish");
undef $sth;

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok (!-f DbFile ($tbl),				"does not exist");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

$dsn = "DBI:CSV:";
ok ($dbh = Connect ($dsn),			"connect");

# Check, whether the csv_tables->{$tbl}{file} attribute works
like (my $def4 = TableDefinition ($tbl4, @tbl_def),
	qr{^create table $tbl4}i,		"table definition");
ok ($dbh->{csv_tables}{$tbl4}{file} = DbFile ($tbl4), "set table/file");
ok ($dbh->do ($def4),				"create table");
ok (-f DbFile ($tbl4),				"does exists");

ok ($dbh->do ("drop table $tbl4"),		"drop table");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

ok ($dbh = DBI->connect ("dbi:CSV:", "", "", {
    f_dir		=> DbDir (),
    f_ext		=> ".csv",
    dbd_verbose		=> 8,
    csv_sep_char	=> ";",
    csv_blank_is_undef	=> 1,
    csv_always_quote	=> 1,
    }),						"connect with attr");

is ($dbh->{dbd_verbose},	8,		"dbd_verbose set");
is ($dbh->{f_ext},		".csv",		"f_ext set");
is ($dbh->{csv_sep_char},	";",		"sep_char set");
is ($dbh->{csv_blank_is_undef},	1,		"blank_is_undef set");

ok ($dbh->do ($def),				"create table");
ok (-f DbFile ($tbl).".csv",			"does exists");
#is ($sth->{blank_is_undef},	1,		"blank_is_undef");
eval {
    local $SIG{__WARN__} = sub { };

    ok ($sth = $dbh->prepare ("insert into $tbl values (?, ?, ?)"), "prepare");
    is ($sth->execute (1, ""), undef,		"not enough values");
    like ($dbh->errstr, qr/passed 2 parameters where 3 required/, "error message");

    # Cannot use the same handle twice. SQL::Statement bug
    ok ($sth = $dbh->prepare ("insert into $tbl values (?, ?, ?)"), "prepare");
    is ($sth->execute (1, "", 1, ""), undef,	"too many values");
    like ($dbh->errstr, qr/passed 4 parameters where 3 required/, "error message");
    };
ok ($sth->execute ($_, undef, "Code $_"),	"insert $_") for 0 .. 9;

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok (!-f DbFile ($tbl),				"does not exist");
ok (!-f DbFile ($tbl).".csv",			"does not exist");

ok ($dbh->disconnect,				"disconnect");
undef $dbh;

done_testing ();
