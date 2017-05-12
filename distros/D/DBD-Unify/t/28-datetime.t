#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DBI qw(:sql_types);

my $UNIFY  = $ENV{UNIFY};
exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db" or
    plan skip_all => "\$DBPATH not set";
my $dbname = "DBI:Unify:$ENV{DBPATH}";

my @sqlv = `SQL -version`;
my ($rev) = ("@sqlv" =~ m/Revision:\s+(\d[.\d]*)/);
$rev < 9.1 and plan skip_all => "DATETIME added in 9.1 (this is just $rev)";

my $dbh;
ok ($dbh = DBI->connect ($dbname, undef, "", {
    RaiseError    => 1,
    PrintError    => 1,
    AutoCommit    => 0,
    ChopBlanks    => 1,
    uni_verbose   => 0,
    uni_scanlevel => 7,
    }), "connect with attributes");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

ok (1, "-- CREATE THE TABLE");
ok ($dbh->do (join " " =>
    "create table xx (",
    "    xs numeric       (4) not null,",
    "    xdt datetime",
    ")"), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0, 02/05/2012)"));
foreach my $v ( 1 .. 5 ) {
    my $dt = "2012-02-05 12:20:30.00$v";
    ok ($dbh->do ("insert into xx values ($v, '$dt')"), "INS $v");
    }
ok (1, "-- FILL THE TABLE, POSITIONAL");
my $sth;
ok ($sth = $dbh->prepare ("insert into xx values (?,?)"), "ins prepare");
foreach my $v ( 6 .. 10 ) {
    my $dt = sprintf("2012-02-%02d 12:20:30.000", $v);
    ok ($sth->execute ($v, $dt), "ins $v");
    }
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

$" = ", ";
ok (1, "-- SELECT FROM THE TABLE");
my %result_ok = (
    0 => "0, '2012-02-05 00:00:00.000'",
    1 => "1, '2012-02-05 12:20:30.001'",
    2 => "2, '2012-02-05 12:20:30.002'",
    3 => "3, '2012-02-05 12:20:30.003'",
    4 => "4, '2012-02-05 12:20:30.004'",
    5 => "5, '2012-02-05 12:20:30.005'",
    6 => "6, '2012-02-06 12:20:30.000'",
    7 => "7, '2012-02-07 12:20:30.000'",
    8 => "8, '2012-02-08 12:20:30.000'",
    9 => "9, '2012-02-09 12:20:30.000'",
    10 => "10, '2012-02-10 12:20:30.000'",
    );
ok ($sth = $dbh->prepare ("select * from xx where xs between 0 and 5"), "sel prepare");
ok (1, "-- Check the internals");
{   local $" = ":";
    my %attr = (
    NAME      => "xs:xdt",
    uni_type  => "5:-19",
    TYPE      => "5:11",
    PRECISION => "4:0",
    SCALE     => "0:0",
    NULLABLE  => "0:1",	# Does not work in Unify (yet)
    );
    foreach my $attr (qw(NAME uni_type TYPE PRECISION SCALE)) {
	#printf STDERR "\n%-20s %s\n", $attr, "@{$sth->{$attr}}";
	is ("@{$sth->{$attr}}", $attr{$attr}, "attr $attr");
    }
    }
ok ($sth->execute, "execute");
while (my ($xs, $xdt) = $sth->fetchrow_array ()) {
    is ($result_ok{$xs}, "$xs, '$xdt'", "fetchrow_array $xs");
    }
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("select xdt from xx where xs = ?"), "sel prepare");
foreach my $xs (1 .. 10) {
    ok ($sth->execute ($xs), "execute $xs");
    my ($xdt) = $sth->fetchrow_array;
    is (length ($xdt), 23, "Length val $xs");
    is ($result_ok{$xs}, "$xs, '$xdt'", "fetch positional $xs");
    }
ok (1, "-- Check the bind_columns");
{   my $xdt = "";
    ok ($sth->bind_columns (\$xdt), "bind \$x.t");
    ok ($sth->execute (3), "execute 3");
    ok ($sth->fetchrow_arrayref, "fetchrow_arrayref");
    is ($xdt, "2012-02-05 12:20:30.003", "fetched");
    }
ok ($sth->finish, "finish");

ok ($dbh->do ("delete xx"), "do delete");
ok ($dbh->commit, "commit");

ok (1, "-- DROP THE TABLE");
ok ($dbh->do ("drop table xx"), "do drop");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");

done_testing;
