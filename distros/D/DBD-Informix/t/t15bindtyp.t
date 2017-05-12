#!/usr/bin/perl
#
#   @(#)$Id: t15bindtyp.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test handling of bind_param with type attributes for DBD::Informix
#
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBI qw(:sql_types);
use DBD::Informix qw(:ix_types);
use DBD::Informix::TestHarness;

# Test install...
my ($dbh) = connect_to_test_database;

my ($ntests) = 8;
if ($dbh->{ix_BlobSupport})
{
    # XPS 8.[012]x does not support blobs.
    $ntests = 17;
}
stmt_note "1..$ntests\n";

stmt_ok;
my ($table) = "dbd_ix_bind_param";

{
    # Testing non-blob types
    # Create table for testing
    stmt_test $dbh, qq{
    CREATE TEMP TABLE $table
    (
        Col01   SERIAL(1000) NOT NULL,
        Col02   CHAR(20) NOT NULL,
        Col03   INTEGER NOT NULL,
        Col04   DATETIME YEAR TO FRACTION(5) NOT NULL,
        Col05   DECIMAL(10,9) NOT NULL
    )
    };

    my $pi = 3.141592654;
    my $e  = 2.718281828;

    # Expected results.
    my $row1 = { 'col01' => 1000,
                 'col02' => 'Another value',
                 'col03' => 987654321,
                 'col04' => '1997-02-28 00:11:22.55555',
                 'col05' => $e
               };
    my $row2 = { 'col01' => 1001,
                 'col02' => 'Another value',
                 'col03' => 987654321,
                 'col04' => '1997-02-28 00:11:22.55555',
                 'col05' => $e
               };
    my $row3 = { 'col01' => 1002,
                 'col02' => 'Some other data',
                 'col03' => 987654321,
                 'col04' => '1997-02-28 00:11:22.55555',
                 'col05' => $pi
               };
    my $row4 = { 'col01' => 1003,
                 'col02' => 'Some other data',
                 'col03' => 12345,
                 'col04' => '2000-02-29 23:59:59.99999',
                 'col05' => $pi
               };
    my $res1 = { 1000 => $row1 };
    my $res2 = { 1000 => $row1, 1001 => $row2 };
    my $res3 = { 1000 => $row1, 1001 => $row2, 1002 => $row3 };
    my $res4 = { 1000 => $row1, 1001 => $row2, 1002 => $row3, 1003 => $row4 };

    my $select = "SELECT * FROM $table ORDER BY Col01";
    my $sel = $dbh->prepare($select) or stmt_fail;
    stmt_ok;

    # Insert a row of values.
    my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?, ?)");
    stmt_fail() unless $sth;
    stmt_ok;

    $sth->bind_param(1, 'Another value', { ix_type => IX_CHAR });
    $sth->bind_param(2, 987654321, { TYPE => SQL_INTEGER });
    $sth->bind_param(3, '1997-02-28 00:11:22.55555', { ix_type => IX_DATETIME });
    $sth->bind_param(4, $e, { TYPE => SQL_NUMERIC });
    stmt_fail() unless $sth->execute;

    # Check that there is one row of data
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;

    # Check that there are now two rows of data, substantially the same
    stmt_fail() unless $sth->execute;
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

    # Try some new bind values
    $sth->bind_param(1, 'Some other data', { ix_type => IX_VARCHAR });
    $sth->bind_param(4, $pi, { ix_type => IX_DECIMAL });
    stmt_fail() unless $sth->execute;

    # Check that there are now three rows of data
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

    # Try some more new bind values
    $sth->bind_param(2, 12345, { ix_type => IX_SMALLINT });
    $sth->bind_param(3, '2000-02-29 23:59:59.99999', { ix_type => IX_VARCHAR });    # Semi-legitimate!
    stmt_fail() unless $sth->execute;

    # Check that there are now four rows of data
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res4) : stmt_nok;
}

if ($dbh->{ix_BlobSupport})
{
    # Testing BYTE and TEXT blob types
    stmt_test $dbh, qq{DROP TABLE $table};

    # Create table for testing
    stmt_test $dbh, qq{
    CREATE TEMP TABLE $table
    (
        Col01   SERIAL(1000) NOT NULL,
        Col02   CHAR(20) NOT NULL,
        Col03   BYTE NOT NULL,
        Col04   TEXT NOT NULL
    )
    };

    # Expected results.
    my $row1 = { 'col01' => 1000,
                 'col02' => 'Another value',
                 'col03' => 987654321,
                 'col04' => '1997-02-28 00:11:22.55555',
               };
    my $row2 = { 'col01' => 1001,
                 'col02' => 'Another value',
                 'col03' => 987654321,
                 'col04' => '1997-02-28 00:11:22.55555',
               };
    my $row3 = { 'col01' => 1002,
                 'col02' => 'Some other data',
                 'col03' => 987654321,
                 'col04' => '3.141593',
               };
    my $row4 = { 'col01' => 1003,
                 'col02' => 'Some other data',
                 'col03' => 12345,
                 'col04' => '2000-02-29 23:59:59.99999',
               };
    my $row5 = { 'col01' => 1000,
                 'col02' => 'Another value',
                 'col03' => 'A Pseudo-BYTE value',
                 'col04' => 'A Pseudo-TEXT value',
               };
    my $res1 = { 1000 => $row1 };
    my $res2 = { 1000 => $row1, 1001 => $row2 };
    my $res3 = { 1000 => $row5, 1001 => $row2 };
    my $res4 = { 1000 => $row5, 1001 => $row2, 1002 => $row3 };
    my $res5 = { 1000 => $row5, 1001 => $row2, 1002 => $row3, 1003 => $row4 };

    my $select = "SELECT * FROM $table ORDER BY Col01";
    my $sel = $dbh->prepare($select) or stmt_fail;
    stmt_ok;

    my ($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, ?, ?)");
    stmt_fail() unless $sth;
    stmt_ok;

    # Insert a row of values.
    $sth->bind_param(1, 'Another value', { ix_type => IX_CHAR }) or stmt_fail;
    $sth->bind_param(2, 987654321, { ix_type => IX_BYTE }) or stmt_fail;
    $sth->bind_param(3, '1997-02-28 00:11:22.55555', { ix_type => IX_TEXT }) or stmt_fail;
    stmt_fail() unless $sth->execute;

    # Check that there is one row of data
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;

    # Insert another (very similar) row of data.
    stmt_fail() unless $sth->execute;

    # Check that there are now two rows of data, substantially the same
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

    # Check that you can update a blob!
    my ($st2) = $dbh->prepare("UPDATE $table SET Col03 = ?, Col04 = ? WHERE Col01 = ?");
    stmt_fail() unless $st2;
    $st2->bind_param(1, 'A Pseudo-BYTE value', { ix_type => IX_BYTE }) or stmt_fail;
    $st2->bind_param(2, 'A Pseudo-TEXT value', { ix_type => IX_TEXT }) or stmt_fail;
    $st2->bind_param(3, 1000) or stmt_fail;
    $st2->execute or stmt_fail;
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

    # Try some new bind values
    $sth->bind_param(1, 'Some other data', { ix_type => IX_VARCHAR });
    $sth->bind_param(3, 3.141593, { ix_type => IX_TEXT });
    stmt_fail() unless $sth->execute;

    # Check that there are now three rows of data
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res4) : stmt_nok;

    # Try some more new bind values
    $sth->bind_param(2, 12345, { ix_type => IX_BYTE });
    $sth->bind_param(3, '2000-02-29 23:59:59.99999', { ix_type => IX_TEXT });
    stmt_fail() unless $sth->execute;

    # Check that there are now four rows of data
    $sel->execute ? validate_unordered_unique_data($sel, 'col01', $res5) : stmt_nok;
}

all_ok();
