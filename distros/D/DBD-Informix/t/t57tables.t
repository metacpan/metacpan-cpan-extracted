#!/usr/bin/perl
#
#   @(#)$Id: t57tables.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test tables
#
#   Copyright 1999    Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2005-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

if (defined $ENV{DBD_INFORMIX_NO_RESOURCE} && $ENV{DBD_INFORMIX_NO_RESOURCE})
{
    stmt_note "1..0 # Skip: requires RESOURCE privileges but DBD_INFORMIX_NO_RESOURCE set.\n";
    exit 0;
}

stmt_note("1..5\n");

my $dbh = connect_to_test_database();
stmt_ok;

$dbh->{PrintError} = 1;

cleanup_database($dbh);

# How do you verify the table list?
# With difficulty, since there are different numbers of system tables
# in different versions of Informix, and you don't know what's in the
# user-defined portion of the database.  So, create our own table, view,
# synonym, etc, and check that SysTables and SysColumns turn up in the list.

my ($tbname) = "dbd_ix_table";
$dbh->do("CREATE TABLE $tbname (col01 CHAR(10), col02 CHAR(20))") or stmt_fail;
my ($vwname) = "dbd_ix_view";
$dbh->do("CREATE VIEW $vwname AS SELECT Col01 FROM $tbname") or stmt_fail;
my ($pbname) = "dbd_ix_pubsyn";
$dbh->do("CREATE SYNONYM $pbname FOR $vwname") or stmt_fail;
my ($prname) = "dbd_ix_prvsyn";
my ($snexp) = 1;
if ($dbh->{ix_ModeAnsiDatabase} == 0)
{
    $dbh->do("CREATE PRIVATE SYNONYM $prname FOR $tbname") or stmt_fail;
    $snexp++;
}
stmt_ok;

my @tables = $dbh->tables or stmt_fail;
stmt_ok;

my ($systab, $syscol, $tbcnt, $vwcnt, $sncnt) = (0, 0, 0, 0, 0);
foreach my $table (@tables)
{
    print "# $table\n";
    $systab++ if ($table =~ /systables/i);
    $syscol++ if ($table =~ /syscolumns/i);
    $tbcnt++  if ($table =~ /$tbname/i);
    $vwcnt++  if ($table =~ /$vwname/i);
    $sncnt++  if ($table =~ /$pbname/i || $table =~ /$prname/i);
}
my($cnt) = $#tables + 1;

# Check multiple uses!
@tables = $dbh->tables or stmt_fail;
# Could get spurious failure if someone else creates or drops a table while this tests runs
stmt_fail unless $#tables + 1 == $cnt;

# Clean up (dropping table drops views and synonyms!)
$dbh->do("DROP TABLE $tbname") or stmt_fail;
stmt_ok;

unless ($systab == 1 && $syscol == 1 && $tbcnt == 1 && $vwcnt == 1 && $sncnt == $snexp)
{
stmt_note("# Unexpected number of systables ($systab vs 1)\n") unless $systab == 1;
stmt_note("# Unexpected number of syscolumns ($syscol vs 1)\n") unless $syscol == 1;
stmt_note("# Unexpected number of $tbname ($tbcnt vs 1)\n") unless $tbcnt == 1;
stmt_note("# Unexpected number of $vwname ($vwcnt vs 1)\n") unless $vwcnt == 1;
stmt_note("# Unexpected number of synonyms ($sncnt vs $snexp)\n") unless $sncnt == $snexp;
stmt_fail("Unexpected number of tables in database.\n");
}
stmt_fail unless $cnt > 10;
stmt_ok;

$dbh->disconnect or stmt_fail;

all_ok;

