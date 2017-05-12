#!/usr/bin/perl
#
#   @(#)$Id: t74blob.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Self-contained Test for Blobs (INSERT & SELECT) for DBD::Informix
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
    print("1..14\n");
    stmt_ok(0);
    $dbh->{PrintError} = 1;

    my $tablename = "dbd_ix_blobtest";

    my $stmt2 = "CREATE TEMP TABLE $tablename (I SERIAL UNIQUE, " .
                "B BYTE IN TABLE, T TEXT IN TABLE)";
    stmt_test($dbh, $stmt2, 0);

    my $stmt3 = "INSERT INTO $tablename VALUES(?, ?, ?)";
    stmt_note("# Testing: \$insert = \$dbh->prepare('$stmt3')\n");
    my $insert;
    stmt_fail() unless ($insert = $dbh->prepare($stmt3));
    stmt_ok(0);

    my $blob2 = "This is a TEXT blob";
    my $blob1 = "This is a pseudo-BYTE blob";
    stmt_note("# Testing: \$insert->execute(34, \$blob1, \$blob2)\n");
    stmt_fail() unless ($insert->execute(34, $blob1, $blob2));
    stmt_ok(0);

    $blob2 = "This is also a TEXT blob";
    $blob1 = "This is also a pseudo-BYTE blob";
    stmt_note("# Testing: \$insert->execute(36, \$blob1, \$blob2)\n");
    stmt_fail() unless ($insert->execute(36, $blob1, $blob2));
    stmt_ok(0);

    my $blob4 = "This, too, is a TEXT blob";
    my $blob3 = "This, too, is a pseudo-BYTE blob";
    stmt_note("# Testing: \$insert->execute(-9, \$blob4, \$blob3)\n");
    stmt_fail() unless ($insert->execute(-9, $blob4, $blob3));
    stmt_ok(0);

    stmt_note("Testing: \$insert->finish\n");
    stmt_fail() unless ($insert->finish);
    stmt_ok(0);

    # Verify that inserted data can be returned
    my $stmt4 = "SELECT * FROM $tablename ORDER BY I";
    stmt_note("# Testing\n\$cursor = \$dbh->prepare('$stmt4')\n");
    my $cursor;
    stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
    stmt_ok(0);

    stmt_note("# Re-testing: \$cursor->execute\n");
    stmt_fail() unless ($cursor->execute);
    stmt_ok(0);

    stmt_note("# Re-testing: \$cursor->fetch\n");
    # Fetch returns a reference to an array!
    my $ref;
    while ($ref = $cursor->fetch)
    {
        stmt_ok(0);
        my @row = @{$ref};
        # Verify returned data!
        stmt_note("# Values returned: ", $#row + 1, "\n");
        for (my $i = 0; $i <= $#row; $i++)
        {
            stmt_note("# Row value $i: $row[$i]\n");
        }
    }

    # Verify data attributes!
    my $i;
    my @type = @{$cursor->{TYPE}};
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
    print("# Number of Columns: $nfld; Number of Parameters: $nbnd\n");

    stmt_note("# Re-testing: \$cursor->finish\n");
    stmt_fail() unless ($cursor->finish);
    stmt_ok(0);

    # FREE the cursor and asociated data
    undef $cursor;
}

$dbh->disconnect ? stmt_ok : stmt_fail;

all_ok();
