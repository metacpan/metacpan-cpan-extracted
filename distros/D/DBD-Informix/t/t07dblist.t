#!/usr/bin/perl
#
#   @(#)$Id: t07dblist.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   List of available databases:
#   @ary = $DBI->data_sources('Informix');
#
#   Copyright 1996    Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2007-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my @ary = DBI->data_sources('Informix');

if (!@ary)
{
    if ($ENV{DBD_INFORMIX_USERNAME} && $ENV{DBD_INFORMIX_PASSWORD} && ($DBI::err == -951 || $DBI::err == -956))
    {
        # Problem is with default connection and sqgetdbs().
        # -951  User username is not known on the database server.
        # -956  Client client-name or user is not trusted by the database server.
        # There could be other errors which should cause test to be skipped.
        print "1..0 # Skip: DBI->data_sources('Informix') because of username/password\n";
    }
    else
    {
        print "1..1\n";
        stmt_note("# Test: DBI->data_sources('Informix'): failed\n");
        stmt_fail();
    }
}
else
{
    my $flag = (defined $ENV{INFORMIXSERVER} && $ENV{INFORMIXSERVER} ne "") ? 1 : 0;
    my $x = @ary;
    my $y = $x + 1;
    print "1..$y\n";
    # Note that there is not very much we can do to validate database list.
    # Remember SE: not even sysmaster is reliable there (but there is a test DB).
    # And OnLine 5.x does not play with INFORMIXSERVER!
    stmt_note("# Test: DBI->data_sources('Informix'):\n");
    stmt_fail("# *** No databases to list? ***\n") if ($#ary < 0);
    my $srv = 0;
    foreach my $db (@ary)
    {
        stmt_note("# Database: $db\n");
        ($db =~ /^dbi:Informix:/) ? stmt_ok(0) : stmt_fail();
        $srv++ if ($flag && $db =~ /\@$ENV{INFORMIXSERVER}$/o);
    }
    stmt_fail("# No databases match INFORMIXSERVER=$ENV{INFORMIXSERVER}\n")
        if ($srv == 0 && $flag);
    stmt_ok();
}

all_ok();
