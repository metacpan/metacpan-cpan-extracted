#!/usr/bin/perl
#
#   @(#)$Id: t30update.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test script for DBD::Informix
#
#   Copyright 1998-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

my($testtable) = "dbd_ix_test1";

stmt_note("1..40\n");

my($dbh) = connect_to_test_database();
stmt_ok(0);

# Create temporary table...
my($stmt2) = qq"CREATE TEMP TABLE $testtable
            (
                id INTEGER NOT NULL,
                name CHAR(64) NOT NULL,
                code CHAR(3) NOT NULL,
                value DECIMAL(10,4) NOT NULL
            )";
stmt_test($dbh, $stmt2, 0);

my($stmt3) = qq"INSERT INTO $testtable
                VALUES(1, 'Alligator Descartes', 'ABC', 123.4567)";
stmt_test($dbh, $stmt3, 0);

select_all({
    1 => ['Alligator Descartes', 'ABC', 123.4567]
    });

my($stmt6) = "UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'";
stmt_test($dbh, $stmt6, 0);

select_all({
    2 => ['Alligator Descartes', 'ABC', 123.4567]
    });

my($stmt7) = qq"INSERT INTO $testtable
                VALUES(1, 'Jonathan Leffler', 'AAA', 9999.8822)";
stmt_test($dbh, $stmt7, 0);

select_all({
    1 => ['Jonathan Leffler', 'AAA', 9999.8822],
    2 => ['Alligator Descartes', 'ABC', 123.4567]
});

my($stmt4) = qq"UPDATE $testtable SET (Code, Value, Name) = (?, ?, ?)
                    WHERE Id = ?";
my($st1) = $dbh->prepare($stmt4) || stmt_fail();
$st1->execute('ROM', -1, 'Julius Caesar', 1) || stmt_fail();
stmt_ok(0);

select_all({
    1 => ['Julius Caesar', 'ROM', -1],
    2 => ['Alligator Descartes', 'ABC', 123.4567]
});

my(@data) = ('AAA', 9999.8822, 'Jonathan Leffler', 1);
$st1->execute(@data) || stmt_fail();

select_all({
    1 => ['Jonathan Leffler', 'AAA', 9999.8822],
    2 => ['Alligator Descartes', 'ABC', 123.4567]
});

my($stmt13) = "INSERT INTO $testtable VALUES(?, ?, ?, ?)";
my($sth);
stmt_note("# Testing: \$sth = \$dbh->prepare('$stmt13')\n");
stmt_fail() unless ($sth = $dbh->prepare($stmt13));
stmt_ok(0);

my(@bind) = ( "3", "Frederick the Great", "ZZZ", -0.0001 );
stmt_note("# Testing: \$sth->execute(@bind)\n");
stmt_fail() unless ($sth->execute(@bind));
stmt_ok(0);

stmt_note("# Testing: \$sth->execute(4.00, \"Ghenghis Khan\")\n");
stmt_fail() unless ($sth->execute(4.00, "Ghenghis Khan", "XYZ", 1123));
stmt_ok(0);

select_all({
1 => ['Jonathan Leffler', 'AAA', 9999.8822],
2 => ['Alligator Descartes', 'ABC', 123.4567],
3 => ['Frederick the Great', 'ZZZ', -0.0001],
4 => ['Ghenghis Khan', 'XYZ', 1123]
});

# FREE the statement and asociated data
undef $sth;

stmt_note("# Testing: \$dbh->disconnect()\n");
stmt_fail() unless ($dbh->disconnect);
stmt_ok(0);

all_ok;

# ----------------------------------------------------------------------


sub select_all
{
    my ($exp1) = @_;        # Reference to associative array
    my (%exp2) = %{$exp1};  # Associative array of numbers (keys) and names
    my (@data);     # Array dereferenced from %exp{1} etc.
    my (@row, $i);  # Local variables
    my ($cursor);

    stmt_note("# Checking Updated Data\n");
    my($stmt8) = "SELECT * FROM $testtable ORDER BY id";
    stmt_note("# Testing: \$cursor = \$dbh->prepare('$stmt8')\n");
    stmt_fail() unless ($cursor = $dbh->prepare($stmt8));
    stmt_ok(0);

    stmt_note("# Testing: \$cursor->execute\n");
    stmt_fail() unless ($cursor->execute);
    stmt_ok(0);

    stmt_note("# Testing: \$cursor->fetchrow iteratively\n");
    $i = 1;
    while (@row = $cursor->fetchrow)
    {
        stmt_note("# Row $i: $row[0] => '$row[1]', '$row[2]', $row[3]\n");
        my($ref_arr) = $exp2{$row[0]};
        @data = @{$ref_arr};
        stmt_note("# Want $i: '$data[0]', '$data[1]', |$data[2]|\n");
        if ($row[1] eq $data[0] && $row[2] eq $data[1] && $row[3] == $data[2])
        {
            stmt_ok(0);
        }
        else
        {
            stmt_note("# Wrong value:\n");
            if ($row[1] ne $data[0])
            {
                stmt_note("# -- Got    <<$row[1]>>\n");
                stmt_note("# -- Wanted <<$data[0]>>\n");
            }
            if ($row[2] ne $data[1])
            {
                stmt_note("# -- Got    <<$row[2]>>\n");
                stmt_note("# -- Wanted <<$data[1]>>\n");
            }
            if ($row[3] != $data[2])
            {
                stmt_note("# -- Got    <<$row[3]>>\n");
                stmt_note("# -- Wanted <<$data[2]>>\n");
            }
            stmt_fail();
        }
        $i++;
    }

    stmt_note("# Re-testing: \$cursor->finish\n");
    stmt_fail() unless ($cursor->finish);
    stmt_ok(0);

    # Free cursor referencing the table...
    undef $cursor;
}
