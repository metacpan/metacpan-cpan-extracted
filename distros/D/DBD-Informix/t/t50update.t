#!/usr/bin/perl
#
#   @(#)$Id: t50update.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test for UPDATE on zero rows in MODE ANSI database.
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2005-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my $dbh = connect_to_test_database;

if (!$dbh->{ix_ModeAnsiDatabase})
{
    stmt_note("1..0 # Skip: MODE ANSI test - database '$dbh->{Name}' is not MODE ANSI\n");
    $dbh->disconnect;
    exit(0);
}

stmt_note("1..7\n");
stmt_ok;

my $table = "dbd_ix_empty";
my $selver = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabID = 1";

my $result = { 'systables' => { 'owner' => 'informix', 'tabname' => 'systables' } };

$dbh->{PrintError} = 1;
$dbh->{ChopBlanks} = 1;
my $sth = $dbh->prepare($selver) or stmt_fail;
stmt_ok;
$sth->execute ? validate_unordered_unique_data($sth, 'tabname', $result) : stmt_nok;

stmt_test($dbh, "create table dbd_ix_empty (col integer not null)");
stmt_test($dbh, "update dbd_ix_empty set col = col * 2 where 1 = 0");
stmt_fail unless $dbh->{ix_sqlcode} == 100;
print_sqlca($dbh);
stmt_test($dbh, "rollback work");
stmt_note("# Disconnect\n");
$dbh->disconnect ? stmt_ok : stmt_fail;

all_ok();
