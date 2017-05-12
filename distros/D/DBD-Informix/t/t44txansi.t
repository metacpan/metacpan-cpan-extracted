#!/usr/bin/perl
#
#   @(#)$Id: t44txansi.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test AutoCommit On for DBD::Informix
#
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler
#
# AutoCommit On => Each statement is a self-contained transaction
# Ensure MODE ANSI databases use cursors WITH HOLD

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test install...
my $dbh = connect_to_test_database();

if (!$dbh->{ix_ModeAnsiDatabase})
{
    stmt_note("1..0 # Skip: MODE ANSI test - database '$dbh->{Name}' is not MODE ANSI\n");
    $dbh->disconnect;
    exit(0);
}

stmt_note("1..18\n");
stmt_ok();

my $ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# Default AutoCommit is $ac\n";
$dbh->{AutoCommit} = 1;
$ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# AutoCommit was set to $ac\n";

my $trans01 = "DBD_IX_Trans01";
my $select = "SELECT * FROM $trans01";

stmt_test $dbh, qq{
CREATE TEMP TABLE $trans01
(
    Col01   SERIAL NOT NULL PRIMARY KEY,
    Col02   CHAR(20) NOT NULL,
    Col03   DATE NOT NULL,
    Col04   DATETIME YEAR TO FRACTION(5) NOT NULL
)
};

my($ssdt, $csdt) = get_date_as_string($dbh, 4, 23, 1214);
my $time = '1918-11-11 11:00:00.00000';
my $tag1  = 'Fangorn Forest';
my $tag2 = 'Mirkwood';

my $row1 = { 'col01' => 1, 'col02' => $tag1, 'col03' => $csdt, 'col04' => $time };
my $row2 = { 'col01' => 2, 'col02' => $tag1, 'col03' => $csdt, 'col04' => $time };
my $row3 = { 'col01' => 3, 'col02' => $tag2, 'col03' => $csdt, 'col04' => $time };
my $row4 = { 'col01' => 4, 'col02' => $tag2, 'col03' => $csdt, 'col04' => $time };
my $row5 = { 'col01' => 5, 'col02' => $tag1, 'col03' => $csdt, 'col04' => $time };
my $res1 = { 1 => $row1 };
my $res2 = { 1 => $row1, 2 => $row2, 3 => $row3 };
my $res3 = { 1 => $row1, 2 => $row2, 3 => $row3, 4 => $row4, 5 => $row5 };

my $sel = $dbh->prepare($select) or stmt_fail;
stmt_ok;

# Confirm that table exists but is empty.
select_zero_data $dbh, $select;

my $insert01 = qq{INSERT INTO $trans01 VALUES(0, '$tag1', '$ssdt', '$time')};

stmt_test $dbh, $insert01;

$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;

# Insert two more rows of data.
stmt_test $dbh, $insert01;
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

sub print_row
{
    my($row) = @_;
    my(@row) = @{$row};
    my($pad, $i) = ("#-# ", 0);
    for ($i = 0; $i < @row; $i++)
    {
        stmt_note("$pad$row[$i]");
        $pad = " :: ";
    }
    stmt_note("\n");
}

my $fetch1;
# Prepare, open and fetch one row from a cursor
my $sth;
stmt_fail unless ($sth = $dbh->prepare($select));
stmt_fail unless ($sth->execute);
stmt_fail unless ($fetch1 = $sth->fetch);
print_row $fetch1;
stmt_ok;

# Insert another two rows of data (committing those rows)
stmt_test $dbh, $insert01;
$insert01 =~ s/$tag2/$tag1/;
stmt_test $dbh, $insert01;

my $fetch2;
# Check that the cursor still works!
while ($fetch2 = $sth->fetch)
{
    print_row $fetch2;
}
stmt_fail if ($sth->{ix_sqlcode} < 0);
stmt_ok;

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

# Delete the data.
stmt_test $dbh, "DELETE FROM $trans01";

# Check that there is no data
select_zero_data $dbh, $select;

$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
