#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Test if all of the documented DBI API is implemented and working OK

BEGIN { use_ok ("DBI") }

# =============================================================================

my ($schema, $dbh) = ("DBUTIL");
ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "connect");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

# =============================================================================

# Attributes common to all handles

my $sth;

ok ( $sth = $dbh->prepare ("select * from DIRS"), "prepare");
is ( $dbh->{Kids},	 1,	"Kids");
ok ( $sth->{Warn},		"Warn");
ok (!$sth->{Active},		"Active");
is ( $dbh->{ActiveKids}, 0,	"ActiveKids");
ok ( $sth->execute,		"execute");
ok ( $sth->{Active},		"Active 2");
is ( $dbh->{ActiveKids}, 1,	"ActiveKids 2");
ok ( $sth->finish,		"finish");
ok (!$sth->{Active},		"Active 3");
is ( $sth->{Kids},	 0,	"Kids 3");
    # Docs do /not/ define what Kids should return
    # for a statement handle (same for ActiveKids,
    # and CachedKids)
ok (!$sth->{CompatMode},	"CompatMode");

# =============================================================================

ok ( $dbh->disconnect,		"disconnect");

done_testing;
