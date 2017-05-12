#!/usr/bin/perl
#
#   @(#)$Id: t43trans.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test AutoCommit Off for DBD::Informix
#
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

# AutoCommit Off => Explicit transactions in force

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test install...
my $dbh = connect_to_test_database();

if ($dbh->{ix_LoggedDatabase} == 0)
{
    stmt_note("1..1\n");
    stmt_note("# No transactions on unlogged database '$dbh->{Name}'\n");
    stmt_note("# Expect error about failing to unset AutoCommit mode.\n");
    # This should generate an error (not a warning as in versions 1.00.PC1 and earlier).
    # Set AutoCommit to Off
    my $ac = $dbh->{AutoCommit} ? "On" : "Off";
    print "# Default AutoCommit is $ac\n";
    my $msg;
    $SIG{__DIE__} = sub { $msg = "Die: $_[0]"; stmt_note("# $msg"); stmt_ok(0); all_ok(); exit(0); };
    $SIG{__WARN__} = sub { $msg = "Warn: $_[0]"; };
    $dbh->{AutoCommit} = 0;
    # Should not reach here!
    $SIG{__WARN__} = 'DEFAULT';
    stmt_note("# *** $msg");
    stmt_note("# *** unexpected return from die/croak code!");
    stmt_fail();
    all_ok();
}

stmt_note("1..21\n");
stmt_ok();
if ($dbh->{ix_ModeAnsiDatabase})
{ stmt_note("# This is a MODE ANSI database\n"); }
else
{ stmt_note("# This is a regular logged database\n"); }

# Set AutoCommit to Off
my $ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# Default AutoCommit is $ac\n";
$dbh->{AutoCommit} = 0;
$ac = $dbh->{AutoCommit} ? "On" : "Off";
print "# AutoCommit was set to $ac\n";

my $trans01 = "DBD_IX_Trans01";
my $select = "SELECT * FROM $trans01";

stmt_test $dbh, qq{
CREATE TABLE $trans01
(
    Col01   SERIAL NOT NULL PRIMARY KEY,
    Col02   CHAR(20) NOT NULL,
    Col03   DATE NOT NULL,
    Col04   DATETIME YEAR TO FRACTION(5) NOT NULL
)
};

my $sel = $dbh->prepare($select) or stmt_fail;
stmt_ok;

my($ssdt, $csdt) = get_date_as_string($dbh, 12, 25, 1996);
my $time = '2004-02-29 23:59:54.32109';
my $tag1  = 'Elfdom';
my $tag2 = 'Santa Claus Home';

my $row1 = { 'col01' => 1, 'col02' => $tag1, 'col03' => $csdt, 'col04' => $time };
my $row2 = { 'col01' => 2, 'col02' => $tag1, 'col03' => $csdt, 'col04' => $time };
my $row3 = { 'col01' => 3, 'col02' => $tag2, 'col03' => $csdt, 'col04' => $time };
my $row4 = { 'col01' => 4, 'col02' => $tag2, 'col03' => $csdt, 'col04' => $time };
my $row5 = { 'col01' => 5, 'col02' => $tag1, 'col03' => $csdt, 'col04' => $time };
my $res1 = { 1 => $row1 };
my $res2 = { 2 => $row2, 3 => $row3 };
my $res3 = { 4 => $row4, 5 => $row5 };

# Ensure that temp table survives...
stmt_fail() unless ($dbh->commit());

my $insert01 = qq{INSERT INTO $trans01 VALUES(0, '$tag1', '$ssdt', '$time')};

stmt_test $dbh, $insert01;
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;

stmt_fail() unless ($dbh->rollback);
stmt_ok();

# Ensure there is no data
select_zero_data $dbh, $select;

# Insert two rows of data.
stmt_test $dbh, $insert01;
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

# Rollback!
stmt_fail() unless ($dbh->rollback);

# Check that there is no data
select_zero_data $dbh, $select;

# Insert two rows of data.
stmt_test $dbh, $insert01;
$insert01 =~ s/$tag2/$tag1/;
stmt_test $dbh, $insert01;

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

# Commit it
stmt_fail() unless ($dbh->commit);

# Check that there is still some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

# Delete the data.
stmt_test $dbh, "DELETE FROM $trans01";

# Check that there is no data
select_zero_data $dbh, $select;

# Rollback the transaction
stmt_fail() unless $dbh->rollback;

# Check that there is still some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res3) : stmt_nok;

stmt_test $dbh, qq{DROP TABLE $trans01};
stmt_fail unless $dbh->commit;


$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
