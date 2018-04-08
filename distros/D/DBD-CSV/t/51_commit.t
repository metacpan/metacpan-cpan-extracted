#!/usr/bin/perl

# Check commit, rollback and "AutoCommit" attribute

use strict;
use warnings;
use Test::More;

BEGIN { use_ok ("DBI") }
do "./t/lib.pl";

my $nano = $ENV{DBI_SQL_NANO};
my @tbl_def = (
    [ "id",   "INTEGER",  4, 0 ],
    [ "name", "CHAR",    64, 0 ],
    );

sub RowCount {
    my ($dbh, $tbl) = @_;

    if ($nano) {
	diag ("SQL::Nano does not support count (*)");
	return 0;
	}

    local $dbh->{PrintError} = 1;
    my $sth = $dbh->prepare ("SELECT count (*) FROM $tbl") or return;
    $sth->execute or return;
    my $row = $sth->fetch or return;
    $row->[0];
    } # RowCount

ok (my $dbh = Connect (),			"connect");

ok (my $tbl = FindNewTable ($dbh),		"find new test table");

like (my $def = TableDefinition ($tbl, @tbl_def),
	qr{^create table $tbl}i,		"table definition");
ok ($dbh->do ($def),				"create table");

is ($dbh->{AutoCommit}, 1,			"AutoCommit on");

eval { $dbh->{AutoCommit} = 0; };
like ($@, qr{^Can't disable AutoCommit},	"disable");
is ($dbh->{AutoCommit}, 1,			"AutoCommit still on");

# Check whether AutoCommit mode works.
ok ($dbh->do ("insert into $tbl values (1, 'Jochen')"), "insert 1");
is (RowCount ($dbh, $tbl), $nano ? 0 : 1,	"1 row");

ok ($dbh->disconnect,				"disconnect");

ok ($dbh = Connect (),				"connect");
is (RowCount ($dbh, $tbl), $nano ? 0 : 1,	"still 1 row");

# Check whether commit issues a warning in AutoCommit mode
ok ($dbh->do ("insert into $tbl values (2, 'Tim')"), "insert 2");
is ($dbh->{AutoCommit}, 1,			"AutoCommit on");
{   my $got_warn = 0;
    local $SIG{__WARN__} = sub { $got_warn++; };
    eval { ok ($dbh->commit,			"commit"); };
    is ($got_warn, 1,				"warning");
    }

# Check whether rollback issues a warning in AutoCommit mode
# We accept error messages as being legal, because the DBI
# requirement of just issuing a warning seems scary.
ok ($dbh->do ("insert into $tbl values (3, 'Alligator')"), "insert 3");
is ($dbh->{AutoCommit}, 1,			"AutoCommit on");
{   my $got_warn = 0;
    local $SIG{__WARN__} = sub { $got_warn++; };
    eval { is ($dbh->rollback, 0,		"rollback"); };
    is ($got_warn, 1,				"warning");
    is ($dbh->err, undef,			"err");
    }

ok ($dbh->do ("drop table $tbl"),		"drop table");
ok ($dbh->disconnect,				"disconnect");

done_testing ();
