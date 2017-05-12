#!/usr/bin/perl
#
#   @(#)$Id: t05dbase.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test database creation and default connections.
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2005-14 Jonathan Leffler
#
# Note that database statements cannot be used with an explicit connection
# with ESQL/C 6.0x and up.

use DBD::Informix::TestHarness;
use strict;
use warnings;

if (defined $ENV{DBD_INFORMIX_NO_DBCREATE} && $ENV{DBD_INFORMIX_NO_DBCREATE})
{
    stmt_note "1..0 # Skip: requires database create permission but DBD_INFORMIX_NO_DBCREATE set.\n";
    exit 0;
}

my ($dbname) = "dbd_ix_db";
my ($user) = $ENV{DBD_INFORMIX_USERNAME};
my ($pass) = $ENV{DBD_INFORMIX_PASSWORD};

stmt_note("1..13\n");

# Do not want these defaults to affect testing (in this file only).
delete $ENV{DBI_DSN};
delete $ENV{DBI_DBNAME};

my $dbh;
my $selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabId = 1";
my $expect = { 'systables' => { 'tabname' => 'systables', 'owner' => 'informix' } };
my $sth;

stmt_note("# Test (explicit default) DBI->connect('dbi:Informix:.DEFAULT.',...)\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));
stmt_ok;
$dbh->{ChopBlanks} = 1;
$dbh->{PrintError} = 1;
stmt_test($dbh, "create database $dbname");

$sth = $dbh->prepare($selver);
$sth->execute;
validate_unordered_unique_data($sth, 'tabname', $expect);

stmt_test($dbh, "close database");
stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

# Test disconnecting implicit connections (B42204)
stmt_note("# Retest disconnect of (explicit default) DBI->connect('dbi:Informix:.DEFAULT.',...)\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));
stmt_ok;
$dbh->{ChopBlanks} = 1;
$dbh->{PrintError} = 1;
stmt_test($dbh, "create database $dbname");

$sth = $dbh->prepare($selver);
$sth->execute;
validate_unordered_unique_data($sth, 'tabname', $expect);
stmt_note("# Test disconnect on DEFAULT connection\n");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

# Clean up test database
stmt_note("# Clean up test database\n");
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));
stmt_ok;
stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

all_ok();
