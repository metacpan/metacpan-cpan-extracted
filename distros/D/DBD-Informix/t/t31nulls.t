#!/usr/bin/perl
#
#   @(#)$Id: t31nulls.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test Null Handling for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

sub select_null_data
{
    my ($dbh, $num, $stmt) = @_;
    my ($count, $st2) = (0);
    my (@row);

    stmt_note("# $stmt\n");
    # Check that there is some data
    stmt_fail() unless ($st2 = $dbh->prepare($stmt));
    stmt_fail() unless ($st2->execute);
    while  (@row = $st2->fetchrow)
    {
        my($pad, $i, $n) = ("# ", 0, 0);
        for ($i = 0; $i < @row; $i++)
        {
            if (defined $row[$i])
            {
                $pad .= "**non-null**";
                $n++;
            }
            else
            {
                $row[$i] = '';
            }
            stmt_note("$pad$row[$i]");
            $pad = " :: ";
        }
        stmt_note("\n");
        stmt_fail() if ($n > 0);
        $count++;
    }
    stmt_fail() unless ($count == $num);
    stmt_fail() unless ($st2->finish);
    undef $st2;
    stmt_ok();
}


# Test install...
my $dbh = connect_to_test_database();

stmt_note("1..7\n");
stmt_ok();
my $trans01 = "dbd_ix_nulls01";

# Create table which accepts nulls in all columns
stmt_test $dbh, qq{
CREATE TEMP TABLE $trans01
(
    Col01   INTEGER,
    Col02   CHAR(20),
    Col03   DATE,
    Col04   DATETIME YEAR TO FRACTION(5),
    Col05   DECIMAL
)
};

# Insert a row of nulls.
stmt_test $dbh, qq{
INSERT INTO $trans01 VALUES(NULL, NULL, NULL, NULL, NULL)
};

my $select = "SELECT * FROM $trans01";

# Check that there is now one row of null data
select_null_data $dbh, 1, $select;

# Insert a row of values.
my $ins = "INSERT INTO $trans01 VALUES(?, ?, ?, ?, ?)";
stmt_note("# $ins\n");
my $sth = $dbh->prepare($ins);
stmt_fail() unless $sth;
stmt_ok;
stmt_fail() unless $sth->execute(undef, undef, undef, undef, undef);
stmt_ok;

# Check that there are now two rows of null data
select_null_data $dbh, 2, $select;

all_ok();
