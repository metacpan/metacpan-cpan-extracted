#!/usr/bin/perl
#
#   @(#)$Id: t54native.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test NAME, ix_NativeTypeName, ix_ColType, ix_ColLength attributes.
#   No testing for UDTs.
#
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

print "1..5\n";

# Test connection
my ($dbh) = connect_to_test_database({ AutoCommit => 1, PrintError => 1 });
stmt_ok;

# Create some temp tables to work with...

sub slurp_and_do
{
    my ($dbh, $file) = @_;
    open(SQL, "<$file") or stmt_fail;
    my (@sql) = <SQL>;
    close SQL;
    $dbh->do("@sql") or stmt_fail;
    stmt_ok;
}

slurp_and_do($dbh, "t/decgen.sql");
slurp_and_do($dbh, "t/dtgen.sql");

my ($online) = "";
my ($nls) = "";

$online = qq{
        col007      VARCHAR(255) NOT NULL,
        col008      VARCHAR(64,32),
        col009      BYTE IN TABLE,
        col010      TEXT IN TABLE,\n}
    if ($dbh->{ix_InformixOnLine});

if ($dbh->{ix_ServerVersion} >= 600)
{
    $nls = "        col011      NCHAR(256),\n";
    $nls .= qq{
        col012      NVARCHAR(24),
        col013      NVARCHAR(255,32),\n}
        if ($dbh->{ix_InformixOnLine});
}

$dbh->do(qq{
    CREATE TEMP TABLE dbd_ix_other
    (
        col000      SERIAL NOT NULL,
        col001      CHAR(10) NOT NULL,
        col002      SMALLINT,
        col003      INTEGER,
        col004      FLOAT,
        col005      SMALLFLOAT,
        col006      DATE,$online$nls
        col014      CHAR(1024) NOT NULL,
        dummy       CHAR(1)
    ) WITH NO LOG });

# OK; those commands created: dbd_ix_decimal, dbd_ix_money,
# dbd_ix_datetime, dbd_ix_interval and dbd_ix_other tables.
# Now, let's review the described data...

my ($sth) = $dbh->prepare("SELECT * FROM dbd_ix_decimal, dbd_ix_money, dbd_ix_datetime, dbd_ix_interval, dbd_ix_other")
    or stmt_fail;

# These attributes return array references.
my ($names) = $sth->{NAME};
my ($types) = $sth->{ix_NativeTypeName};
my ($coltyp) = $sth->{ix_ColType};
my ($collen) = $sth->{ix_ColLength};

stmt_fail("Array length mismatch {NAMES} $#{$names} vs {ix_NativeTypeName} $#${types}\n")
    if ($#{$names} != $#{$types});
stmt_fail("Array length mismatch {NAMES} $#${names} vs {ix_ColType} $#{$coltyp}\n")
    if ($#${names} != $#${coltyp});
stmt_fail("Array length mismatch {NAMES} $#${names} vs {ix_ColLength} $#{$collen}\n")
    if ($#${names} != $#${collen});
stmt_ok;

# JL 2000-02-08:
# Ideally, the code below should verify that the returned data matches
# expectations.  This is decidedly non-trivial to code, so the data is
# simply listed.  It generally looks plausible.

my ($i, $n);

$n = $#${names};
for ($i = 0; $i <= $n; $i++)
{
    printf "# %4d: %-20s %5d %5d %s\n", $i, $names->[$i], $coltyp->[$i], $collen->[$i], $types->[$i];
}

$dbh->disconnect or stmt_fail;
stmt_ok;

all_ok();
