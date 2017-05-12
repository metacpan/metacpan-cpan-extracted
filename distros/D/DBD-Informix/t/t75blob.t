#!/usr/bin/perl
#
#   @(#)$Id: t75blob.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
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

my $tablename = "DBD_IX_BlobTest2";

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
    print("1..10\n");
    stmt_ok(0);
    $dbh->{PrintError} = 1;

    my $stmt2 = qq{ CREATE TEMP TABLE $tablename (I SERIAL UNIQUE,
                    B BYTE IN TABLE, T TEXT IN TABLE) };
    stmt_test($dbh, $stmt2, 0);

    my $stmt3 = qq{ INSERT INTO $tablename VALUES(?, ?, ?) };
    stmt_note("# Testing: \$insert = \$dbh->prepare('$stmt3')\n");
    my $insert;
    stmt_fail() unless ($insert = $dbh->prepare($stmt3));
    stmt_ok(0);

    for (my $i = 1; $i <= 20; $i++)
    {
        my $repeat = int(rand 30) + 1;
        my $blob1 = "This is a pseudo-BYTE blob " x $repeat;
        my $blob2 = "This is a TEXT blob " x $repeat;
        $blob1 = "<<$repeat>>$blob1";
        $blob2 = "<<$repeat>>$blob2";
        chop $blob1;
        chop $blob2;
        stmt_note("# Loop $i: repeat $repeat\n");
        stmt_fail() unless ($insert->execute($i, $blob1, $blob2));
        stmt_note("# insert OK $i\n");
        ## This causes -608 errors on the next iteration of the
        ## main loop in v0.59; fixed in v0.60.
        if ($i % 6 == 0)
        {
            $i++;
            stmt_note("# Loop $i: double null\n");
            stmt_fail() unless ($insert->execute($i, undef, undef));
            stmt_note("# aux insert OK $i\n");
        }
    }
    stmt_ok(0);

    stmt_note("Testing: \$insert->finish\n");
    stmt_fail() unless ($insert->finish);
    stmt_ok(0);

    # Verify that inserted data can be returned
    my $stmt4 = qq{ SELECT * FROM $tablename ORDER BY I };
    stmt_note("# Testing\n\$cursor = \$dbh->prepare('$stmt4')\n");
    my $cursor;
    stmt_fail() unless ($cursor = $dbh->prepare($stmt4));
    stmt_ok(0);

    stmt_note("# Testing: \$cursor->execute\n");
    stmt_fail() unless ($cursor->execute);
    stmt_ok(0);

    stmt_note("# Testing: \$cursor->fetch\n");
    # Fetch returns a reference to an array!
    my $ref;
    while ($ref = $cursor->fetch)
    {
        my @row = @{$ref};
        # Verify returned data!
        stmt_note("# Values returned: ", $#row + 1, "\n");
        for (my $i = 0; $i <= $#row; $i++)
        {
            my $val = $row[$i];
            if (defined $val)
            {
                $val = substr($row[$i], 0, 30) . "..."
                    if (length($val) > 33);
                stmt_note("# Row value $i: $val\n");
            }
            else
            {
                stmt_note("# Row value $i: <<NULL>>\n");
            }
        }
    }
    stmt_ok(0);

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

    $dbh->do("DROP TABLE $tablename");
}

$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
