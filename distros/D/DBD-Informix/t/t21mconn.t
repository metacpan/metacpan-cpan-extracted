#!/usr/bin/perl
#
#   @(#)$Id: t21mconn.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test Multiple Connections for DBD::Informix
#
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

my ($dbase1, $user1, $pass1) = primary_connection();
my ($dbase2, $user2, $pass2) = secondary_connection();

if (is_shared_memory_connection($dbase1) &&
    is_shared_memory_connection($dbase2))
{
    stmt_note("1..0 # Skip: Two shared memory connections - multi-connection test skipped\n");
    exit(0);
}

# Test connections...
stmt_note("# Connect to: $dbase1\n");
my ($dbh1) = DBI->connect("dbi:Informix:$dbase1", $user1, $pass1);
stmt_fail() unless defined $dbh1;

print "# Driver Information\n";
print "#     Name:                  $dbh1->{Driver}->{Name}\n";
print "#     Version:               $dbh1->{Driver}->{Version}\n";
print "#     Product:               $dbh1->{ix_ProductName}\n";
print "#     Product Version:       $dbh1->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $dbh1->{ix_MultipleConnections}\n";
print "# \n";

if ($dbh1->{ix_MultipleConnections} == 0)
{
    stmt_note("1..0 # Skip: multiple connections are not supported\n");
    all_ok();
}

stmt_note("1..22\n");
stmt_ok();

print_dbinfo($dbh1);
info_usertables($dbh1);

stmt_note("# Connect to: $dbase2\n");
my ($dbh2) = DBI->connect("DBI:Informix:$dbase2", $user2, $pass2);
stmt_fail() unless defined $dbh2;
stmt_ok();

print_dbinfo($dbh2);
info_usertables($dbh2);

# Demonstrate that previous database is still accessible...
info_usertables($dbh1);

my ($stmt1) =
    "SELECT TabName FROM 'informix'.SysTables" .
    " WHERE TabID >= 100 AND TabType = 'T'" .
    " ORDER BY TabName";

my ($stmt2) =
    "SELECT ColName, ColType FROM 'informix'.SysColumns" .
    " WHERE TabID = 1 ORDER BY ColName";

my ($st1, $st2);
stmt_fail() unless ($st1 = $dbh1->prepare($stmt1));
stmt_ok();
stmt_fail() unless ($st2 = $dbh2->prepare($stmt2));
stmt_ok();

stmt_fail() unless ($st1->execute);
stmt_ok();
stmt_fail() unless ($st2->execute);
stmt_ok();

my (@row1, $row2);

LOOP: while (1)
{
    # Yes, these are intentionally different!
    last LOOP unless (@row1 = $st1->fetchrow);
    last LOOP unless ($row2 = $st2->fetch);
    print "# 1: $row1[0]\n";
    print "# 2: ${$row2}[0]\n";
    print "# 2: ${$row2}[1]\n";
}

while (@row1 = $st1->fetchrow)
{
    print "# 1: $row1[0]\n";
}
stmt_fail() unless ($st1->finish);
stmt_ok();

while ($row2 = $st2->fetch)
{
    print "# 2: ${$row2}[0]\n";
    print "# 2: ${$row2}[1]\n";
}
stmt_fail() unless ($st2->finish);
stmt_ok();

stmt_note("# Testing: \$dbh1->disconnect()\n");
stmt_fail() unless ($dbh1->disconnect);
stmt_ok();

info_usertables($dbh2);

stmt_note("# Testing: \$dbh2->disconnect()\n");
stmt_fail() unless ($dbh2->disconnect);
stmt_ok();

all_ok();

sub info_usertables
{
    my ($dbh) = @_;
    my ($sth);
    my ($row);
    my (@row);
    my ($n);

    stmt_note("# Generate a list of user-defined tables\n");
    my ($stmt) =
        "SELECT TabName FROM 'informix'.SysTables" .
        " WHERE TabID >= 100 AND TabType = 'T'" .
        " ORDER BY TabName";
    stmt_fail() unless ($sth = $dbh->prepare($stmt));
    stmt_ok();
    stmt_fail() unless ($sth->execute());
    stmt_ok();
    $n = 0;
    while ($row = $sth->fetch())
    {
        @row = @{$row};
        print "# $n: $row[0]\n";
        $n++;
    }
    stmt_fail() unless ($sth->finish());
    stmt_ok();
}
