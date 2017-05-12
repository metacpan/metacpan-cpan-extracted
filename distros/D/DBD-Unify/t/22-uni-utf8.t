#!/usr/bin/perl -w

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
	uni_unicode   => 1,
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
    "    xc char (20),",
    "    xt text",
    ")"), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

my $t8 = "\x{0218}\x{0151}m\x{0119} \x{0165}\x{00e8}\x{1e8b}\x{1e71}";

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0, 'Some text', 'Some text')"));
foreach my $v ( 1 .. 5 ) {
    my $t = "x" x (1 << $v);
    ok ($dbh->do ("insert into xx values ($v, 'xxxx', '$t')"), "INS $v");
    }
ok (1, "-- FILL THE TABLE, POSITIONAL");
my $sth;
ok ($sth = $dbh->prepare ("insert into xx values (?,?,?)"), "ins prepare");
foreach my $v ( 6 .. 10 ) {
    ok ($sth->execute ($v, $t8, $t8 x ($v - 5)), "ins $v");
    }
ok ($sth->finish, "finish");
ok ($dbh->commit, "commit");

$" = ", ";
ok (1, "-- SELECT FROM THE TABLE");
my %result_ok = (
    0 => "0, 'Some text', 'Some text'",

    1 => "1, 'xxxx', 'xx'",
    2 => "2, 'xxxx', 'xxxx'",
    3 => "3, 'xxxx', 'xxxxxxxx'",
    4 => "4, 'xxxx', 'xxxxxxxxxxxxxxxx'",
    5 => "5, 'xxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'",
    );
ok ($sth = $dbh->prepare ("select * from xx where xs between 0 and 5"), "sel prepare");
ok ($sth->execute, "execute");
while (my ($xs, $xc, $xt) = $sth->fetchrow_array ()) {
    is ($result_ok{$xs}, "$xs, '$xc', '$xt'", "fetchrow_array $xs");
    }
ok ($sth->finish, "finish");

ok (1, "-- SELECT FROM THE TABLE, POSITIONAL");
ok ($sth = $dbh->prepare ("select xc, xt from xx where xs = ?"), "sel prepare");
foreach my $xs (1 .. 5) {
    ok ($sth->execute ($xs), "execute $xs");
    my ($xc, $xt) = $sth->fetchrow_array;
    is (1 << $xs, length ($xt), "Length val $xs");
    is ($xt, "x" x (1 << $xs), "fetch positional $xs");
    }
ok (1, "-- Check the bind_columns");
{   my ($xc, $xt) = ("", "");
    ok ($sth->bind_columns (\$xc, \$xt), "bind \$xt");
    ok ($sth->execute (3), "execute 3");
    ok ($sth->fetchrow_arrayref, "fetchrow_arrayref");
    is ($xt, "xxxxxxxx", "fetched");

    ok ($sth->execute (6), "execute 3");
    ok ($sth->fetch, "fetch");
    is ($xc, $t8, "char utf8");
    is ($xt, $t8, "text utf8");
    }
ok ($sth->finish, "finish");

ok ($dbh->do ("delete from xx"), "do delete");
ok ($dbh->commit, "commit");

ok (1, "-- DROP THE TABLE");
ok ($dbh->do ("drop table xx"), "do drop");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");

done_testing;
