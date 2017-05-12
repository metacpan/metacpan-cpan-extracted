#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $UNIFY  = $ENV{UNIFY};

unless (exists $ENV{DBPATH} && -d $ENV{DBPATH} && -r "$ENV{DBPATH}/file.db") {
    warn "\$DBPATH not set";
    print "1..0\n";
    exit 0;
    }
my $dbname = "DBI:Unify:$ENV{DBPATH}";

use DBI;

my $dbh;
ok ($dbh = DBI->connect ($dbname, undef, "", {
	RaiseError    => 1,
	PrintError    => 1,
	AutoCommit    => 0,
	ChopBlanks    => 1,
	dbd_verbose   => 0,
	uni_scanlevel => 7,
	}), "connect with attributes");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

ok (1, "-- CREATE A TABLE");
ok ($dbh->do (join " " =>
    "create table xx (",
    "    xs numeric (4) not null,",
    "    xl numeric (9),",
    "    xc char    (5),",
    "    xf float",
    ")"), "create");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

ok (1, "-- FILL THE TABLE");
ok ($dbh->do ("insert into xx values (0, 123456789, 'abcde', 1.23)"), "insert 1234");
foreach my $v ( 1 .. 9 ) {
    ok ($dbh->do ("insert into xx values (?, ?, ?, ?)", undef,
	$v, $v * 100000, "$v", .99/$v), "insert $v with 3-arg do ()");
    }

my $error;
open my $eh, ">", \$error;
select ((select ($eh), $| = 1)[0]);
DBI->trace (0, $eh);
{   my $do_st = "update xx set xl = -1 where xs = ?";
    my $do_at = { dbd_verbose => 3 };
    my @do_bv = (99);

    my $sth;
    ok ($sth = $dbh->prepare ($do_st, $do_at), "prepare (..., attr)");
    like ($error, qr{update xx}, "dbd_verbose - prepare");
    SKIP: {
	$sth or skip "Prepare with attributes failed", 3;
	ok ($sth->execute (@do_bv), "execute");
	ok ($sth->finish, "finish");
	like ($error, qr{DBD::Unify::st_execute}, "dbd_verbose - execute");
	$sth->{dbd_verbose} = 0;
	}

    ok ($dbh->do ($do_st, $do_at, @do_bv), "do (.., attr, ...)");
    $dbh->{dbd_verbose} = 0;
    DBI->trace (0, *STDERR);
    close $eh;
    }

ok ($dbh->commit, "commit");

ok ($dbh->do ("drop table xx"), "Drop table");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");

done_testing;
