#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use DBI qw(:sql_types);

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

{   my $sts;
    ok ($sts = $dbh->prepare (q;
	select COLCODE
	from   SYS.COLTYPE
	where  COLTYPE = 'FLOAT';
	), "prepare equal");
    ok ($sts->execute,	"execute equal");
    my ($colcode) = $sts->fetchrow_array;
    is ($colcode, 8,	"fetch equal");
    ok ($sts->finish,	"finish equal");
    }

#$dbh->{uni_verbose} = 999;
{   my $sts;
    ok ($sts = $dbh->prepare (q;
	select COLCODE
	from   SYS.COLTYPE
	where  COLTYPE like 'AMOU%';
	), "prepare like");
    ok ($sts->execute,	"execute like");
    my ($colcode) = $sts->fetchrow_array;
    is ($colcode, 4,	"fetch like");
    ok ($sts->finish,	"finish like");
    }

{   my $sts;
    ok ($sts = $dbh->prepare (q;
	select COLCODE
	from   SYS.COLTYPE
	where  COLTYPE reglike '^DOUB.*';
	), "prepare reglike");
    ok ($sts->execute,	"execute reglike");
    my ($colcode) = $sts->fetchrow_array;
    is ($colcode, 15,	"fetch reglike");
    ok ($sts->finish,	"finish reglike");
    }

SKIP: {
    my @sqlv = `SQL -version`;
    my ($rev) = ("@sqlv" =~ m/Revision:\s+(\d[.\d]*)/);
    $rev < 8.2 and skip "SHLIKE will dump core", 4;

    my $sts;
    ok ($sts = $dbh->prepare (q;
	select COLCODE
	from   SYS.COLTYPE
	where  COLTYPE shlike 'CHAR*';
	), "prepare shlike");
    ok ($sts->execute,	"execute shlike");
    my ($colcode) = $sts->fetchrow_array;
    is ($colcode, 5,	"fetch shlike");
    ok ($sts->finish,	"finish shlike");
    }

ok ($dbh->disconnect,	"disconnect");

done_testing;
