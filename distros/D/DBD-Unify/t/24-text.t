#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DBI qw(:sql_types);

my $UNIFY  = $ENV{UNIFY};
unless (exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db") {
    warn "\$DBPATH not set";
    print "1..0\n";
    exit 0;
    }
my $dbname = "DBI:Unify:$ENV{DBPATH}";

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
    "    xt text",
    ")"), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0, 'Some text')"));
foreach my $v ( 1 .. 5 ) {
    my $t = "x" x (1 << $v);
    ok ($dbh->do ("insert into xx values ($v, '$t')"), "INS $v");
    }
ok (1, "-- FILL THE TABLE, POSITIONAL");
my $sth;
ok ($sth = $dbh->prepare ("insert into xx values (?,?)"), "ins prepare");
foreach my $v ( 6 .. 10 ) {
    my $t = "x" x (1 << $v);
    ok ($sth->execute ($v, $t), "ins $v");
    }
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

$" = ", ";
ok (1, "-- SELECT FROM THE TABLE");
my %result_ok = (
    0 => "0, 'Some text'",

    1 => "1, 'xx'",
    2 => "2, 'xxxx'",
    3 => "3, 'xxxxxxxx'",
    4 => "4, 'xxxxxxxxxxxxxxxx'",
    5 => "5, 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'",
    );
ok ($sth = $dbh->prepare ("select * from xx where xs between 0 and 5"), "sel prepare");
ok (1, "-- Check the internals");
{   local $" = ":";
    my %attr = (
	NAME      => "xs:xt",
	uni_type  => "5:-9",
	TYPE      => "5:-1",
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
while (my ($xs, $xt) = $sth->fetchrow_array ()) {
    is ($result_ok{$xs}, "$xs, '$xt'", "fetchrow_array $xs");
    }
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("select xt from xx where xs = ?"), "sel prepare");
foreach my $xs (1 .. 10) {
    ok ($sth->execute ($xs), "execute $xs");
    my ($xt) = $sth->fetchrow_array;
    is (1 << $xs, length ($xt), "Length val $xs");
    is ($xt, "x" x (1 << $xs), "fetch positional $xs");
    }
ok (1, "-- Check the bind_columns");
{   my $xt = "";
    ok ($sth->bind_columns (\$xt), "bind \$xt");
    ok ($sth->execute (3), "execute 3");
    ok ($sth->fetchrow_arrayref, "fetchrow_arrayref");
    is ($xt, "xxxxxxxx", "fetched");
    }
ok ($sth->finish, "finish");

{   my ($r, $xt);
    $r .= chr int rand 256 for 0 .. 132_000;
    ok ($r, "128k+ random data");
    ok ($sth = $dbh->prepare ("update xx set xt = ? where xs = 3"), "prepare update");
    ok ($sth->execute ($r), "execute update");
    ok ($sth->finish, "finish update");
    ok ($sth = $dbh->prepare ("select xt from xx where xs = ?"), "prepare select");
    ok ($sth->execute (3), "execute select");
    ok (($xt) = $sth->fetchrow_array (), "fetch random data");
    is (length ($xt), length ($r), "length");
    is ($xt, $r, "Data");
    ok ($sth->finish, "finish select");
    ok ($sth->execute (3), "execute select 2");
    undef $xt;
    ok ($sth->bind_columns (\$xt), "bind_columns");
    ok ($sth->fetch, "fetch random data to bound column");
    is (length ($xt), length ($r), "length");
    is ($xt, $r, "Data");
    ok ($sth->finish, "finish select");
    }

ok ($dbh->do ("delete xx"), "do delete");
ok ($dbh->commit, "commit");

ok (1, "-- DROP THE TABLE");
ok ($dbh->do ("drop table xx"), "do drop");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");

done_testing;
