#!/usr/bin/perl
#
#   @(#)$Id: t41txacoff.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test Transactions with AutoCommit Off for DBD::Informix
#
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler
#
# Simple transaction testing setting AutoCommit Off.
# Not significantly different from the testing in t43trans.t.

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test connection
my $dbh = connect_to_test_database({ AutoCommit => 1, PrintError => 1 });

if ($dbh->{ix_LoggedDatabase} == 0)
{
    stmt_note("1..0 # Skip: No transactions on unlogged database '$dbh->{Name}'\n");
    $dbh->disconnect;
    exit(0);
}

# Only the maintainers of DBD::Informix should have to wrap their brains
# around this -- everyone else should skip it now!
# Note: we have a logged database.  Use test_conn_tx() immediately after
# connection, or immediately after commit/rollback, to verify correct
# variable state.
# Assert that if AutoCommit is Off and database is not MODE ANSI, will be InTx;
# otherwise, will not be InTx.
sub test_conn_tx
{
    my ($dbh) = @_;
    stmt_note "# InTransaction = $dbh->{ix_InTransaction}\n";
    if ($dbh->{AutoCommit} == 0 && $dbh->{ix_ModeAnsiDatabase} == 0)
    {
        stmt_fail unless $dbh->{ix_InTransaction};
    }
    else
    {
        stmt_fail if $dbh->{ix_InTransaction};
    }
}

my $trans01 = "DBD_IX_Trans01";
my $ansi = $dbh->{ix_ModeAnsiDatabase};

stmt_note "1..20\n";
stmt_ok;
stmt_note "# This is a MODE ANSI database\n" if ($ansi);
stmt_note "# This is a regular logged database\n" if (!$ansi);
stmt_note "# AutoCommit mode is $dbh->{AutoCommit}\n";
stmt_note "# InTransaction = $dbh->{ix_InTransaction}\n";
test_conn_tx($dbh);

stmt_note "# Set AutoCommit Off - start manual transactions\n";
$dbh->{AutoCommit} = 0;
stmt_note "# AutoCommit mode is now $dbh->{AutoCommit}\n";
stmt_note "# InTransaction = $dbh->{ix_InTransaction}\n";
test_conn_tx($dbh);

stmt_test $dbh, qq{
CREATE TABLE $trans01
(
    Col01   SERIAL NOT NULL PRIMARY KEY,
    Col02   CHAR(20) NOT NULL,
    Col03   DATE NOT NULL,
    Col04   DATETIME YEAR TO FRACTION(5) NOT NULL
)
};
stmt_note "# InTransaction = $dbh->{ix_InTransaction}\n";
stmt_fail unless $dbh->{ix_InTransaction};

my($ssdt, $csdt) = get_date_as_string($dbh, 12, 25, 1996);
my $time = '2004-02-29 23:59:54.32109';

stmt_fail unless ($dbh->commit());
test_conn_tx($dbh);

# This transaction will be rolled back.
my $tag1  = 'Elfdom';
my $insert01 = qq{INSERT INTO $trans01 VALUES(0, '$tag1', '$ssdt', '$time')};

stmt_test $dbh, $insert01;
print "# InTransaction = $dbh->{ix_InTransaction}\n";
stmt_fail unless $dbh->{ix_InTransaction};

stmt_fail unless ($dbh->rollback);
test_conn_tx($dbh);
stmt_ok;

my $select = "SELECT * FROM $trans01";

# This transaction will be rolled back.
# Check that there is no data
select_zero_data $dbh, $select;
stmt_note "# InTransaction = $dbh->{ix_InTransaction}\n";
stmt_fail unless $dbh->{ix_InTransaction};

# Insert two rows of data.
stmt_test $dbh, $insert01;
my $tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag1/$tag2/;
stmt_test $dbh, $insert01;

# Row number 1 is inserted but rolled back...
my $row1 = { 'col01' => 2, 'col02' => 'Elfdom', 'col03' => $csdt, 'col04' => $time };
my $row2 = { 'col01' => 3, 'col02' => 'Santa Claus Home', 'col03' => $csdt, 'col04' => $time };
my $res1 = { 2 => $row1, 3 => $row2 };
my $row3 = { 'col01' => 4, 'col02' => 'Santa Claus Home', 'col03' => $csdt, 'col04' => $time };
my $row4 = { 'col01' => 5, 'col02' => 'Elfdom', 'col03' => $csdt, 'col04' => $time };
my $res2 = { 4 => $row3, 5 => $row4 };

my $sel = $dbh->prepare($select) or stmt_fail;
stmt_ok;

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res1) : stmt_nok;
stmt_fail unless $dbh->{ix_InTransaction};

# Rollback!
stmt_fail unless ($dbh->rollback);
test_conn_tx($dbh);

# This transaction will be committed
# Check that there is no data
select_zero_data $dbh, $select;
stmt_fail unless $dbh->{ix_InTransaction};

# Insert two rows of data.
stmt_test $dbh, $insert01;
$tag2 = 'Santa Claus Home';
$insert01 =~ s/$tag2/$tag1/;
stmt_test $dbh, $insert01;

# Check that there is some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;

# Commit it
stmt_fail unless $dbh->commit;
test_conn_tx($dbh);

# This transaction will be rolled back.
# Check that there is still some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;
stmt_fail unless $dbh->{ix_InTransaction};

# Delete the data.
stmt_test $dbh, "DELETE FROM $trans01";

# Check that there is no data
select_zero_data $dbh, $select;

# Rollback the transaction
stmt_fail unless $dbh->rollback;
test_conn_tx($dbh);

# Check that there is still some data
$sel->execute ? validate_unordered_unique_data($sel, 'col01', $res2) : stmt_nok;
stmt_fail unless $dbh->{ix_InTransaction};

stmt_test $dbh, qq{DROP TABLE $trans01};
stmt_fail unless $dbh->commit;

$dbh->disconnect ? stmt_ok : stmt_nok;

all_ok();
