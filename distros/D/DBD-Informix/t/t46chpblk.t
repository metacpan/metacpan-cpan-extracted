#!/usr/bin/perl
#
#   @(#)$Id: t46chpblk.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   ChopBlanks attribute test script for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my $tabname = "dbd_ix_chbl_01";

my $dbh = connect_to_test_database();
print "# OnLine - will test VARCHAR data types\n"
    if ($dbh->{ix_InformixOnLine});
print "# SE - no testing for VARCHAR data types\n"
    unless ($dbh->{ix_InformixOnLine});
my $subtests = 5;
my $comtests = 2;
my $multiplier = 2;
$multiplier = 4 if ($dbh->{ix_InformixOnLine});
my $ntests = $subtests * $multiplier + $comtests;
stmt_note("1..$ntests\n");
stmt_ok(0);

# Expected results (data loaded from @expect_vc in each case)
# @expect_vc -- VARCHAR (either way)
# @expect_ct -- CHAR with trailing blanks
# @expect_cn -- CHAR without trailing blanks
my @expect_vc = ( "ABC", "ABC   ", "ABCDEFGHIJ" );
my @expect_ct = ( "ABC       ", "ABC       ", "ABCDEFGHIJ" );
my @expect_cn = ( "ABC", "ABC", "ABCDEFGHIJ" );

sub test_trailing_blanks
{
    my ($type, @expect) = @_;
    my ($i) = 1;
    my ($ref, @row, $sth);

    stmt_note("# Testing $type - ChopBlanks set to $dbh->{ChopBlanks}\n");
    stmt_fail() unless $dbh->do(qq%
        CREATE TEMP TABLE $tabname
        (
            Col01 INTEGER NOT NULL,
            Col02 $type(10) NOT NULL
        )
        %);
    my $ins;
    stmt_fail() unless $ins = $dbh->prepare(qq%
        INSERT INTO $tabname VALUES(?, ?)
        %);
    for ($i = 0; $i < @expect_vc; $i++)
    {
        stmt_fail() unless $ins->execute($i+1, $expect_vc[$i]);
    }
    stmt_fail() unless $ins->finish();
    stmt_ok();

    stmt_fail() unless $sth = $dbh->prepare(qq%
        SELECT Col01, Col02 FROM $tabname ORDER BY Col01
        %);
    stmt_fail() unless $sth->execute();;
    $i = 0;
    while ($ref = $sth->fetch())
    {
        @row = @{$ref};
        stmt_note("# Actual $row[0] <<$row[1]>>\n");
        my($k) = $i + 1;
        stmt_note("# Expect $k <<$expect[$i]>>\n");
        stmt_fail() if ($row[0] != $k || $row[1] ne $expect[$i]);
        stmt_ok();
        $i++;
    }
    stmt_fail() unless $sth->finish();
    undef $sth;
    stmt_fail() unless $dbh->do("DROP TABLE $tabname");
    stmt_ok();
}

stmt_note("# ChopBlanks set to $dbh->{ChopBlanks} at startup\n");

$dbh->{ChopBlanks} = 0;     # Preserve trailing blanks!
test_trailing_blanks("CHAR   ", @expect_ct);
test_trailing_blanks("VARCHAR", @expect_vc) if ($dbh->{ix_InformixOnLine});

$dbh->{ChopBlanks} = 1;     # Chop trailing blanks!
test_trailing_blanks("CHAR   ", @expect_cn);
test_trailing_blanks("VARCHAR", @expect_vc) if ($dbh->{ix_InformixOnLine});

stmt_fail() unless ($dbh->disconnect);
stmt_ok();

all_ok;
