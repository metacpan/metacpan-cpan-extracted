#!/usr/bin/perl
#
#   @(#)$Id: t66insert.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test INSERT Cursors for DBD::Informix
#
#   Copyright 2000    Paul Palacios, C-Group Inc.
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use DBD::Informix::TestHarness;

my($dbh) = connect_to_test_database({RaiseError=>1, PrintError=>1});

$dbh->{AutoCommit} = 0 if $dbh->{ix_LoggedDatabase};

stmt_note("1..10\n");
stmt_ok();
my($table) = "dbd_ix_insert";

my($create) = qq{
CREATE TEMP TABLE $table
(
    Col01   SERIAL(1000) NOT NULL,
    Col02   CHAR(20) NOT NULL,
    Col03   DATETIME YEAR TO FRACTION(5) NOT NULL,
    Col04   DECIMAL NOT NULL
)
};

# Create table for testing
stmt_test $dbh, $create;

my($rows) = 1000;

# Insert a row of values.
{
stmt_note("# Inserting $rows rows without INSERT cursor\n");
my($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, CURRENT, ?)" );
stmt_fail() unless $sth;
stmt_ok;

my($t0) = [gettimeofday];

for my $i (0 .. $rows)
{
    stmt_fail() unless ($sth->execute('FOOBARBAZ', $i + 2.8128))
}

my($elapsed) = tv_interval ( $t0, [gettimeofday]);

my($note) = sprintf("without INSERT cursor: $rows in %.3f seconds (%.5f seconds/row)\n",
                    $elapsed, $elapsed/$rows);
stmt_note($note);

stmt_ok;
#print_sqlca $sth;
my($rows) = $sth->rows;
stmt_comment("ROWS = $rows\n");

$sth->finish;
$dbh->commit if $dbh->{ix_LogggedDatabase};
}

$dbh->do("DROP TABLE $table") or stmt_fail;
$dbh->do($create) or stmt_fail;

{
stmt_note("# Inserting $rows rows with INSERT cursor\n");
my($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, CURRENT, ?)", { ix_InsertCursor => 1 } );
stmt_fail() unless $sth;
stmt_ok;

my($t0) = [gettimeofday];
for my $i (0 .. $rows)
{
    stmt_fail() unless ($sth->execute('FOOBARBAZ', $i + 2.8128))
}
my($elapsed) = tv_interval ( $t0, [gettimeofday]);

my($note) = sprintf("# with    INSERT cursor: $rows in %.3f seconds (%.5f seconds/row)\n",
                    $elapsed, $elapsed/$rows);
stmt_note($note);

stmt_ok;
#print_sqlca $sth;
my($rows) = $sth->rows;
stmt_comment("ROWS = $rows");
$sth->finish;
$dbh->commit if $dbh->{ix_LogggedDatabase};
}

$dbh->do("DROP TABLE $table") or stmt_fail;
$dbh->do($create) or stmt_fail;

{
$rows /= 10;
stmt_note("# Inserting $rows rows without INSERT cursor\n");
my($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, CURRENT, ?)", { ix_InsertCursor => 0 } );
stmt_fail() unless $sth;
stmt_ok;

my($t0) = [gettimeofday];
for my $i (0 .. $rows)
{
    stmt_fail() unless ($sth->execute('FOOBARBAZ', $i + 2.8128));
}
my($elapsed) = tv_interval ( $t0, [gettimeofday]);

my($note) = sprintf("# without INSERT cursor: $rows in %.3f seconds (%.5f seconds/row)\n",
                    $elapsed, $elapsed/$rows);
stmt_note($note);
stmt_ok;

my($rows) = $sth->rows;
stmt_comment("ROWS = $rows");
$sth->finish;
$dbh->commit if $dbh->{ix_LogggedDatabase};
}

stmt_note("# Update statement should be rejected\n");
$dbh->{PrintError} = 0;
$dbh->{RaiseError} = 0;
my($sql) = "UPDATE $table SET Col02 = ? WHERE Col01 = ?";
stmt_note("# $sql\n");
my($sth) = $dbh->prepare($sql, { ix_InsertCursor => 1 } );
stmt_fail() if $sth;
stmt_note("# $DBI::errstr\n");
stmt_ok;

{
if ($dbh->{ix_LoggedDatabase})
{
    stmt_note("# Checking for warning if AutoCommit On in Logged DB\n");
    $dbh->{AutoCommit} = 1;
    my($warning);
    local $SIG{__WARN__} = sub {$warning = $_[0]};
    my($sth) = $dbh->prepare("INSERT INTO $table VALUES(0, ?, CURRENT, ?)", { ix_InsertCursor => 1 } );
    stmt_fail() unless $sth;
    stmt_note("# $warning");
    stmt_fail() unless $warning =~ /insert cursor ineffective with AutoCommit enabled/;
}
stmt_ok;
}

$dbh->disconnect or stmt_fail;
all_ok();
