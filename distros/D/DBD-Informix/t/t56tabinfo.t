#!/usr/bin/perl
#
#   @(#)$Id: t56tabinfo.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test table_info
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

stmt_note("1..6\n");

my $dbh = connect_to_test_database();
stmt_ok;

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

my $sth = $dbh->table_info or stmt_fail;
stmt_ok;
my $tab = $sth->fetchall_arrayref or stmt_fail;
stmt_ok;

my $row;

my ($systab, $syscol, $tbcnt, $vwcnt, $sncnt) = (0, 0, 0, 0, 0);
my ($cnt) = 0;
foreach $row (@$tab)
{
    my ($pad, $n, $i) = ("# ", $#$row + 1, 0);
    for ($i = 0; $i < $n; $i++)
    {
        print $pad, (defined $$row[$i]) ? "<$$row[$i]>" : "NULL"; $pad = " :: ";
    }
    print " ::\n";
    $systab++ if ($$row[2] =~ /systables/i);
    $syscol++ if ($$row[2] =~ /syscolumns/i);
    $tbcnt++  if ($$row[2] =~ /$tbname/i);
    $vwcnt++  if ($$row[2] =~ /$vwname/i);
    $sncnt++  if ($$row[2] =~ /$pbname/i || $$row[2] =~ /$prname/i);
    $cnt++;
}

# Check multiple uses!
$sth = $dbh->table_info or stmt_fail;
$tab = $sth->fetchall_arrayref or stmt_fail;
my ($chk) = 0;
foreach $row (@$tab)
{
    $chk++;
}
stmt_fail unless $chk == $cnt;

# Clean up (dropping table drops views and synonyms!)
$dbh->do("DROP TABLE $tbname") or stmt_fail;
stmt_ok;

stmt_fail unless $systab == 1 && $syscol == 1 && $tbcnt == 1 && $vwcnt == 1 && $sncnt == $snexp;
stmt_fail unless $cnt > 10;
stmt_ok;

$dbh->disconnect or stmt_fail;

all_ok;
