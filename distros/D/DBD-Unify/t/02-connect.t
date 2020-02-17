#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok ("DBI") };

my ($schema, $dbh) = ("DBUTIL");

ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "Connect");

$dbh or BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");

my $sth = $dbh->prepare ("select * from DIRS");
ok ($sth->execute,	"execute");
ok ($sth->{Active},	"sth attr Active");
$sth->finish;
ok (!$sth->{Active},	"sth attr not Active");
$dbh->disconnect;	# Should auto-destroy $sth;
ok (!$dbh->ping,	"disconnected");

if ($ENV{DBD_TEST_HANDLE_EXHAUSTION}) {
    foreach my $dbhc (0 .. 99999) {
	$dbh = DBI->connect ("dbi:Unify:", "", $schema);
	unless ($dbhc) { # Test only once
	    my $sth = $dbh->prepare ("select * from DIRS");
	    is ($sth->{CursorName}, "c_sql_00001_000001", "Cursor name");
	    $sth->finish;
	    }
	$dbh->disconnect;
	}
    ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "Connect");
    $dbh->{PrintWarn} = 0;
    ok (!$dbh->prepare ("select * from DIRS"),	"Ran out of DBH ID's");
    is ($DBI::errstr, "Cannot use DBH ID",	"Ran out of DBH ID's");
    $dbh->disconnect;
    }
else {
    diag ("Set \$DBD_TEST_HANDLE_EXHAUSTION=1 for DBH exhaustion");
    }

{   local $SIG{__WARN__} = sub {};
    $ENV{UNIFY} = undef;
    ok (!DBI->connect ("dbi:Unify:", "", $schema), "Connect \$UNIFY undef");
    $ENV{UNIFY} = "";
    ok (!DBI->connect ("dbi:Unify:", "", $schema), "Connect \$UNIFY ''");
    $ENV{UNIFY} = "/dev/null";
    ok (!DBI->connect ("dbi:Unify:", "", $schema), "Connect \$UNIFY '/dev/null'");
    }

done_testing;
