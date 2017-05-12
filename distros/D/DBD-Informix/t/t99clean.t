#!/usr/bin/perl
#
#   @(#)$Id: t99clean.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Clean up DBD::Informix testing debris from the test databases
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

my($dbname, $dbuser, $dbpass) = ("","","");
foreach my $connector (\&primary_connection, \&secondary_connection, \&tertiary_connection)
{
    # Test connection
    my ($newname, $newuser, $newpass) = &$connector();
    if ($newname ne $dbname)
    {
        ($dbname, $dbuser, $dbpass) = ($newname, $newuser, $newpass);
        my $dbh = connect_controllably(1, { AutoCommit => 1, RaiseError => 0, PrintError => 0 }, $connector);
        cleanup_database($dbh);
        $dbh->disconnect ? stmt_ok : stmt_nok;
    }
}

my $n = stmt_counter;
print "1..$n\n";

all_ok();
