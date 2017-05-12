#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok ("DBI") }

my $dbh;
ok ($dbh = DBI->connect ("dbi:Unify:", "", ""), "connect");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

ok (1, "-- table ()");
my @tbl;
ok (@tbl = $dbh->tables (), "tables ()");
s/"//g for @tbl;
my %tbl = map { $_ => 1 } @tbl;
ok (exists $tbl{"SYS.ACCESSIBLE_TABLES"}, "base table existance");

my ($catalog, $schema, $table, $type, $rw);
ok (1, "-- table_info ()");
my $sth; # $dbh->table_info () returns a handle to be fetched
ok ($sth = $dbh->table_info (), "table_info ()");
ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
my $n = 0;
$n++ while $sth->fetch;
ok ($n == @tbl,		"table count");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info (undef), "table_info (undef)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info ({
    TABLE_CAT   => undef,
    TABLE_NAME  => undef,
    TABLE_TYPE  => undef,
    }), "table_info ({ TABLE_*** => undef })");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info (""), "table_info ('')");
ok ($sth->finish,	"finish");
ok (!$dbh->table_info ("DBUTIL"), "table_info ('DBUTIL')");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info (undef, "DBUTIL"), "table_info (undef, 'DBUTIL')");
ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
$n = 0;
$n++ while $sth->fetch;
ok (($n == grep m/^DBUTIL\./ => @tbl), "count DBUTIL tables");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info ({
    TABLE_CAT   => undef,
    TABLE_SCHEM => "DIRS",
    }), "table_info (undef, 'DIRS')");
ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
$n = 0;
$n++ while $sth->fetch;
is ($n, 0, "DIRS is a table, not a schema");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info ({ TABLE_NAME  => "DIRS" }), "table_info ({ TABLE_NAME => 'DIRS' })");
ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
$n = 0;
$n++ while $sth->fetch;
is ($n, 1,		"count DIRS tables");
is ($schema, "DBUTIL",	"table schema");
is ($type,   "T",	"table type");
is ($rw,     "W",	"table read only");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->table_info ({ TABLE_NAME => "DIRS", TABLE_TYPE => "T" }), "table_info ({ TABLE_NAME => 'DIRS', TABLE_TYPE => 'T' })");
ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
$n = 0;
$n++ while $sth->fetch;
is ($n, 1,		"count DIRS Tables");
ok ($sth->finish,	"finish");

ok (1, "-- link_info ()");
ok ($sth = DBD::Unify::db::link_info ($dbh), "::link_info (\$dbh)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info (), "\$dbh->link_info ()");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info ({
    TABLE_SCHEM => $ENV{USCHEMA}||"PUBLIC",
    TABLE_NAME  => "DIRS",
    TABLE_TYPE  => "T" }), "\$dbh->link_info (PUBLIC, DIRS, T)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info ({
    TABLE_SCHEM => undef,
    TABLE_NAME  => "XYZZY",
    TABLE_TYPE  => "T" }), "\$dbh->link_info (undef, XYZZY, T)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info (undef, "XYZZY", undef), "\$dbh->link_info (XYZZY,)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info (undef, undef, "XYZZY"), "\$dbh->link_info (,XYZZY)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info (undef, undef, "DIRS", "R"), "\$dbh->link_info (..., 'R')");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info (undef, undef, "DIRS", ""), "\$dbh->link_info (..., '')");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->link_info ({
    TABLE_CAT => "foo" }), "\$dbh->link_info ({ TABLE_CAT => \"foo\" })");
ok ($sth->finish,	"finish");

ok (1, "-- foreign_key_info ()");
ok ($sth = $dbh->foreign_key_info (undef, undef, undef, undef, undef, undef),
			"foreign_key_info (undef ...)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->foreign_key_info (undef, $ENV{USCHEMA}||"PUBLIC", undef,
				   undef, undef, undef),
			"foreign_key_info (SCHEMA, ...)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->foreign_key_info (undef, $ENV{USCHEMA}||"PUBLIC", undef,
				   undef, $ENV{USCHEMA}||"PUBLIC", undef),
			"foreign_key_info (SCHEMA, SCHEMA, ...)");
ok ($sth->finish,	"finish");
ok ($sth = $dbh->foreign_key_info (undef, $ENV{USCHEMA}||"PUBLIC", "foo",
				   undef, $ENV{USCHEMA}||"PUBLIC", "foo"),
			"foreign_key_info (SCHEMA.foo, SCHEMA.foo)");

ok ($sth->finish,	"finish");

ok (1, "-- primary_key");
is_deeply ([ $dbh->primary_key (undef, "DBUTIL", "DIRS") ],
			    [ "DIRID" ], "keys - single primary key");
is_deeply ([ $dbh->primary_key (undef, "DBUTIL", "ADEVLOCKS") ],
			    [ "OBJID", "OBJTYPE" ], "keys - composite key");

ok (1, "-- column_info");
ok ($sth = $dbh->column_info (undef, "DBUTIL", "DIRS", "DIRID"), "column_info (foo)");
is_deeply ($sth->fetchrow_arrayref, [
	undef, "DBUTIL", "DIRS",
	"DIRID", 2, "NUMERIC", 9, undef,
	0, undef, 0, undef, undef,
	undef, undef, undef, undef, undef, undef, undef, undef, undef,
	undef, undef, undef, undef, undef, undef, undef, undef, undef,
	undef, undef, undef, undef, undef,
	2, "NUMERIC", 10, 0, "N", "Y", "Y", "Y", "N" ], "fetch + content");
ok ($sth->finish,	"finish");

ok ($dbh->rollback,	"rollback");
ok ($dbh->disconnect,	"disconnect");

# Failure testing

$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
$dbh->{PrintWarn}  = 0;

undef  $sth;
eval { $sth = $dbh->table_info ([])};
is ($sth, undef, "table_info ([])");
is ($DBI::errstr, undef, "table_info ([]) has no DBI error message");
# DBI seems to catch this
like ($@, qr{^usage: table_info \(}, "table_info ([]) error message");
 
eval { $sth = $dbh->link_info  ([])};
is ($sth, undef, "link_info ([])");
is ($DBI::errstr, undef, "link_info ([]) has no DBI error message");
like ($@, qr{^usage: link_info \(}, "link_info ([]) error message");

# UNIFY does not support CAT
eval { $sth = $dbh->table_info ("foo", undef, undef, undef) };
is ($sth, undef, "table_info (\"foo\", undef, undef, undef)");
is ($DBI::errstr, undef, "table_info ([]) has no DBI error message");

ok   (1, "Test GetInfo functionality");
ok   ($dbh->get_info ( 7),			"SQL_DRIVER_VERSION");
is   ($dbh->get_info (17), "Unify DataServer",	"SQL_DBMS_NAME");
is   ($dbh->get_info (39), "Owner",		"SQL_SCHEMA_TERM");
like ($dbh->get_info (47), qr{^},		"SQL_USER_NAME");
like ($dbh->get_info ( 2), qr{^dbi:Unify:},	"SQL_DATA_SOURCE_NAME");
ok   (my $kw = $dbh->get_info (89),		"SQL_KEYWORDS");
like ($kw, qr{,BINARY,BTREE,},			"SQL_KEYWORDS");

ok   (1, "Test TypeInfo functionality");
ok   (my $tia = $dbh->type_info_all (),		"type_info_all ()");
is   (ref $tia,		"ARRAY",		"Array");
is   (ref $tia->[0],	"HASH",			"Hash");
is   (ref $tia->[1],	"ARRAY",		"Pseudo Hash");
ok   (exists $tia->[0]{DATA_TYPE},		"DATA_TYPE");

my %tia = map { $_->[0] => [ @$_ ] } @{$tia}[1 .. $#$tia];
ok   (exists $tia{CHAR},			"CHAR");
is   ($tia{AMOUNT}[$tia->[0]{CREATE_PARAMS}], "PRECISION,SCALE",
						"AMOUNT - PRECISION");
my $ti;
ok   ($ti = $dbh->type_info ( 1),		"type_info ( 1)");
is   ($ti->{TYPE_NAME}, "CHAR",			"CHAR");
ok   ($ti = $dbh->type_info ( 2),		"type_info ( 2)");
is   ($ti->{TYPE_NAME}, "NUMERIC",		"NUMERIC");
ok   ($ti = $dbh->type_info ( 5),		"type_info ( 5)");
is   ($ti->{TYPE_NAME}, "SMALLINT",		"SMALLINT");
ok   ($ti = $dbh->type_info ( 6),		"type_info ( 6)");
is   ($ti->{TYPE_NAME}, "FLOAT",		"FLOAT");
ok   ($ti = $dbh->type_info ( 7),		"type_info ( 7)");
is   ($ti->{TYPE_NAME}, "REAL",			"REAL");
ok   ($ti = $dbh->type_info ( 8),		"type_info ( 8)");
is   ($ti->{TYPE_NAME}, "DOUBLE PRECISION",	"DOUBLE PRECISION");
ok   ($ti = $dbh->type_info ( 9),		"type_info ( 9)");
is   ($ti->{TYPE_NAME}, "DATE",			"DATE");
ok   ($ti = $dbh->type_info (10),		"type_info (10)");
is   ($ti->{TYPE_NAME}, "TIME",			"TIME");
ok   ($ti = $dbh->type_info (11),		"type_info (11)");
is   ($ti->{TYPE_NAME}, "TIMESTAMP",		"TIMESTAMP");

ok   ($ti = $dbh->type_info (-1),		"type_info (-1)");
is   ($ti->{TYPE_NAME}, "TEXT",			"TEXT");
ok   ($ti = $dbh->type_info (-2),		"type_info (-2)");
is   ($ti->{TYPE_NAME}, "BINARY",		"BINARY");
ok   ($ti = $dbh->type_info (-5),		"type_info (-5)");
is   ($ti->{TYPE_NAME}, "HUGE INTEGER",		"HUGE INTEGER");

done_testing;
