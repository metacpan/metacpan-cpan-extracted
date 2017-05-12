#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok ("DBI") }

{   my ($schema, $dbh) = ("DBUTIL");
    ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "connect 1");

    SKIP: {
	$dbh or skip "Cannot connect: $DBI::errstr", 7;

	my $sth;
	ok ( $sth = $dbh->prepare ("select * from DIRS"), "prepare 1");
	ok ( $sth->execute,	"execute 1");
	ok ( $sth->{Active},	"Active 1");
	ok ( $sth->finish,	"finish 1");
	ok (!$sth->{Active},	"!Active 1");
	ok ( $dbh->disconnect,	"disconnect 1"); # Should auto-destroy $sth;
	ok (!$dbh->ping,	"ping 1");
	}
    }

{   my ($schema, $dbh) = ("DBUTIL");
    ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "connect 2");

    SKIP: {
	$dbh or skip "Cannot connect again: $DBI::errstr", 7;

	my $sth;
	ok ( $sth = $dbh->prepare ("select * from DIRS"), "prepare 2");
	ok ( $sth->execute,	"execute 2");
	ok ( $sth->{Active},	"Active 2");
	ok ( $sth->finish,	"finish 2");
	ok (!$sth->{Active},	"!Active 2");
	ok ( $dbh->disconnect,	"disconnect 2"); # Should auto-destroy $sth;
	ok (!$dbh->ping,	"ping 2");
	}
    }

done_testing;
