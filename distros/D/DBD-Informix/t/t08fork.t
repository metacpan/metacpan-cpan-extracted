#!/usr/bin/perl
#
#   @(#)$Id: t08fork.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Ensure that child processes cannot use parental database handles
#
#   Copyright 2003-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

$| = 1;
stmt_note("1..2\n");
my $dbh = connect_to_test_database({PrintError => 0});
stmt_ok;
my $sql = 'SELECT tabid FROM "informix".systables WHERE tabid = 1';

my $pid = fork;

if ($pid)
{
    # Parent - should be OK
    # MacOS X - has to set some sort of handler for SIGCHLD
    $SIG{CHLD} = sub { return; };
    wait;   # Wait for child to die!
    my $rc = $?;
    stmt_note "# Parent detected child status $rc\n";
    stmt_fail unless ($rc == 0);
    my $sth = $dbh->prepare($sql) or stmt_fail;
    stmt_ok;
}
else
{
    # Child - should be unable to use $dbh
    my $sth = $dbh->prepare($sql);
    stmt_fail if defined($sth);
    stmt_fail unless $DBI::err == -746;
    stmt_fail unless $DBI::errstr =~ m/child process cannot use database handle created in parent/i;
    stmt_note "# Child detected correct error status in \$DBI::err and \$DBI::errstr\n";
    exit(0);
}

all_ok();

