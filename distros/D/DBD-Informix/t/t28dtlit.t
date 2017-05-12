#!/usr/bin/perl
#
#   @(#)$Id: t28dtlit.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test for handling DATETIME literals in SQL statements
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler
#
# Note that DBD::Informix used to mangle a time such as '12:30:23' to '12??'
# because dbd_ix_preparse() would treat the :30 as a positional parameter
# (in a misguided attempt to accommodate Oracle scripts).

use DBD::Informix::TestHarness;
use strict;
use warnings;

print("1..10\n");

my $dbh = connect_to_test_database();
stmt_ok;

print "# DBI Information\n";
print "#     Version:               $DBI::VERSION\n";
print "# Generic Driver Information\n";
print "#     Type:                  $dbh->{Driver}->{Type}\n";
print "#     Name:                  $dbh->{Driver}->{Name}\n";
print "#     Version:               $dbh->{Driver}->{Version}\n";
print "#     Attribution:           $dbh->{Driver}->{Attribution}\n";
print "# Informix Driver Information\n";
print "#     Product:               $dbh->{ix_ProductName}\n";
print "#     Product Version:       $dbh->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $dbh->{ix_MultipleConnections}\n";
print "#     Active Connections:    $dbh->{ix_ActiveConnections}\n";
print "#     Current Connection:    $dbh->{ix_CurrentConnection}\n";
print "# \n";

my $tablename = "dbd_ix_test3";

my $stmt1 = qq{
CREATE TEMP TABLE $tablename
(
    id1     INTEGER,
    id2     DATETIME YEAR TO SECOND,
    id3     INTERVAL HOUR(6) TO FRACTION(3)
)
};
$stmt1 =~ s/\s+/ /gm;
stmt_test($dbh, $stmt1, 0);

stmt_test($dbh, qq"INSERT INTO $tablename VALUES(1122,
                 DATETIME(1998-03-05 09:11:46) YEAR TO SECOND,
                 INTERVAL(23:59:59.999) HOUR(6) TO FRACTION(3))");
stmt_test($dbh, qq"INSERT INTO $tablename VALUES(1001002002,
                 DATETIME(2000-02-29 23:59:59) YEAR TO SECOND,
                 INTERVAL(-2223:09:50.630) HOUR(6) TO FRACTION(3))");

my $stmt2 = qq"SELECT id1, id2, id3 FROM $tablename
    WHERE id2 > DATETIME(1970-01-01 00:00:00) YEAR TO SECOND
      AND id3 > INTERVAL(-10000:00:00.000) HOUR(6) TO FRACTION(3)";
stmt_note("# Testing: prepare('$stmt2')\n");
my $sth = $dbh->prepare($stmt2);
stmt_fail() unless (defined $sth);
stmt_ok(0);

stmt_fail() unless $sth->execute;
stmt_ok(0);

my ($id1, $id2, $id3);
while (($id1, $id2, $id3) = $sth->fetchrow)
{
    stmt_ok(0);
    stmt_note("# Row: $id1\t$id2\t$id3\n");
}

stmt_fail() unless $sth->finish;
stmt_ok(0);
undef $sth;

stmt_fail() unless $dbh->disconnect;
stmt_ok(0);
all_ok();
