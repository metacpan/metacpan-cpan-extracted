#!/usr/bin/perl
#
#   @(#)$Id: t32nulls.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test Null Handling for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test install...
my $dbh = connect_to_test_database();

if ($dbh->{ix_ServerVersion} < 730)
{
    stmt_note "1..0 # Skip: test fails on servers earlier than 7.30\n";
    exit 0;
}

stmt_note("1..7\n");
stmt_ok();
my $table = "dbd_ix_nulls02";

stmt_test $dbh, "CREATE TEMP TABLE $table(a CHAR(10), b CHAR(10))";

my $sth;
stmt_fail unless
    $sth=$dbh->prepare("INSERT INTO $table(a,b) VALUES (?,?)");
stmt_ok;

my $var1="";
my $var2=1;
print "# var1 = <<$var1>>, ", (defined $var1) + 0, "\n";
print "# var2 = <<$var2>>, ", (defined $var2) + 0, "\n";
stmt_fail unless $sth->execute($var1,$var2);
stmt_ok;

undef $var1;
$var2=2;
print "# var1 = undefined, ", (defined $var1) + 0, "\n";
print "# var2 = <<$var2>>, ", (defined $var2) + 0, "\n";
stmt_fail unless $sth->execute($var1,$var2);
stmt_ok;

my $sel;
my @row;
my $select = "select count(*) from $table ";
stmt_fail unless $sel = $dbh->prepare($select);
stmt_fail unless $sel->execute();
stmt_fail unless (@row = $sel->fetchrow);
print "# TOTAL: ", $row[0], "\n";
stmt_fail "# Incorrect row count (got $row[0], expected 2)\n"
          unless $row[0] == 2;
stmt_fail unless $sel->finish;
undef $sel;
stmt_ok;

$select .=  "where a is null";
stmt_fail unless $sel = $dbh->prepare($select);
stmt_fail unless $sel->execute();
stmt_fail unless (@row = $sel->fetchrow);
print "# NULLS: ", $row[0], "\n";
stmt_fail "# Incorrect row count (got $row[0], expected 1)\n"
          unless $row[0] == 1;
stmt_fail unless $sel->finish;
undef $sel;
stmt_ok;

all_ok();
