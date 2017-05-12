#!/usr/bin/perl
#
#   @(#)$Id: t72blob.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test Basic Blobs (INSERT & SELECT) for DBD::Informix
#
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test install...
my $dbh = connect_to_test_database();

if (!$dbh->{ix_BlobSupport})
{
    print("1..0 # Skip: No blob support -- no blob testing\n");
    $dbh->disconnect;
    exit(0);
}
else
{
    print("1..12\n");
    stmt_ok(0);

    my $tablename = "dbd_ix_blobtest";

    my $stmt2 = "CREATE TEMP TABLE $tablename (I SERIAL UNIQUE, " .
             " T TEXT IN TABLE, B BYTE IN TABLE)";
    stmt_test($dbh, $stmt2, 0);

    my $stmt3 = "INSERT INTO $tablename VALUES(?, ?, ?)";
    stmt_note("# Testing: \$insert = \$dbh->prepare('$stmt3')\n");
    my $insert;
    stmt_fail() unless ($insert = $dbh->prepare($stmt3));
    stmt_ok(0);

    my $value1 = "This is a TEXT blob";
    my $value2 = "This is a pseudo-BYTE blob";
    my $blob1 = $value1;
    my $blob2 = $value2;
    stmt_note("# Testing: \$insert->execute(1, \$blob1, \$blob2)\n");
    stmt_fail() unless ($insert->execute(1, $blob1, $blob2));
    stmt_ok(0);

    # At one time, we got free problems reported when we did this!
    my $value3 = "This is also a TEXT blob";
    my $value4 = "This is also a pseudo-BYTE blob";
    $blob1 = $value3;
    $blob2 = $value4;
    stmt_note("# Testing: \$insert->execute(2, \$blob1, \$blob2)\n");
    stmt_fail() unless ($insert->execute(2, $blob1, $blob2));
    stmt_ok(0);

    my $value5 = "This, too, is a TEXT blob";
    my $value6 = "This, too, is a pseudo-BYTE blob";
    my $blob3 = $value5;
    my $blob4 = $value6;
    stmt_note("# Testing: \$insert->execute(3, \$blob3, \$blob4)\n");
    stmt_fail() unless ($insert->execute(3, $blob3, $blob4));
    stmt_ok(0);

    my $row1 = { 'i' => 1, 't' => $value1, 'b' => $value2 };
    my $row2 = { 'i' => 2, 't' => $value3, 'b' => $value4 };
    my $row3 = { 'i' => 3, 't' => $value5, 'b' => $value6 };
    my $res1 = { 1 => $row1, 2 => $row2, 3 => $row3 };

    stmt_note("Testing: \$insert->finish\n");
    stmt_fail() unless ($insert->finish);
    stmt_ok(0);

    $dbh->commit if ($dbh->{ix_InTransaction});

    # Verify that inserted data can be returned
    my $stmt4 = "SELECT * FROM $tablename ORDER BY I";
    stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt4')\n");
    my $cursor;
    stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
    stmt_ok(0);

    stmt_note("# Re-testing: \$cursor->execute\n");
    stmt_fail() unless ($cursor->execute);
    stmt_ok(0);

    validate_unordered_unique_data($cursor, 'i', $res1);

    # Verify data attributes!
    my @type = @{$cursor->{TYPE}};
    my $i;
    for ($i = 0; $i <= $#type; $i++) { print ("# Type      $i: $type[$i]\n"); }
    my @name = @{$cursor->{NAME}};
    for ($i = 0; $i <= $#name; $i++) { print ("# Name      $i: $name[$i]\n"); }
    my @null = @{$cursor->{NULLABLE}};
    for ($i = 0; $i <= $#null; $i++) { print ("# Nullable  $i: $null[$i]\n"); }
    my @prec = @{$cursor->{PRECISION}};
    for ($i = 0; $i <= $#prec; $i++) { print ("# Precision $i: $prec[$i]\n"); }
    my @scal = @{$cursor->{SCALE}};
    for ($i = 0; $i <= $#scal; $i++) { print ("# Scale     $i: $scal[$i]\n"); }

    my $nfld = $cursor->{NUM_OF_FIELDS};
    my $nbnd = $cursor->{NUM_OF_PARAMS};
    stmt_note("# Number of Columns: $nfld; Number of Parameters: $nbnd\n");

    stmt_note("# Testing: \$cursor->finish\n");
    stmt_fail() unless ($cursor->finish);
    stmt_ok();

    # FREE the cursor and asociated data
    undef $cursor;
}

$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
