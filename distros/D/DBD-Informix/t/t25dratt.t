#!/usr/bin/perl
#
#   @(#)$Id: t25dratt.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Driver Attribute test script for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

stmt_note("1..4\n");

# Test install...
# NB: Do not use DBI->install_driver in your code.
# Use: DBI->connect() instead.
stmt_note("# Testing: DBI->install_driver('Informix')\n");
my $drh = DBI->install_driver('Informix');
stmt_ok(0);

print "# DBI Information\n";
print "#     Version:               $DBI::VERSION\n";
print "# Driver Information\n";
print "#     Type:                  $drh->{Type}\n";
print "#     Name:                  $drh->{Name}\n";
print "#     Version:               $drh->{Version}\n";
print "#     Attribution:           $drh->{Attribution}\n";
print "#     Product:               $drh->{ix_ProductName}\n";
print "#     Product Version:       $drh->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $drh->{ix_MultipleConnections}\n";
print "#     Active Connections:    $drh->{ix_ActiveConnections}\n";
print "#     Current Connection:    $drh->{ix_CurrentConnection}\n";
print "# \n";

stmt_fail() unless $drh->{ix_ActiveConnections} == 0;
stmt_ok();

my $dbh = connect_to_test_database();

print "#     Multiple Connections:  $drh->{ix_MultipleConnections}\n";
print "#     Active Connections:    $drh->{ix_ActiveConnections}\n";
print "#     Current Connection:    $drh->{ix_CurrentConnection}\n";
print "#     Current Database:      $dbh->{Name}\n";

stmt_fail() unless $drh->{ix_ActiveConnections} == 1;
stmt_ok();

stmt_note("# Testing: \$dbh->disconnect()\n");
stmt_fail() unless ($dbh->disconnect);

print "#     Multiple Connections:  $drh->{ix_MultipleConnections}\n";
print "#     Active Connections:    $drh->{ix_ActiveConnections}\n";
print "#     Current Connection:    $drh->{ix_CurrentConnection}\n";

stmt_fail() unless $drh->{ix_ActiveConnections} == 0;
stmt_ok();

all_ok;
