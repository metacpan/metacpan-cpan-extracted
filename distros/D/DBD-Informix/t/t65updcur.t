#!/usr/bin/perl
#
#   @(#)$Id: t65updcur.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test $sth->{CursorName} and cursors FOR UPDATE for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test install...
my $dbh = connect_to_test_database();

stmt_note("1..16\n");
stmt_ok();

my $table = "DBD_IX_TestTable";
my $select = "SELECT * FROM $table";

stmt_test $dbh, qq{
CREATE TEMP TABLE $table
(
    Col01   SERIAL NOT NULL PRIMARY KEY,
    Col02   CHAR(30) NOT NULL,
    Col03   DATE NOT NULL,
    Col04   DATETIME YEAR TO FRACTION(5) NOT NULL
)
};

my($ssdt, $csdt) = get_date_as_string($dbh, 12, 8, 1940);
my $time = '1940-12-08 06:45:32.54321';
my $raw1 = 'Mornington Crescent';
my $tag1 = $dbh->quote($raw1);
my $raw2 = "King's Cross / St Pancras";
my $tag2 = $dbh->quote($raw2);
my $raw3 = "ABC $raw1";
my $insert01 = qq{INSERT INTO $table VALUES(0, $tag1, '$ssdt', '$time')};

# Insert two rows of data
stmt_test $dbh, $insert01;
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

my $sel = $dbh->prepare($select) or stmt_fail;
stmt_ok;

my $row1 = { 'col01' => 1, 'col02' => $raw1, 'col03' => $csdt, 'col04' => $time };
my $row2 = { 'col01' => 2, 'col02' => $raw2, 'col03' => $csdt, 'col04' => $time };
my $row3 = { 'col01' => 1, 'col02' => $raw3, 'col03' => $csdt, 'col04' => $time };
my $res1 = { 1 => $row1, 2 => $row2 };
my $res2 = { 1 => $row3 };

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;

my $selupd = $select . " FOR UPDATE";
my $st1 = $dbh->prepare($selupd) or stmt_fail;
stmt_ok;

# Check that attribute caching is still working!
my $name = $st1->{CursorName};
my $i;
for ($i = 0; $i < 3; $i++)
{
    my $x = ($name eq $st1->{CursorName}) ? "OK" : "** BROKEN **";
    print "# Cursor name $i: $st1->{CursorName} $x\n";
}

$name = $st1->{CursorName};
my $updstmt = "UPDATE $table SET Col02 = ? WHERE CURRENT OF $name";
print "# $updstmt\n";
my $st2 = $dbh->prepare($updstmt) or stmt_fail;
stmt_ok();

my $delstmt = "DELETE FROM $table WHERE CURRENT OF $name";
print "# $delstmt\n";
my $st3 = $dbh->prepare($delstmt) or stmt_fail;
stmt_ok();

# In a logged database, must be in a transaction
# Given new AutoCommit behaviour, must set AutoCommit Off.
$dbh->{AutoCommit} = 0
    unless (!$dbh->{ix_LoggedDatabase});

my $n = 0;
stmt_fail() unless ($st1->execute());
stmt_ok();

# Fetch first row
my $data;
stmt_fail() unless ($data = $st1->fetch);
stmt_ok();
$n++;
my @row;@row = @{$data};
for ($i = 0; $i <= $#row; $i++)
{
    print "Row $n: Field $i: <<$row[$i]>>\n";
}

# Update current row
$row[1] = "ABC " . $row[1];
stmt_fail() unless ($st2->execute($row[1]));

# Fetch second row
stmt_fail() unless ($data = $st1->fetch);
stmt_ok();
$n++;
@row = @{$data};
for ($i = 0; $i <= $#row; $i++)
{
    print "Row $n: Field $i: <<$row[$i]>>\n";
}

# Delete it
stmt_fail() unless ($st3->execute);
stmt_ok;

# In a logged database, must be in a transaction
$dbh->commit unless (!$dbh->{ix_LoggedDatabase});

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
